function(input, output, session) {

  # =========================================================================
  # Helpers
  # =========================================================================

  .source_spectrum <- function(source_type, solar_cond,
                               upload = NULL, upload_unit = NULL,
                               upload_calibration = NULL,
                               upload_reference_depth_m = NULL) {
    if (source_type == "solar") {
      spectrum <- from_solar(solar_cond)
      list(
        lambda = spectrum$lambda,
        irradiance = spectrum$E,
        unit = "W/m2/nm",
        reference_depth_m = spectrum$meta$reference_depth_m,
        reference_medium = spectrum$meta$reference_medium,
        source_condition = solar_cond,
        source_import = spectrum$meta$import,
        source_provenance = spectrum$meta$provenance
      )
    } else {
      validate(need(!is.null(upload),
                    "Upload a spectrum file, or click 'Load example data', to continue."))
      spec <- tryCatch(
        from_ocean_optics(
          upload$datapath,
          quantity = "irradiance",
          unit = upload_unit,
          calibration = upload_calibration
        ),
        error = function(e)
          validate(paste("Could not read the uploaded file:",
                         conditionMessage(e))))
      validate(need(
        identical(spec$quantity, "irradiance"),
        paste0("This tab propagates irradiance, but the uploaded file holds '",
               spec$quantity, "' (", spec$unit, ").")))
      spec_w <- convert_unit(spec, "W/m2/nm")
      validate(need(
        is.numeric(upload_reference_depth_m) &&
          length(upload_reference_depth_m) == 1L &&
          is.finite(upload_reference_depth_m) &&
          upload_reference_depth_m >= 0,
        "Declare a finite, non-negative reference depth for the uploaded spectrum."
      ))
      list(
        lambda = spec_w$lambda,
        irradiance = spec_w$E,
        unit = spec_w$unit,
        reference_depth_m = upload_reference_depth_m,
        reference_medium = "water",
        source_condition = paste0("uploaded file '", upload$name, "'"),
        source_import = list(
          calibration_state = spec$meta$calibration_state,
          calibration = spec$meta$calibration,
          source_path = upload$name,
          source_checksum_md5 = spec$meta$import$source_checksum_md5,
          reader_model_version = spec$meta$import$reader_model_version,
          package_version = spec$meta$import$package_version,
          code_commit = spec$meta$import$code_commit,
          preprocessing = spec$meta$preprocessing$method
        )
      )
    }
  }

  .depth_seq <- function(from, to, step) {
    if (from == 0) {
      seq(0, to, by = step)
    } else {
      unique(c(seq(from, to, by = step), to))
    }
  }

  # Named for the app's own y-axis unit choices, which are not all members of
  # the package's controlled vocabulary. Only W_nm has a canonical unit to
  # delegate to; the photon and log-photon axes have no vocabulary entry.
  .axis_label <- function(unit) {
    switch(unit,
      W_nm       = bquote(Spectral~irradiance~
                          (.(unit_expression("W/m2/nm")))),
      photon_nm  = expression(Photon~irradiance~
                              (photons~m^{-2}~s^{-1}~nm^{-1})),
      log_photon = expression(log[10]~photons~m^{-2}~s^{-1}~nm^{-1})
    )
  }

  .apply_unit <- function(irr, lambda, unit) {
    switch(unit,
      W_nm       = irr,
      photon_nm  = W2photon(irr, lambda),
      log_photon = log10(pmax(W2photon(irr, lambda), .Machine$double.eps))
    )
  }

  .source_reference_label <- function(source) {
    paste0(
      "Source: ", source$source_condition, " [", unit_label(source$unit),
      "], reference ",
      format(source$reference_depth_m), " m in ", source$reference_medium
    )
  }

  .propagated_light_label <- function(condition, water_type, target_depth,
                                      wavelength_policy) {
    source <- .source_spectrum("solar", condition)
    paste0(
      .source_reference_label(source), "; target ", format(target_depth),
      " m; Jerlov ", water_type, "; wavelength policy ", wavelength_policy,
      "; spectral Beer-Lambert propagation",
      "; flat-interface Fresnel surface model when the source is in air"
    )
  }

  # Caption listing the data sources / methods behind the plot above it.
  .refs_panel <- function(...) {
    items <- unlist(list(...))
    tags$div(
      style = "margin-top:10px; font-size:0.85em; color:#666;",
      tags$strong("Data sources & methods"),
      tags$ul(style = "margin-bottom:0; padding-left:1.2em;",
              lapply(items, function(t) tags$li(t)))
    )
  }

  .species_source_ref <- function(species) {
    src <- SPECIES_SOURCE[[species]]
    if (is.null(src) || !nzchar(src)) src <- "unpublished"
    paste0("Receptor λmax (", species, "): ", src, ".")
  }

  # Measured beam attenuation c = a + b from a tab's toggle + a/b inputs,
  # or NULL when the toggle is off or the inputs are incomplete.
  .beam_c <- function(use, a, b) {
    if (isTRUE(use) && is.finite(a) && is.finite(b)) beam_attenuation(a, b)
    else NULL
  }

  # =========================================================================
  # Tab 1 — Depth Propagation
  # =========================================================================

  # "Load example data" loads the bundled Mare Chiaro field spectrum (converted
  # to W/m2/nm, like the solar path) in place of an uploaded file. A real upload
  # supersedes it.
  dp_example <- reactiveVal(FALSE)
  observeEvent(input$dp_example,  dp_example(TRUE))
  observeEvent(input$upload_file, dp_example(FALSE), ignoreInit = TRUE)

  dp_source <- reactive({
    if (input$source_type == "upload" && isTRUE(dp_example()) &&
        is.null(input$upload_file)) {
      x <- convert_unit(from_naples("0m"), "W/m2/nm")
      list(
        lambda = x$lambda,
        irradiance = x$E,
        reference_depth_m = x$meta$reference_depth_m,
        reference_medium = x$meta$reference_medium,
        source_condition = "Naples 0 m example",
        source_import = x$meta$import,
        source_provenance = x$meta$provenance
      )
    } else {
      .source_spectrum(input$source_type, input$solar_cond,
                       upload = input$upload_file,
                       upload_unit = input$upload_unit,
                       upload_calibration = input$upload_calibration,
                       upload_reference_depth_m = input$upload_reference_depth)
    }
  })

  dp_domain <- reactive({
    src <- dp_source()
    luxR:::.prepare_jerlov_domain(
      src$lambda, src$irradiance,
      wavelength_policy = input$dp_wavelength_policy,
      type = input$wtype,
      operation = "Shiny Depth Propagation"
    )
  })

  dp_spectra <- reactive({
    src    <- dp_source()
    domain <- dp_domain()
    lambda <- domain$lambda
    E0     <- domain$values
    dlo    <- input$depths[1]
    dhi    <- input$depths[2]
    step   <- max(1, input$depth_step)
    depths <- .depth_seq(dlo, dhi, step)
    Kd     <- domain$Kd
    luxR:::.validate_source_target_depths(
      reference_depth_m = src$reference_depth_m,
      reference_medium = src$reference_medium,
      target_depth_m = depths,
      source_condition = src$source_condition,
      water_type = input$wtype,
      operation = "Shiny Depth Propagation"
    )
    E_water <- luxR:::.source_irradiance_in_water(
      E0,
      reference_medium = src$reference_medium,
      surface_source = SURFACE_SOURCE,
      surface_angle = SURFACE_ANGLE_DEG,
      refractive_index = SURFACE_REFRACTIVE_INDEX,
      operation = "Shiny Depth Propagation"
    )
    M      <- propagate_spectrum(E_water, Kd, from = src$reference_depth_m,
                                 to = depths, lambda = lambda,
                                 format = "matrix")
    # named list keyed by depth (matches dp_plot / dp_summary consumers)
    stats::setNames(lapply(seq_along(depths), function(j) M[, j]),
                    as.character(depths))
  })

  dp_metadata <- reactive({
    src <- dp_source()
    targets <- as.numeric(names(dp_spectra()))
    luxR:::.depth_output_metadata(
      source_condition = src$source_condition,
      reference_depth_m = src$reference_depth_m,
      reference_medium = src$reference_medium,
      water_type = input$wtype,
      target_depth_m = targets,
      jerlov_metadata = dp_domain()$metadata,
      source_import = src$source_import,
      surface_source = SURFACE_SOURCE,
      surface_angle = SURFACE_ANGLE_DEG,
      refractive_index = SURFACE_REFRACTIVE_INDEX
    )
  })

  output$dp_import_status <- renderUI({
    if (input$source_type != "upload") return(NULL)
    if (isTRUE(dp_example()) && is.null(input$upload_file)) {
      return(tags$div(
        class = "alert alert-info",
        "Bundled Naples example: calibrated photon irradiance converted to W/m²/nm."
      ))
    }
    req(input$upload_file)
    src <- dp_source()
    info <- src$source_import
    tags$div(
      class = "alert alert-info",
      tags$strong("Imported calibrated irradiance: "),
      info$calibration, tags$br(),
      paste0("File: ", info$source_path, " | MD5: ",
             info$source_checksum_md5, " | preprocessing: ",
             info$preprocessing)
    )
  })

  output$dp_plot <- renderPlot({
    lambda  <- dp_domain()$lambda
    res     <- dp_spectra()
    depths  <- as.numeric(names(res))
    unit    <- input$dp_unit

    ys <- lapply(res, function(E) .apply_unit(E, lambda, unit))
    yrange <- range(unlist(ys), finite = TRUE)

    n    <- length(depths)
    cols <- if (n == 1) "steelblue" else
      colorRampPalette(c("goldenrod", "steelblue4"))(n)

    plot(lambda, ys[[1]], type = "n",
         xlim = range(lambda), ylim = yrange,
         xlab = "Wavelength (nm)", ylab = .axis_label(unit),
         main = paste("Depth propagation —", input$wtype, "water"),
         sub = luxR:::.format_depth_output_metadata(dp_metadata()),
         cex.sub = 0.78)
    for (i in seq_along(depths))
      lines(lambda, ys[[i]], col = cols[i], lwd = 1.4)
    legend("topright",
           legend = paste(depths, "m"),
           col = cols, lty = 1, lwd = 1.4, bty = "n",
           title = "Target depth")
  })

  dp_summary_df <- reactive({
    res    <- dp_spectra()
    luxR:::.depth_summary_df(res, dp_domain()$lambda)
  })

  output$dp_summary <- renderTable({
    df <- dp_summary_df()
    df[["Photons/s/m2"]] <- formatC(df[["Photons/s/m2"]],
                                    format = "e", digits = 3)
    # Rename for display only. The underlying column keeps its ASCII name so
    # the CSV download header and the .depth_download_df round-trip are
    # unchanged.
    names(df)[names(df) == "Photons/s/m2"] <-
      "photons m⁻² s⁻¹"
    df
  }, digits = 2)

  dp_download_df <- reactive({
    luxR:::.depth_download_df(dp_summary_df(), dp_metadata())
  })

  output$dp_download <- downloadHandler(
    filename = function() paste0("luxR_depth_summary_", Sys.Date(), ".csv"),
    content  = function(file) {
      utils::write.csv(dp_download_df(), file, row.names = FALSE)
    }
  )

  output$dp_refs <- renderUI({
    light <- if (input$source_type == "solar") REF_ASTM
             else if (isTRUE(dp_example()) && is.null(input$upload_file)) REF_NAPLES
             else REF_UPLOAD
    .refs_panel(light, REF_JERLOV)
  })

  # =========================================================================
  # Tab 2 — Species Perception
  # =========================================================================

  output$sp_receptor_ui <- renderUI({
    recs <- subset(species_sensitivities, species == input$sp_species)$receptor
    selectInput("sp_receptor", "Receptor class",
                choices = sort(unique(recs)),
                selected = sort(unique(recs))[1])
  })

  sp_sensitivity <- reactive({
    req(input$sp_receptor)
    # During the species->receptor reactive update the chosen receptor can
    # briefly not belong to the species; guard before calling species_LEF
    # (which errors on an unknown receptor) so downstream NULL checks hold.
    recs <- subset(species_sensitivities, species == input$sp_species)$receptor
    if (!input$sp_receptor %in% recs) return(NULL)
    species_LEF(input$sp_species, receptor = input$sp_receptor,
                lambda = seq(300, 750, by = 1))
  })

  # Effective sensitivity: photoreceptor absorptance at the chosen axial optical
  # density (self-screening). OD = 0 falls back to the bare pigment template.
  sp_effective_S <- reactive({
    S <- sp_sensitivity()
    if (is.null(S)) return(NULL)
    if (input$sp_od <= 0) return(S)
    receptor_absorptance(S, optical_density = input$sp_od)
  })

  sp_light <- reactive({
    .source_spectrum("solar", input$sp_solar)
  })

  sp_qcatch_result <- eventReactive(input$sp_calc, {
    S   <- sp_effective_S()
    src <- sp_light()
    if (is.null(S)) return(NULL)
    binw <- if (length(src$lambda) > 1) mean(diff(src$lambda)) else 10
    value <- quantum_catch(
      irradiance = src$irradiance,
      lambda = src$lambda,
      S = S,
      input_unit = src$unit,
      total = TRUE,
      binwidth = binw
    )
    list(
      value = value,
      unit = "photon/m2/s",
      source_condition = src$source_condition,
      source_unit = src$unit,
      reference_depth_m = src$reference_depth_m,
      reference_medium = src$reference_medium,
      species = input$sp_species,
      receptor = input$sp_receptor,
      sensitivity_model = if (input$sp_od > 0)
        "absorptance from axial optical density"
      else
        "normalised pigment template",
      axial_optical_density = input$sp_od,
      peak_absorptance = if (input$sp_od > 0) max(S$S) else NA_real_,
      binwidth_nm = binw,
      wavelength_min_nm = min(src$lambda),
      wavelength_max_nm = max(src$lambda),
      source_import = src$source_import,
      sensitivity_provenance = luxR:::.bundled_dataset_provenance(
        species_sensitivities, "species_sensitivities"
      )
    )
  }, ignoreNULL = FALSE)

  sp_qcatch_val <- reactive({
    result <- sp_qcatch_result()
    if (is.null(result)) NULL else result$value
  })

  sp_qcatch_df <- reactive({
    result <- sp_qcatch_result()
    req(!is.null(result))
    data.frame(
      quantity = "sensitivity-weighted photon irradiance",
      value = result$value,
      unit = result$unit,
      interpretation = paste(
        "Photon irradiance weighted by dimensionless sensitivity or",
        "absorptance; not an absolute per-receptor photon rate."
      ),
      source_condition = result$source_condition,
      source_unit = result$source_unit,
      source_reference_depth_m = result$reference_depth_m,
      source_reference_medium = result$reference_medium,
      species = result$species,
      receptor = result$receptor,
      sensitivity_model = result$sensitivity_model,
      axial_optical_density = result$axial_optical_density,
      peak_absorptance = result$peak_absorptance,
      binwidth_nm = result$binwidth_nm,
      wavelength_min_nm = result$wavelength_min_nm,
      wavelength_max_nm = result$wavelength_max_nm,
      source_artifact = result$source_import$source_path,
      source_checksum_md5 = result$source_import$source_checksum_md5,
      source_model_version = result$source_import$reader_model_version,
      source_package_version = result$source_import$package_version,
      source_code_commit = result$source_import$code_commit,
      sensitivity_source_artifact =
        result$sensitivity_provenance$source_artifact,
      sensitivity_source_checksum_md5 =
        result$sensitivity_provenance$source_artifact_md5,
      sensitivity_citation_keys = paste(
        result$sensitivity_provenance$citation_key, collapse = ";"
      ),
      sensitivity_model_version =
        result$sensitivity_provenance$processing_version,
      absolute_rate_status = paste(
        "not calculated: receptor collection area, source solid angle, ocular",
        "transmission, and quantum efficiency were not supplied"
      ),
      stringsAsFactors = FALSE
    )
  })

  output$sp_plot <- renderPlot({
    S   <- sp_sensitivity()     # bare pigment template
    Eff <- sp_effective_S()     # absorptance (or template at OD = 0)
    src <- sp_light()
    req(!is.null(S), !is.null(Eff))

    lambda_s     <- S$lambda
    tmpl_n       <- S$S   / max(S$S,   na.rm = TRUE)   # bare template, normalised
    eff_n        <- Eff$S / max(Eff$S, na.rm = TRUE)   # effective sens., normalised
    peak_capture <- max(Eff$S, na.rm = TRUE)           # absolute peak absorptance
    screened     <- isTRUE(input$sp_od > 0)

    binw <- if (length(src$lambda) > 1) mean(diff(src$lambda)) else 10
    irr_w <- W2photon(src$irradiance, src$lambda)
    irr_n <- irr_w / max(irr_w, na.rm = TRUE)

    irr_at_s <- approx(src$lambda, irr_n, xout = lambda_s, rule = 2)$y

    par(mar = c(4, 4, 3, 4))
    plot(lambda_s, eff_n, type = "l", col = "darkorange", lwd = 2,
         ylim = c(0, 1.05),
         xlab = "Wavelength (nm)", ylab = "Normalised sensitivity / irradiance",
         main = paste(input$sp_species, "-", input$sp_receptor),
         sub = paste(.source_reference_label(src), "; curves normalised to peak"),
         cex.sub = 0.78)
    if (screened)                                       # show broadening vs template
      lines(lambda_s, tmpl_n, col = "grey60", lwd = 1.3, lty = 3)
    lines(lambda_s, irr_at_s, col = "steelblue", lwd = 1.5, lty = 2)
    legend("topright",
           legend = c(
             if (screened)
               sprintf("absorptance (peak %.0f%% capture)", 100 * peak_capture)
             else paste(input$sp_receptor, "sensitivity"),
             if (screened) "bare pigment template",
             "Photon irradiance (normalised)"),
           col = c("darkorange", if (screened) "grey60", "steelblue"),
           lty = c(1, if (screened) 3, 2),
           lwd = c(2, if (screened) 1.3, 1.5), bty = "n")
  })

  output$sp_qcatch <- renderPrint({
    result <- sp_qcatch_result()
    if (is.null(result)) {
      cat("Press 'Calculate quantum catch' to compute.\n")
    } else {
      cat("Sensitivity-weighted photon irradiance\n")
      cat(sprintf("Qw = %.4e  photons m⁻² s⁻¹\n", result$value))
      cat("Not an absolute photons per receptor per second rate.\n")
      cat(sprintf("Source: %s [%s], reference %.1f m in %s\n",
                  result$source_condition, unit_label(result$source_unit),
                  result$reference_depth_m, result$reference_medium))
      cat(sprintf("Integration: %.1f--%.1f nm, %.3g nm bins\n",
                  result$wavelength_min_nm, result$wavelength_max_nm,
                  result$binwidth_nm))
      row <- subset(species_sensitivities,
                    species  == input$sp_species &
                    receptor == input$sp_receptor)
      if (nrow(row) > 0)
        cat(sprintf("lambda_max = %d nm  (%s chromophore)\n",
                    row$lambda_max[1], row$chromophore[1]))
      if (isTRUE(input$sp_od > 0)) {
        Eff <- sp_effective_S()
        if (!is.null(Eff))
          cat(sprintf("axial OD = %.2f  ->  peak capture = %.0f%%\n",
                      input$sp_od, 100 * max(Eff$S, na.rm = TRUE)))
      }
      cat(paste(
        "Absolute-rate inputs not supplied: receptor collection area, source",
        "solid angle, ocular transmission, quantum efficiency.\n"
      ))
    }
  })

  output$sp_download <- downloadHandler(
    filename = function() paste0("luxR_quantum_catch_", Sys.Date(), ".csv"),
    content = function(file) {
      utils::write.csv(sp_qcatch_df(), file, row.names = FALSE, na = "")
    }
  )

  output$sp_refs <- renderUI({
    items <- c(.species_source_ref(input$sp_species), REF_GOVARD)
    if (isTRUE(input$sp_od > 0)) items <- c(items, REF_ABSORPTANCE)
    .refs_panel(c(items, REF_ASTM))
  })

  # =========================================================================
  # Tab — Colour discrimination
  # =========================================================================

  jnd_light <- reactive({
    req(is.finite(input$jnd_depth))
    light_at_depth(
      input$jnd_solar, input$jnd_wtype, input$jnd_depth,
      surface_source = SURFACE_SOURCE,
      surface_angle = SURFACE_ANGLE_DEG,
      refractive_index = SURFACE_REFRACTIVE_INDEX,
      wavelength_policy = input$jnd_wavelength_policy
    )
  })

  jnd_reflectance <- function(choice, file, lambda) {
    if (choice == "upload") {
      validate(need(!is.null(file), "Upload a reflectance CSV."))
      tryCatch(luxR:::.read_reflectance_csv(file$datapath, lambda),
               error = function(e)
                 validate(paste("Could not read reflectance CSV:",
                                conditionMessage(e))))
    } else {
      luxR:::.preset_reflectance(choice, lambda)
    }
  }

  jnd_result <- eventReactive(input$jnd_calc, {
    lf     <- jnd_light()
    lambda <- lf$lambda
    r1     <- jnd_reflectance(input$jnd_r1, input$jnd_r1_file, lambda)
    r2     <- jnd_reflectance(input$jnd_r2, input$jnd_r2_file, lambda)
    recs   <- chromatic_receptors(input$jnd_species)
    validate(need(length(recs) >= 2,
                  paste(
                    "This species has no validated chromatic channel;",
                    "colour discrimination is unavailable."
                  )))
    jnd    <- luxR:::.app_jnd(r1, r2, lf$irradiance, lambda,
                             input$jnd_species, recs)
    list(
      jnd = jnd, lambda = lambda, r1 = r1, r2 = r2,
      species = input$jnd_species,
      receptors = recs,
      light_context = .propagated_light_label(
        input$jnd_solar, input$jnd_wtype, input$jnd_depth,
        input$jnd_wavelength_policy
      )
    )
  })

  output$jnd_plot <- renderPlot({
    res <- jnd_result()
    plot(res$lambda, res$r1, type = "l", col = "grey40", lwd = 2,
         ylim = c(0, 1), xlab = "Wavelength (nm)", ylab = "Reflectance",
         main = "Compared reflectances", sub = res$light_context,
         cex.sub = 0.78)
    lines(res$lambda, res$r2, col = "firebrick", lwd = 2)
    legend("topright", c("Reflectance 1", "Reflectance 2"),
           col = c("grey40", "firebrick"), lwd = 2, bty = "n")
  })

  output$jnd_out <- renderPrint({
    res <- jnd_result()
    cat(sprintf("Colour discrimination: %.3f JND\n", res$jnd))
    cat(sprintf("Viewer: %s; chromatic receptors: %s\n",
                res$species, paste(res$receptors, collapse = ", ")))
    cat(res$light_context, "\n")
    cat("Model: Vorobyev-Osorio receptor-noise JND.\n")
    cat(if (isTRUE(res$jnd >= 1))
          "(>= 1 JND: discriminable)\n"
        else
          "(< 1 JND: not discriminable)\n")
  })

  output$jnd_refs <- renderUI({
    .refs_panel(REF_VOROBYEV, .species_source_ref(input$jnd_species),
                REF_GOVARD, REF_ASTM, REF_JERLOV)
  })

  # =========================================================================
  # Tab — Visibility
  # =========================================================================

  vis_beam_c <- reactive(.beam_c(input$vis_use_c, input$vis_a, input$vis_b))

  output$vis_table <- renderTable({
    req(is.finite(input$vis_lambda))
    Kd <- jerlov_Kd(input$vis_wtype, lambda = input$vis_lambda)
    m  <- luxR:::.visibility_metrics(Kd,
                                     photic_fraction    = input$vis_photic,
                                     contrast_threshold = input$vis_contrast,
                                     beam_c             = vis_beam_c())
    data.frame(
      Metric = c("Secchi depth", "Photic depth",
                 "Horizontal visual range (heuristic estimate)"),
      `Value (m)` = c(m$secchi_m, m$photic_m, m$visual_range_m),
      check.names = FALSE
    )
  }, digits = 2)

  output$vis_context <- renderText({
    attenuation <- if (isTRUE(input$vis_use_c)) {
      paste0("measured beam attenuation c = a + b = ",
             format(vis_beam_c()), " 1/m")
    } else {
      "proxy beam attenuation c = 1.5 x Kd"
    }
    paste0(
      "Jerlov ", input$vis_wtype, " at ", format(input$vis_lambda),
      " nm; Kd in 1/m; ", attenuation,
      ". Visual range is an unvalidated heuristic scenario estimate."
    )
  })

  output$vis_refs <- renderUI({
    items <- c(REF_JERLOV, REF_SECCHI, REF_VISRANGE)
    if (isTRUE(input$vis_use_c)) items <- c(items, REF_IOP)
    .refs_panel(items)
  })

  # =========================================================================
  # Tab — Detection
  # =========================================================================

  det_light <- reactive({
    req(is.finite(input$det_depth))
    light_at_depth(
      input$det_solar, input$det_wtype, input$det_depth,
      surface_source = SURFACE_SOURCE,
      surface_angle = SURFACE_ANGLE_DEG,
      refractive_index = SURFACE_REFRACTIVE_INDEX,
      wavelength_policy = input$det_wavelength_policy
    )
  })

  det_result <- reactive({
    req(is.finite(input$det_lambda))
    lf     <- det_light()
    lambda <- lf$lambda
    obj    <- jnd_reflectance(input$det_obj, input$det_obj_file, lambda)
    bg     <- jnd_reflectance(input$det_bg,  input$det_bg_file,  lambda)
    chan   <- detection_channel(input$det_species)
    Kd_ref <- jerlov_Kd(input$det_wtype, lambda = input$det_lambda)
    beam_c <- .beam_c(input$det_use_c, input$det_a, input$det_b)
    detectability(obj, bg, lf$irradiance, lambda, Kd = Kd_ref,
                  species = input$det_species, channel = chan,
                  contrast_threshold = input$det_contrast,
                  direction = input$det_dir, beam_c = beam_c)
  })

  det_context <- reactive({
    chan <- detection_channel(input$det_species)
    attenuation <- if (isTRUE(input$det_use_c)) {
      paste0("measured beam attenuation c = a + b = ",
             format(.beam_c(TRUE, input$det_a, input$det_b)), " 1/m")
    } else {
      "proxy beam attenuation c = 1.5 x Kd"
    }
    paste0(
      .propagated_light_label(
        input$det_solar, input$det_wtype, input$det_depth,
        input$det_wavelength_policy
      ),
      "; sighting wavelength ", format(input$det_lambda), " nm; ",
      input$det_dir, " viewing; validated channel ", chan, "; ", attenuation
    )
  })

  output$det_plot <- renderPlot({
    plot(det_result())
    title(sub = det_context(), cex.sub = 0.72)
  })
  output$det_out  <- renderPrint({
    cat(det_context(), "\n")
    print(det_result())
  })

  output$det_refs <- renderUI({
    chan <- detection_channel(input$det_species)
    roles <- if (chan == "both") c("chromatic", "achromatic") else chan
    items <- c(REF_ASTM, REF_JERLOV, REF_DETECT,
               .species_source_ref(input$det_species),
               paste0(
                 "Validated ", roles, " channel: ",
                 vapply(roles, function(role) {
                   channel_source(input$det_species, role)
                 }, character(1)),
                 "."
               ),
               REF_GOVARD)
    if (chan %in% c("both", "chromatic")) items <- c(items, REF_VOROBYEV)
    if (isTRUE(input$det_use_c)) items <- c(items, REF_IOP)
    .refs_panel(items)
  })

}
