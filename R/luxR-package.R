#' luxR: Underwater Light Analysis and Visual Ecology
#'
#' Tools for quantifying and modelling underwater light environments.
#' Propagates spectral irradiance through the water column via Beer-Lambert
#' attenuation, computes PAR, and converts between energy and photon-flux
#' units. Provides the \code{\link{lux_spectrum}} S3 class for unit-safe
#' spectral arithmetic and native format readers for TriOS RAMSES and Ocean
#' Optics instruments. Optional \pkg{lightr} interoperability preserves native
#' instrument records until their measurement, scale, calibration, and
#' resampling policies are explicitly declared. Includes visual ecology
#' utilities: Govardovskii (2000)
#' visual-pigment templates, photoreceptor quantum catch,
#' Vorobyev-Osorio colour discrimination (JND), Secchi depth, and
#' heuristic horizontal visual-range and object-detection scenarios.
#'
#' @seealso
#' Useful links:
#' \itemize{
#'   \item \url{https://johnkirwan.github.io/luxR/}
#'   \item \url{https://github.com/JohnKirwan/luxR}
#'   \item Report bugs at \url{https://github.com/JohnKirwan/luxR/issues}
#' }
#'
#' @docType package
#' @name luxR-package
#' @aliases luxR
#' @importFrom Rdpack reprompt
"_PACKAGE"
