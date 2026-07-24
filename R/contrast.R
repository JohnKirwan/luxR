#' Michelson contrast
#'
#' Computes the Michelson (sinusoidal) contrast: \eqn{(I_{bright} - I_{dark}) /
#' (I_{bright} + I_{dark})}. Values range from 0 (no contrast) to 1 (maximum
#' contrast). Commonly used for periodic patterns such as gratings.
#'
#' @param I_bright Luminance or radiance of the brighter region (scalar or
#'   vector). Must be \eqn{\ge I_{dark}}.
#' @param I_dark Luminance or radiance of the darker region (scalar or vector).
#' @return Contrast value(s) in \eqn{[0, 1]}.
#' @seealso [weber_contrast()]
#' @examples
#' michelson_contrast(I_bright = 8, I_dark = 2)
#' @export
michelson_contrast <- function(I_bright, I_dark) {
  if (any(I_bright + I_dark == 0))
    stop("I_bright and I_dark cannot both be zero.")
  if (any(I_bright < I_dark))
    stop("I_bright must be >= I_dark. Check argument order.")
  (I_bright - I_dark) / (I_bright + I_dark)
}

#' Weber contrast
#'
#' Computes the Weber contrast: \eqn{(I_{target} - I_{background}) /
#' I_{background}}. Positive values indicate a target brighter than its
#' background; negative values indicate a darker target. Commonly used for
#' isolated objects on a uniform background.
#'
#' @param I_target Luminance or radiance of the target (scalar or vector).
#' @param I_background Luminance or radiance of the background (scalar or
#'   vector). Must be non-zero.
#' @return Contrast value(s); unbounded but typically in \eqn{[-1, \infty)}.
#' @seealso [michelson_contrast()]
#' @examples
#' weber_contrast(I_target = 8, I_background = 4)
#' @export
weber_contrast <- function(I_target, I_background) {
  if (any(I_background == 0))
    stop("I_background cannot be zero.")
  (I_target - I_background) / I_background
}
