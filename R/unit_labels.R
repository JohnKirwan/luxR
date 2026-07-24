# Rendered unit labels -- the display counterpart to the ASCII controlled
# vocabulary in .UNIT_QUANTITIES. The vocabulary is closed and validated at
# construction, so a lookup table is preferred over a token parser: it is
# auditable at a glance and cannot mis-parse. test-unit-labels.R asserts that
# this table stays in sync with .VALID_UNITS.
#
# Non-ASCII is written as \u escapes per CRAN policy; the rendered form is
# shown in the trailing comment on each line.
#   µ MICRO SIGN          ² SUPERSCRIPT TWO
#   ⁻ SUPERSCRIPT MINUS   ¹ SUPERSCRIPT ONE

.UNIT_LABELS_UTF8 <- c(
  "W/m2/nm" =
    "W m\u207b\u00b2 nm\u207b\u00b9",  # W m⁻² nm⁻¹
  "umol/m2/s/nm" =
    "\u00b5mol m\u207b\u00b2 s\u207b\u00b9 nm\u207b\u00b9",  # µmol m⁻² s⁻¹ nm⁻¹
  "mmol/m2/s/nm" =
    "mmol m\u207b\u00b2 s\u207b\u00b9 nm\u207b\u00b9",  # mmol m⁻² s⁻¹ nm⁻¹
  "mol/m2/s/nm" =
    "mol m\u207b\u00b2 s\u207b\u00b9 nm\u207b\u00b9",  # mol m⁻² s⁻¹ nm⁻¹
  "W/m2/sr/nm" =
    "W m\u207b\u00b2 sr\u207b\u00b9 nm\u207b\u00b9",  # W m⁻² sr⁻¹ nm⁻¹
  "mW/m2/sr/nm" =
    "mW m\u207b\u00b2 sr\u207b\u00b9 nm\u207b\u00b9",  # mW m⁻² sr⁻¹ nm⁻¹
  "umol/m2/s/sr/nm" =
    "\u00b5mol m\u207b\u00b2 s\u207b\u00b9 sr\u207b\u00b9 nm\u207b\u00b9",  # µmol m⁻² s⁻¹ sr⁻¹ nm⁻¹
  "mmol/m2/s/sr/nm" =
    "mmol m\u207b\u00b2 s\u207b\u00b9 sr\u207b\u00b9 nm\u207b\u00b9",  # mmol m⁻² s⁻¹ sr⁻¹ nm⁻¹
  "mol/m2/s/sr/nm" =
    "mol m\u207b\u00b2 s\u207b\u00b9 sr\u207b\u00b9 nm\u207b\u00b9",  # mol m⁻² s⁻¹ sr⁻¹ nm⁻¹
  "dimensionless" =
    "dimensionless"  # dimensionless
)

.UNIT_LABELS_PLOTMATH <- c(
  "W/m2/nm"         = "W~m^{-2}~nm^{-1}",
  "umol/m2/s/nm"    = "mu*mol~m^{-2}~s^{-1}~nm^{-1}",
  "mmol/m2/s/nm"    = "mmol~m^{-2}~s^{-1}~nm^{-1}",
  "mol/m2/s/nm"     = "mol~m^{-2}~s^{-1}~nm^{-1}",
  "W/m2/sr/nm"      = "W~m^{-2}~sr^{-1}~nm^{-1}",
  "mW/m2/sr/nm"     = "mW~m^{-2}~sr^{-1}~nm^{-1}",
  "umol/m2/s/sr/nm" = "mu*mol~m^{-2}~s^{-1}~sr^{-1}~nm^{-1}",
  "mmol/m2/s/sr/nm" = "mmol~m^{-2}~s^{-1}~sr^{-1}~nm^{-1}",
  "mol/m2/s/sr/nm"  = "mol~m^{-2}~s^{-1}~sr^{-1}~nm^{-1}",
  "dimensionless"   = "dimensionless"
)

#' @keywords internal
#' @noRd
.lookup_unit_label <- function(unit, table) {
  if (!is.character(unit) || length(unit) != 1L || is.na(unit)) {
    stop("`unit` must be a single non-NA character string.", call. = FALSE)
  }
  if (!unit %in% names(table)) {
    stop("`unit` '", unit, "' is not in the controlled vocabulary. ",
         "Valid units: ", paste(.VALID_UNITS, collapse = ", "), ".",
         call. = FALSE)
  }
  unname(table[[unit]])
}

#' Render a unit string for display
#'
#' Formats a unit from the controlled vocabulary as a human-readable label
#' using SI negative exponents, for use in table headers, user interfaces,
#' and prose. The canonical unit strings stored in
#' \code{lux_spectrum$unit} are deliberately ASCII (\code{"umol/m2/s/nm"}) so
#' they remain stable identifiers; this function is the display counterpart.
#'
#' @param unit A single unit string from the controlled vocabulary. See
#'   \code{\link{lux_spectrum}} for the valid values.
#' @return A length-1 character vector holding the rendered label, e.g.
#'   \eqn{\mu mol\,m^{-2}\,s^{-1}\,nm^{-1}}{mu mol m^-2 s^-1 nm^-1} for
#'   \code{"umol/m2/s/nm"}.
#' @seealso \code{\link{unit_expression}} for the plotmath equivalent used in
#'   plot axis labels.
#' @examples
#' unit_label("umol/m2/s/nm")
#' unit_label("W/m2/sr/nm")
#' @export
unit_label <- function(unit) {
  .lookup_unit_label(unit, .UNIT_LABELS_UTF8)
}

#' Render a unit string as a plotmath expression
#'
#' Formats a unit from the controlled vocabulary as a plotmath language
#' object with SI negative exponents, suitable for passing directly as the
#' \code{xlab} or \code{ylab} of a base graphics plot.
#'
#' @param unit A single unit string from the controlled vocabulary. See
#'   \code{\link{lux_spectrum}} for the valid values.
#' @return A language object suitable for use as a plot label.
#' @seealso \code{\link{unit_label}} for the plain-text equivalent.
#' @examples
#' plot(400:700, rep(1, 301), type = "l",
#'      xlab = "Wavelength (nm)", ylab = unit_expression("W/m2/nm"))
#' @export
unit_expression <- function(unit) {
  parse(text = .lookup_unit_label(unit, .UNIT_LABELS_PLOTMATH))[[1]]
}
