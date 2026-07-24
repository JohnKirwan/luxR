# read_spectrum - declared physical spectral import via lightr

#' Read a declared, calibrated spectrum with lightr
#'
#' Parses one instrument file with \code{\link{read_instrument_spectrum}}, then
#' applies explicit scale and negative-value policies before constructing a
#' \code{\link{lux_spectrum}}. Typical native spectrometer grids are irregular,
#' so \code{interpolate = TRUE} is normally required. Use
#' \code{read_instrument_spectrum(interpolate = FALSE)} to inspect or retain
#' native sampling without claiming it satisfies the \code{lux_spectrum} grid
#' contract.
#'
#' @param path Path to one spectral file.
#' @param measurement Declared measurement represented by lightr's processed
#'   values. See \code{\link{read_instrument_spectrum}}.
#' @param value_scale Declared input scale: \code{"percent"} or
#'   \code{"fraction"} for reflectance, and \code{"absolute"} for irradiance
#'   or radiance.
#' @param quantity Explicit luxR physical quantity. It must match
#'   \code{measurement}.
#' @param unit Explicit unit compatible with \code{quantity}.
#' @param calibration Non-empty calibration identifier or description.
#' @param range Required finite increasing wavelength limits in nm.
#' @param interpolate Whether lightr should interpolate to integer nanometres.
#'   Defaults to \code{FALSE}; irregular native grids will fail construction
#'   with guidance to opt in or retain the instrument record.
#' @param negative_policy Either \code{"error"} (default) or an explicit,
#'   recorded \code{"zero"} floor.
#' @param parser_args Named list of simple scalar arguments passed to the
#'   lightr parser.
#' @param warning_policy Whether lightr warnings should fail the import or be
#'   explicitly retained. Defaults to fail-fast behavior.
#' @return A validated \code{\link{lux_spectrum}} with calibration, instrument
#'   metadata, parser provenance, notices, scaling, and resampling policy.
#' @seealso \code{\link{read_instrument_spectrum}},
#'   \code{\link{from_ocean_optics}}, \code{\link{read_ocean_optics}},
#'   \code{\link{from_trios}}
#' @examples
#' \dontrun{
#' x <- read_spectrum(
#'   "path/to/calibrated-irradiance.IRR8",
#'   measurement = "irradiance", value_scale = "absolute",
#'   quantity = "irradiance", unit = "W/m2/nm",
#'   calibration = "certificate CAL-2026-04",
#'   range = c(300, 700), interpolate = TRUE
#' )
#' }
#' @export
read_spectrum <- function(
    path, measurement = NULL, value_scale = NULL, quantity = NULL, unit = NULL,
    calibration = NULL, range = NULL, interpolate = FALSE,
    negative_policy = "error", parser_args = list(),
    warning_policy = "error") {
  instrument <- read_instrument_spectrum(
    path = path, measurement = measurement, value_scale = value_scale,
    range = range, interpolate = interpolate, parser_args = parser_args,
    warning_policy = warning_policy
  )
  instrument$meta$import$operation <- "read_spectrum"
  as_lux_spectrum(
    instrument, quantity = quantity, unit = unit, calibration = calibration,
    negative_policy = negative_policy
  )
}
