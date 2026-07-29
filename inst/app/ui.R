navbarPage(
  title = tagList(
    tags$img(
      src = "logo.png",
      alt = "luxR package logo",
      style = paste(
        "height: 34px;",
        "width: auto;",
        "margin-right: 8px;",
        "vertical-align: middle;"
      )
    ),
    tags$span("luxR — Underwater Light Explorer")
  ),
  windowTitle = "luxR — Underwater Light Explorer",
  theme = NULL,

  # ---- Tab 1: Depth Propagation -------------------------------------------
  tabPanel(
    APP_TAB_TITLES[["depth"]],
    value = "depth",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Light Source"),
        radioButtons("source_type", NULL,
                     choices = c("Solar spectrum" = "solar",
                                 "Upload file"    = "upload"),
                     selected = "solar"),
        conditionalPanel(
          condition = "input.source_type == 'solar'",
          selectInput("solar_cond", "Condition",
                      choices = SOLAR_LABELS,
                      selected = "clear_noon")
        ),
        conditionalPanel(
          condition = "input.source_type == 'upload'",
          helpText("Upload calibrated Ocean Optics spectral irradiance. ",
                   "TriOS radiance cannot be converted to irradiance without ",
                   "angular measurements and is not supported in this tab."),
          fileInput("upload_file", "Ocean Optics spectrum file"),
          selectInput(
            "upload_unit", "Declared spectral irradiance unit",
            choices = c("W m⁻² nm⁻¹"           = "W/m2/nm",
                        "µmol m⁻² s⁻¹ nm⁻¹"    = "umol/m2/s/nm",
                        "mmol m⁻² s⁻¹ nm⁻¹"    = "mmol/m2/s/nm",
                        "mol m⁻² s⁻¹ nm⁻¹"     = "mol/m2/s/nm"),
            selected = "W/m2/nm"
          ),
          textInput(
            "upload_calibration", "Calibration declaration",
            value = "",
            placeholder = "Certificate, method, or processing record"
          ),
          numericInput("upload_reference_depth",
                       "Spectrum reference depth below surface (m)",
                       value = 0, min = 0, max = 200, step = 1),
          actionButton("dp_example", "Load example data",
                       class = "btn-link", style = "padding-left:0"),
          helpText("Example: a small field spectrum from Mare Chiaro, Gulf of",
                   "Naples (Bok & Kirwan 2021) — a sample to try the workflow,",
                   "not a reference like the solar spectra.")
        ),
        hr(),
        h4("Water Column"),
        selectInput("wtype", "Jerlov water type",
                    choices = setNames(JERLOV_TYPES, JERLOV_TYPES),
                    selected = "IA"),
        selectInput(
          "dp_wavelength_policy", "Outside Jerlov's 350–700 nm range",
          choices = c(
            "Restrict calculation to 350–700 nm" = "trim",
            "Stop with an error" = "error",
            "Extend nearest endpoint Kd (assumption)" = "constant"
          ),
          selected = "trim"
        ),
        sliderInput("depths", "Target depths below surface (m)",
                    min = 0, max = 200, value = c(10, 50), step = 5),
        numericInput("depth_step", "Depth step (m)", value = 10,
                     min = 1, max = 50, step = 1),
        hr(),
        h4("Display"),
        selectInput("dp_unit", "Y-axis unit",
                    choices = c("W m⁻² nm⁻¹"            = "W_nm",
                                "photons m⁻² s⁻¹ nm⁻¹"  = "photon_nm",
                                "log₁₀ photons"         = "log_photon"),
                    selected = "W_nm")
      ),
      mainPanel(
        width = 9,
        helpText(
          "Model: wavelength-resolved Beer–Lambert attenuation with a constant ",
          "Jerlov Kd over each path. Wavelengths propagate independently; this ",
          "is not an angular or multiple-scattering radiative-transfer solver."
        ),
        uiOutput("dp_import_status"),
        plotOutput("dp_plot", height = "450px"),
        hr(),
        tableOutput("dp_summary"),
        downloadButton("dp_download", "Download summary (CSV)"),
        uiOutput("dp_refs")
      )
    )
  ),

  # ---- Tab 2: Species Perception ------------------------------------------
  tabPanel(
    APP_TAB_TITLES[["perception"]],
    value = "perception",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Photoreceptor"),
        selectInput("sp_species", "Species",
                    choices = SPECIES_LIST,
                    selected = SPECIES_LIST[1]),
        uiOutput("sp_receptor_ui"),
        sliderInput("sp_od", "Axial optical density",
                    min = 0, max = 2, value = 0.4, step = 0.05),
        helpText("Optical density of the photoreceptor outer segment. 0 = the",
                 "bare pigment template; higher values raise photon capture and",
                 "broaden the curve (self-screening), as in long deep-sea cells."),
        hr(),
        h4("Light Field"),
        selectInput("sp_solar", "Solar condition",
                    choices = SOLAR_LABELS, selected = "clear_noon"),
        hr(),
        actionButton("sp_calc", "Calculate quantum catch",
                     class = "btn-primary", width = "100%")
      ),
      mainPanel(
        width = 9,
        plotOutput("sp_plot", height = "420px"),
        hr(),
        wellPanel(
          h4("Sensitivity-weighted photon irradiance"),
          verbatimTextOutput("sp_qcatch"),
          downloadButton("sp_download", "Download result and assumptions (CSV)")
        ),
        uiOutput("sp_refs")
      )
    )
  ),

  # ---- Tab 3: Colour discrimination ---------------------------------------
  tabPanel(
    APP_TAB_TITLES[["colour"]],
    value = "colour",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Light field"),
        selectInput("jnd_solar", "Solar condition",
                    choices = SOLAR_LABELS, selected = "clear_noon"),
        selectInput("jnd_wtype", "Jerlov water type",
                    choices = setNames(JERLOV_TYPES, JERLOV_TYPES),
                    selected = "IA"),
        selectInput(
          "jnd_wavelength_policy", "Outside Jerlov's 350–700 nm range",
          choices = c(
            "Restrict calculation to 350–700 nm" = "trim",
            "Stop with an error" = "error",
            "Extend nearest endpoint Kd (assumption)" = "constant"
          ),
          selected = "trim"
        ),
        numericInput("jnd_depth", "Target depth below surface (m)",
                     value = 5, min = 0, max = 200),
        hr(),
        h4("Viewer"),
        selectInput("jnd_species", "Species",
                    choices = CHROMATIC_SPECIES_LIST,
                    selected = CHROMATIC_SPECIES_LIST[1]),
        hr(),
        h4("Two reflectances"),
        selectInput("jnd_r1", "Reflectance 1",
                    choices = c("Grey" = "grey", "Red" = "red",
                                "Green" = "green", "Blue" = "blue",
                                "Upload CSV" = "upload"),
                    selected = "grey"),
        conditionalPanel("input.jnd_r1 == 'upload'",
                         fileInput("jnd_r1_file", "Reflectance 1 CSV")),
        selectInput("jnd_r2", "Reflectance 2",
                    choices = c("Grey" = "grey", "Red" = "red",
                                "Green" = "green", "Blue" = "blue",
                                "Upload CSV" = "upload"),
                    selected = "red"),
        conditionalPanel("input.jnd_r2 == 'upload'",
                         fileInput("jnd_r2_file", "Reflectance 2 CSV")),
        hr(),
        actionButton("jnd_calc", "Compute JND",
                     class = "btn-primary", width = "100%")
      ),
      mainPanel(
        width = 9,
        plotOutput("jnd_plot", height = "380px"),
        hr(),
        wellPanel(h4("Colour discrimination"),
                  verbatimTextOutput("jnd_out")),
        uiOutput("jnd_refs")
      )
    )
  ),

  # ---- Tab 4: Visibility --------------------------------------------------
  tabPanel(
    APP_TAB_TITLES[["visibility"]],
    value = "visibility",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Water"),
        selectInput("vis_wtype", "Jerlov water type",
                    choices = setNames(JERLOV_TYPES, JERLOV_TYPES),
                    selected = "IA"),
        numericInput("vis_lambda", "Reference wavelength (nm)",
                     value = 550, min = 350, max = 700, step = 10),
        hr(),
        sliderInput("vis_photic", "Photic fraction",
                    min = 0.001, max = 0.1, value = 0.01, step = 0.001),
        sliderInput("vis_contrast", "Contrast threshold",
                    min = 0.005, max = 0.1, value = 0.02, step = 0.005),
        hr(),
        checkboxInput("vis_use_c",
                      "Use measured beam attenuation (c = a + b)", FALSE),
        conditionalPanel(
          "input.vis_use_c == true",
          numericInput("vis_a", "Absorption a (1/m)",
                       value = 0.20, min = 0, step = 0.01),
          numericInput("vis_b", "Scattering b (1/m)",
                       value = 0.10, min = 0, step = 0.01)
        )
      ),
      mainPanel(
        width = 9,
        wellPanel(h4("Visibility metrics"),
                  tableOutput("vis_table")),
        verbatimTextOutput("vis_context"),
        helpText("Secchi, photic, and horizontal visual range derived from the",
                 "diffuse attenuation coefficient Kd at the reference wavelength.",
                 "The visual-range value is an unvalidated contrast-threshold",
                 "scenario estimate, not an actual observer detection range.",
                 "By default visual range uses the c = Kd × 1.5 proxy and may",
                 "overestimate range for coastal water types (C1–C3); tick the",
                 "box to supply a measured beam attenuation c = a + b instead."),
        uiOutput("vis_refs")
      )
    )
  ),

  # ---- Tab 5: Detection ---------------------------------------------------
  tabPanel(
    APP_TAB_TITLES[["detection"]],
    value = "detection",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Light field"),
        selectInput("det_solar", "Solar condition",
                    choices = SOLAR_LABELS, selected = "clear_noon"),
        selectInput("det_wtype", "Jerlov water type",
                    choices = setNames(JERLOV_TYPES, JERLOV_TYPES),
                    selected = "IA"),
        selectInput(
          "det_wavelength_policy", "Outside Jerlov's 350–700 nm range",
          choices = c(
            "Restrict calculation to 350–700 nm" = "trim",
            "Stop with an error" = "error",
            "Extend nearest endpoint Kd (assumption)" = "constant"
          ),
          selected = "trim"
        ),
        numericInput("det_depth", "Target depth below surface (m)",
                     value = 5, min = 0, max = 200),
        numericInput("det_lambda", "Sighting wavelength (nm)",
                     value = 490, min = 350, max = 700, step = 10),
        hr(),
        h4("Viewer"),
        selectInput("det_species", "Species",
                    choices = DETECTION_SPECIES_LIST,
                    selected = DETECTION_SPECIES_LIST[1]),
        hr(),
        h4("Object vs background"),
        selectInput("det_obj", "Object reflectance",
                    choices = c("Grey" = "grey", "Red" = "red",
                                "Green" = "green", "Blue" = "blue",
                                "Upload CSV" = "upload"), selected = "red"),
        conditionalPanel("input.det_obj == 'upload'",
                         fileInput("det_obj_file", "Object CSV")),
        selectInput("det_bg", "Background reflectance",
                    choices = c("Grey" = "grey", "Red" = "red",
                                "Green" = "green", "Blue" = "blue",
                                "Upload CSV" = "upload"), selected = "grey"),
        conditionalPanel("input.det_bg == 'upload'",
                         fileInput("det_bg_file", "Background CSV")),
        hr(),
        h4("Viewing"),
        selectInput("det_dir", "Direction",
                    choices = c("Horizontal" = "horizontal",
                                "Looking up" = "up", "Looking down" = "down"),
                    selected = "horizontal"),
        sliderInput("det_contrast", "Achromatic threshold (Weber)",
                    min = 0.005, max = 0.1, value = 0.02, step = 0.005),
        hr(),
        checkboxInput("det_use_c",
                      "Use measured beam attenuation (c = a + b)", FALSE),
        conditionalPanel(
          "input.det_use_c == true",
          numericInput("det_a", "Absorption a (1/m)",
                       value = 0.20, min = 0, step = 0.01),
          numericInput("det_b", "Scattering b (1/m)",
                       value = 0.10, min = 0, step = 0.01)
        )
      ),
      mainPanel(
        width = 9,
        wellPanel(
          strong("Heuristic scenario only. "),
          "This scalar contrast/JND calculation is not an empirically ",
          "validated prediction of actual detection distance."
        ),
        plotOutput("det_plot", height = "420px"),
        hr(),
        wellPanel(h4("Threshold-distance estimate"),
                  verbatimTextOutput("det_out")),
        uiOutput("det_refs")
      )
    )
  )

)
