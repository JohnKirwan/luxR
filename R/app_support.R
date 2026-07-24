# Internal helpers for the bundled Shiny app (inst/app). Not exported.

#' @keywords internal
#' @noRd
.depth_summary_df <- function(spectra, lambda) {
  # `spectra` is a named list keyed by depth (names must parse as numeric);
  # values are per-depth irradiance vectors over `lambda`. Full numeric
  # precision is kept here; display rounding is the caller's concern.
  binw   <- if (length(lambda) > 1) mean(diff(lambda)) else 10
  depths <- as.numeric(names(spectra))
  rows <- lapply(seq_along(spectra), function(i) {
    E   <- spectra[[i]]
    lux <- irradiance2lux(E, lambda, total = TRUE, binwidth = binw)
    ph  <- sum(W2photon(E, lambda) * binw)
    data.frame(
      `Depth (m)`    = depths[i],
      `Lux`          = lux,
      `Photons/s/m2` = ph,
      check.names    = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Build reproducibility metadata for a Shiny depth-propagation result.
#' @keywords internal
#' @noRd
.depth_output_metadata <- function(source_condition, reference_depth_m,
                                   reference_medium, water_type,
                                   target_depth_m,
                                   jerlov_metadata,
                                   source_import = NULL,
                                   surface_source = c("direct", "diffuse"),
                                   surface_angle = 30,
                                   refractive_index = 1.333) {
  surface_source <- match.arg(surface_source)
  required_jerlov <- c(
    "supported_wavelength_range_nm", "table_checksum_md5", "source_path",
    "build_commit", "model_version", "package_version", "interp",
    "extrapolation", "wavelength_policy", "input_wavelength_range_nm",
    "calculated_wavelength_range_nm", "trimmed_wavelength_count"
  )
  if (!is.list(jerlov_metadata) ||
      any(!required_jerlov %in% names(jerlov_metadata))) {
    stop("Jerlov metadata is missing required propagation context.",
         call. = FALSE)
  }
  range_fields <- c(
    "supported_wavelength_range_nm", "input_wavelength_range_nm",
    "calculated_wavelength_range_nm"
  )
  if (any(vapply(jerlov_metadata[range_fields], function(x) {
    !is.numeric(x) || length(x) != 2L || any(!is.finite(x)) || x[[1L]] > x[[2L]]
  }, logical(1)))) {
    stop("Jerlov wavelength metadata must contain finite, ordered ranges.",
         call. = FALSE)
  }
  .validate_source_target_depths(
    reference_depth_m = reference_depth_m,
    reference_medium = reference_medium,
    target_depth_m = target_depth_m,
    source_condition = source_condition,
    water_type = water_type,
    operation = "Shiny depth-output metadata"
  )

  # Applying the surface operation to unit irradiance uses the same validated
  # physics path as the calculation and yields the exact recorded multiplier.
  surface_multiplier <- .source_irradiance_in_water(
    1,
    reference_medium = reference_medium,
    surface_source = surface_source,
    surface_angle = surface_angle,
    refractive_index = refractive_index,
    operation = "Shiny depth-output metadata"
  )
  import_defaults <- list(
    calibration_state = "bundled/reference source",
    calibration = "bundled source metadata",
    source_path = "bundled luxR dataset",
    source_checksum_md5 = NA_character_,
    reader_model_version = NA_character_,
    package_version = as.character(utils::packageVersion("luxR")),
    code_commit = NA_character_,
    preprocessing = "none"
  )
  if (!is.null(source_import)) {
    if (!is.list(source_import) ||
        any(!names(import_defaults) %in% names(source_import))) {
      stop("Uploaded source import metadata is incomplete.", call. = FALSE)
    }
    import_defaults <- source_import[names(import_defaults)]
  }
  import_defaults <- lapply(import_defaults, function(value) {
    if (is.null(value) || length(value) != 1L) NA_character_ else as.character(value)
  })
  propagation <- .propagation_model_context(
    "Shiny Depth Propagation", from = reference_depth_m,
    to = target_depth_m
  )

  data.frame(
    source_condition = rep(source_condition, length(target_depth_m)),
    source_reference_medium = rep(reference_medium, length(target_depth_m)),
    source_reference_depth_m = rep(reference_depth_m, length(target_depth_m)),
    source_calibration_state = rep(
      import_defaults$calibration_state, length(target_depth_m)
    ),
    source_calibration = rep(import_defaults$calibration, length(target_depth_m)),
    source_path = rep(import_defaults$source_path, length(target_depth_m)),
    source_checksum_md5 = rep(
      import_defaults$source_checksum_md5, length(target_depth_m)
    ),
    source_reader_model_version = rep(
      import_defaults$reader_model_version, length(target_depth_m)
    ),
    source_reader_package_version = rep(
      import_defaults$package_version, length(target_depth_m)
    ),
    source_reader_code_commit = rep(
      import_defaults$code_commit, length(target_depth_m)
    ),
    source_preprocessing = rep(
      import_defaults$preprocessing, length(target_depth_m)
    ),
    propagation_model = rep(propagation$model, length(target_depth_m)),
    propagation_model_version = rep(
      propagation$model_version, length(target_depth_m)
    ),
    propagation_equation = rep(
      propagation$equation, length(target_depth_m)
    ),
    propagation_assumptions = rep(
      propagation$assumptions, length(target_depth_m)
    ),
    propagation_package_version = rep(
      propagation$package_version, length(target_depth_m)
    ),
    propagation_code_commit = rep(
      propagation$code_commit, length(target_depth_m)
    ),
    surface_model = rep("flat-interface Fresnel", length(target_depth_m)),
    surface_transmission_applied = rep(
      identical(reference_medium, "air"), length(target_depth_m)
    ),
    surface_source = rep(surface_source, length(target_depth_m)),
    surface_incidence_angle_deg = rep(surface_angle, length(target_depth_m)),
    surface_refractive_index = rep(refractive_index, length(target_depth_m)),
    surface_multiplier = rep(surface_multiplier, length(target_depth_m)),
    jerlov_type = rep(water_type, length(target_depth_m)),
    jerlov_supported_min_nm = rep(
      jerlov_metadata$supported_wavelength_range_nm[[1L]],
      length(target_depth_m)
    ),
    jerlov_supported_max_nm = rep(
      jerlov_metadata$supported_wavelength_range_nm[[2L]],
      length(target_depth_m)
    ),
    jerlov_input_min_nm = rep(
      jerlov_metadata$input_wavelength_range_nm[[1L]],
      length(target_depth_m)
    ),
    jerlov_input_max_nm = rep(
      jerlov_metadata$input_wavelength_range_nm[[2L]],
      length(target_depth_m)
    ),
    jerlov_calculated_min_nm = rep(
      jerlov_metadata$calculated_wavelength_range_nm[[1L]],
      length(target_depth_m)
    ),
    jerlov_calculated_max_nm = rep(
      jerlov_metadata$calculated_wavelength_range_nm[[2L]],
      length(target_depth_m)
    ),
    jerlov_interpolation = rep(jerlov_metadata$interp, length(target_depth_m)),
    jerlov_extrapolation = rep(
      jerlov_metadata$extrapolation, length(target_depth_m)
    ),
    jerlov_wavelength_policy = rep(
      jerlov_metadata$wavelength_policy, length(target_depth_m)
    ),
    jerlov_trimmed_wavelength_count = rep(
      jerlov_metadata$trimmed_wavelength_count, length(target_depth_m)
    ),
    jerlov_table_checksum_md5 = rep(
      jerlov_metadata$table_checksum_md5, length(target_depth_m)
    ),
    jerlov_source_path = rep(
      jerlov_metadata$source_path, length(target_depth_m)
    ),
    jerlov_build_commit = rep(
      jerlov_metadata$build_commit, length(target_depth_m)
    ),
    jerlov_model_version = rep(
      jerlov_metadata$model_version, length(target_depth_m)
    ),
    jerlov_package_version = rep(
      jerlov_metadata$package_version, length(target_depth_m)
    ),
    target_depth_m = target_depth_m,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Format depth-propagation metadata for display beneath a plot.
#' @keywords internal
#' @noRd
.format_depth_output_metadata <- function(metadata) {
  required <- c(
    "source_condition", "source_reference_medium",
    "source_reference_depth_m", "source_calibration_state",
    "source_calibration", "source_path", "source_checksum_md5",
    "source_reader_model_version", "source_reader_package_version",
    "source_reader_code_commit", "source_preprocessing",
    "propagation_model", "propagation_model_version",
    "propagation_equation", "propagation_assumptions",
    "propagation_package_version", "propagation_code_commit", "surface_model",
    "surface_transmission_applied", "surface_source",
    "surface_incidence_angle_deg", "surface_refractive_index",
    "surface_multiplier", "jerlov_type",
    "jerlov_supported_min_nm", "jerlov_supported_max_nm",
    "jerlov_input_min_nm", "jerlov_input_max_nm",
    "jerlov_calculated_min_nm", "jerlov_calculated_max_nm",
    "jerlov_interpolation", "jerlov_extrapolation",
    "jerlov_wavelength_policy", "jerlov_trimmed_wavelength_count",
    "jerlov_table_checksum_md5", "jerlov_source_path",
    "jerlov_build_commit", "jerlov_model_version",
    "jerlov_package_version", "target_depth_m"
  )
  if (!is.data.frame(metadata) || nrow(metadata) < 1L ||
      !all(required %in% names(metadata))) {
    stop("Depth-output metadata is missing required fields.",
         call. = FALSE)
  }
  constant_fields <- setdiff(required, "target_depth_m")
  if (any(vapply(metadata[constant_fields], function(x) {
    length(unique(x)) != 1L
  }, logical(1)))) {
    stop("Depth-output metadata contains inconsistent run-level fields.",
         call. = FALSE)
  }

  targets <- metadata$target_depth_m
  target_text <- if (length(targets) == 1L) {
    paste0(format(targets), " m")
  } else {
    deltas <- diff(targets)
    if (length(unique(deltas)) == 1L) {
      paste0(format(targets[1]), "-", format(targets[length(targets)]),
             " m by ", format(deltas[1]), " m")
    } else {
      paste0(paste(format(targets), collapse = ", "), " m")
    }
  }

  surface_text <- if (isTRUE(metadata$surface_transmission_applied[1])) {
    paste0(
      metadata$surface_model[1], " ", metadata$surface_source[1],
      " at ", format(metadata$surface_incidence_angle_deg[1]),
      " deg, n=", format(metadata$surface_refractive_index[1]),
      ", multiplier=", format(metadata$surface_multiplier[1], digits = 6)
    )
  } else {
    paste0(metadata$surface_model[1],
           " not applied (source already in water; multiplier=1)")
  }

  paste0(
    "Source: ", metadata$source_condition[1], " (",
    metadata$source_reference_medium[1], "; reference ",
    format(metadata$source_reference_depth_m[1]), " m)\n",
    "Calibration: ", metadata$source_calibration_state[1], " - ",
    metadata$source_calibration[1],
    " | preprocessing: ", metadata$source_preprocessing[1], "\n",
    "Propagation: ", metadata$propagation_model[1], " [",
    metadata$propagation_model_version[1], "]; ",
    metadata$propagation_assumptions[1], "\n",
    "Surface: ", surface_text, " | Jerlov: ", metadata$jerlov_type[1],
    " (", metadata$jerlov_wavelength_policy[1], "; ",
    format(metadata$jerlov_calculated_min_nm[1]), "-",
    format(metadata$jerlov_calculated_max_nm[1]), " nm; ",
    metadata$jerlov_interpolation[1], " interpolation; ",
    metadata$jerlov_extrapolation[1], " extrapolation)",
    " | Target depths: ", target_text
  )
}

#' Join depth-propagation metadata to the downloadable numeric summary.
#' @keywords internal
#' @noRd
.depth_download_df <- function(summary, metadata) {
  if (!is.data.frame(summary) || !"Depth (m)" %in% names(summary)) {
    stop("Depth summary is missing the `Depth (m)` field.", call. = FALSE)
  }
  if (!is.data.frame(metadata) ||
      !"target_depth_m" %in% names(metadata) ||
      nrow(summary) != nrow(metadata) ||
      !identical(as.numeric(summary[["Depth (m)"]]),
                 as.numeric(metadata$target_depth_m))) {
    stop("Depth summary and output metadata target depths are misaligned.",
         call. = FALSE)
  }

  names(metadata) <- c(
    "Source condition", "Source reference medium",
    "Source reference depth (m)", "Source calibration state",
    "Source calibration declaration", "Source file",
    "Source checksum (MD5)", "Source reader model version",
    "Source reader package version", "Source reader code commit",
    "Source preprocessing", "Propagation model", "Propagation model version",
    "Propagation equation", "Propagation assumptions",
    "Propagation package version", "Propagation code commit", "Surface model",
    "Surface transmission applied", "Surface source",
    "Surface incidence angle (deg)", "Surface refractive index",
    "Surface multiplier", "Jerlov type",
    "Jerlov supported minimum (nm)", "Jerlov supported maximum (nm)",
    "Input wavelength minimum (nm)", "Input wavelength maximum (nm)",
    "Calculated wavelength minimum (nm)", "Calculated wavelength maximum (nm)",
    "Jerlov interpolation", "Jerlov extrapolation",
    "Jerlov wavelength policy", "Trimmed wavelength count",
    "Jerlov table checksum (MD5)", "Jerlov source path",
    "Jerlov build commit", "Jerlov model version",
    "luxR package version", "Target depth (m)"
  )
  values <- summary[, setdiff(names(summary), "Depth (m)"), drop = FALSE]
  data.frame(metadata, values, check.names = FALSE)
}

#' @keywords internal
#' @noRd
.preset_reflectance <- function(type = c("grey", "red", "green", "blue"),
                                lambda) {
  type <- match.arg(type)
  gauss <- function(centre) 0.2 + 0.25 * exp(-((lambda - centre) / 35)^2)
  out <- switch(type,
    grey  = rep(0.3, length(lambda)),
    red   = gauss(625),
    green = gauss(550),
    blue  = gauss(460)
  )
  pmin(pmax(out, 0), 1)
}

#' @keywords internal
#' @noRd
.app_jnd <- function(refl1, refl2, illuminant, lambda, species, receptor,
                     noise = 0.05) {
  stim1 <- reflectance_to_radiance(refl1, illuminant, lambda)
  stim2 <- reflectance_to_radiance(refl2, illuminant, lambda)
  colour_jnd(stim1 = stim1, stim2 = stim2, lambda = lambda,
             species = species, receptor = receptor, noise = noise)
}

#' @keywords internal
#' @noRd
.visibility_metrics <- function(Kd, photic_fraction = 0.01,
                                contrast_threshold = 0.02, beam_c = NULL) {
  list(
    secchi_m       = as.numeric(secchi_depth(Kd)),
    photic_m       = as.numeric(photic_depth(Kd, fraction = photic_fraction)),
    visual_range_m = as.numeric(
      visual_range(Kd, contrast_threshold = contrast_threshold,
                   beam_c = beam_c))
  )
}

#' Read a 2-column reflectance CSV (wavelength, reflectance) onto a target grid.
#' @keywords internal
#' @noRd
.read_reflectance_csv <- function(path, lambda) {
  context <- .validate_import_path(
    path, format = "reflectance CSV", operation = ".read_reflectance_csv",
    configuration = list(target_lambda = lambda)
  )
  if (!is.numeric(lambda) || is.object(lambda) || !length(lambda) ||
      any(!is.finite(lambda))) {
    .stop_spectrum_import(
      "`lambda` must be a non-empty finite numeric target grid.", context,
      class = "luxR_spectrum_schema_error", field = "lambda", value = lambda
    )
  }
  .validate_import_grid(lambda, context)
  table <- tryCatch(
    utils::read.csv(path, header = FALSE, colClasses = "character",
                    check.names = FALSE, blank.lines.skip = FALSE,
                    comment.char = "", strip.white = TRUE),
    error = function(e) {
      .stop_spectrum_import(
        paste0("Could not parse reflectance CSV: ", conditionMessage(e)),
        context, class = "luxR_spectrum_format_error", field = "file"
      )
    }
  )
  if (ncol(table) != 2L || nrow(table) == 0L) {
    .stop_spectrum_import(
      paste0("Reflectance CSV must contain exactly two columns and at least ",
             "one data row; got ", ncol(table), " columns and ",
             nrow(table), " rows."),
      context, class = "luxR_spectrum_schema_error", field = "columns",
      value = ncol(table)
    )
  }
  first <- tolower(trimws(unlist(table[1L, ], use.names = FALSE)))
  wavelength_headers <- c("wavelength", "lambda", "wl", "wv", "nm")
  reflectance_headers <- c("reflectance", "refl", "r", "value")
  has_header <- first[[1L]] %in% wavelength_headers &&
    first[[2L]] %in% reflectance_headers
  if (has_header) {
    table <- table[-1L, , drop = FALSE]
    line_offset <- 1L
    if (nrow(table) == 0L) {
      .stop_spectrum_import(
        "Reflectance CSV contains a header but no data rows.", context,
        class = "luxR_spectrum_schema_error", field = "data"
      )
    }
  } else {
    line_offset <- 0L
  }
  parsed <- t(vapply(seq_len(nrow(table)), function(i) {
    source_line <- i + line_offset
    c(
      wavelength = .parse_import_number(table[[1L]][[i]], "wavelength",
                                        context, i, source_line),
      reflectance = .parse_import_number(table[[2L]][[i]], "reflectance",
                                         context, i, source_line)
    )
  }, numeric(2L)))
  wavelength <- parsed[, "wavelength"]
  reflectance <- parsed[, "reflectance"]
  .validate_import_grid(wavelength, context,
                        seq_len(nrow(table)) + line_offset)
  outside <- which(reflectance < 0 | reflectance > 1)
  if (length(outside)) {
    i <- outside[[1L]]
    .stop_spectrum_import(
      paste0("Reflectance must lie in [0, 1]; row ", i, " is ",
             format(reflectance[[i]]), "."),
      context, class = "luxR_spectrum_value_error", field = "reflectance",
      value = reflectance[[i]], row = i, line = i + line_offset
    )
  }
  if (min(lambda) < min(wavelength) || max(lambda) > max(wavelength)) {
    .stop_spectrum_import(
      paste0("Target wavelength range ", min(lambda), "--", max(lambda),
             " nm exceeds measured reflectance coverage ", min(wavelength),
             "--", max(wavelength), " nm; endpoint extrapolation is disabled."),
      context, class = "luxR_spectrum_value_error", field = "lambda",
      value = range(lambda)
    )
  }
  result <- stats::approx(wavelength, reflectance, xout = lambda,
                          ties = "ordered")$y
  if (any(!is.finite(result))) {
    .stop_spectrum_import(
      "Reflectance interpolation produced non-finite values.", context,
      class = "luxR_spectrum_value_error", field = "reflectance",
      value = result
    )
  }
  attr(result, "luxR.import") <- context
  attr(result, "luxR.preprocessing") <- list(
    method = "linear interpolation", measured_range_nm = range(wavelength),
    target_range_nm = range(lambda)
  )
  result
}
