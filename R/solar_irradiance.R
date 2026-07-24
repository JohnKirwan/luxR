# solar_irradiance.R — reference surface spectra

#' Reference solar spectral irradiance under standard conditions.
#'
#' Returns a reference spectrum from the bundled \code{solar_spectra} dataset,
#' based on ASTM G173-03 global-tilt values scaled to several representative
#' illumination conditions. Intended for use as the reference shape in
#' \code{\link{broadband2spectrum}} and \code{\link{lux2irradiance}}.
#'
#' @details
#' Available conditions:
#' \describe{
#'   \item{\code{"clear_noon"}}{Full-sun midday irradiance (ASTM G173-03 GTI).}
#'   \item{\code{"clear_dawn"}}{Clear sky near sunrise/sunset (~35\% of noon).}
#'   \item{\code{"overcast"}}{Overcast diffuse sky (~22\% of noon).}
#'   \item{\code{"underwater_1m"}}{ASTM GTI attenuated through 1 m of Jerlov IA water.}
#'   \item{\code{"underwater_10m"}}{ASTM GTI attenuated through 10 m of Jerlov IA water.}
#' }
#' The historical underwater sources span 300--800 nm and were generated with
#' constant endpoint extension beyond the bundled Jerlov dataset's supported
#' 350--700 nm domain. Their attributes explicitly record this assumption and
#' the Jerlov table checksum so it is not a silent extrapolation path.
#'
#' @param condition Character string naming the illumination condition.
#'   One of the five conditions listed in Details.
#' @return A data frame with columns \code{wavelength} (nm) and
#'   \code{irradiance} (W/m^2/nm). Attributes record \code{condition},
#'   \code{reference_depth_m} (metres relative to the water surface), and
#'   \code{reference_medium} (\code{"air"} or \code{"water"}).
#' @examples
#' solar_irradiance("clear_noon")
#' broadband2spectrum(480, unit = "W", spectrum = solar_irradiance("overcast"))
#' @export
solar_irradiance <- function(condition = "clear_noon") {
  valid <- names(solar_spectra)
  if (!condition %in% valid)
    stop("unknown condition: '", condition, "'. ",
         "Valid: ", paste(valid, collapse = ", "))

  spectrum <- solar_spectra[[condition]]
  .validate_solar_source_metadata(spectrum, condition)
  spectrum
}

.validate_solar_source_metadata <- function(spectrum, condition) {
  stored_condition <- attr(spectrum, "condition", exact = TRUE)
  reference_depth <- attr(spectrum, "reference_depth_m", exact = TRUE)
  reference_medium <- attr(spectrum, "reference_medium", exact = TRUE)

  if (!identical(stored_condition, condition)) {
    .stop_solar_source_metadata(
      condition, "condition", stored_condition,
      "missing or inconsistent metadata"
    )
  }
  if (!is.numeric(reference_depth) || length(reference_depth) != 1L ||
      !is.finite(reference_depth) || reference_depth < 0) {
    .stop_solar_source_metadata(
      condition, "reference_depth_m", reference_depth, "invalid metadata"
    )
  }
  if (!is.character(reference_medium) || length(reference_medium) != 1L ||
      is.na(reference_medium) ||
      !reference_medium %in% c("air", "water")) {
    .stop_solar_source_metadata(
      condition, "reference_medium", reference_medium, "invalid metadata"
    )
  }
  if (identical(reference_medium, "water")) {
    policy <- attr(spectrum, "jerlov_wavelength_policy", exact = TRUE)
    supported <- attr(
      spectrum, "jerlov_supported_wavelength_range_nm", exact = TRUE
    )
    checksum <- attr(spectrum, "jerlov_table_checksum_md5", exact = TRUE)
    input_range <- attr(
      spectrum, "jerlov_input_wavelength_range_nm", exact = TRUE
    )
    if (!identical(policy, "constant") ||
        !identical(supported, c(350, 700)) ||
        !identical(input_range, range(spectrum$wavelength)) ||
        input_range[[1L]] > supported[[1L]] ||
        input_range[[2L]] < supported[[2L]] ||
        !is.character(checksum) || length(checksum) != 1L ||
        is.na(checksum) || !grepl("^[0-9a-f]{32}$", checksum)) {
      .stop_solar_source_metadata(
        condition, "jerlov_wavelength_policy", policy,
        "missing or invalid Jerlov-domain metadata"
      )
    }
  }

  invisible(spectrum)
}

.stop_solar_source_metadata <- function(condition, field, value, problem) {
  error <- structure(
    list(
      message = paste0(
        "Bundled dataset `solar_spectra`, source '", condition, "', has ",
        problem, " for `", field, "`."
      ),
      call = NULL,
      dataset = "solar_spectra",
      source_condition = condition,
      field = field,
      value = value
    ),
    class = c("luxR_source_metadata_error", "error", "condition")
  )
  stop(error)
}
