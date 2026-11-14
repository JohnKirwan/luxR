# species_perception.R — photoreceptor quantum catches

#' Govardovskii et al. (2000) visual-pigment template.
#'
#' Reconstructs a photoreceptor's normalised absorbance spectrum from the
#' peak wavelength alone, using the parametric template of Govardovskii et al.
#' (2000) for A1 and A2 chromophores. This is the standard workhorse of
#' comparative visual physiology.
#'
#' @details
#' The template models absorbance as the sum of an \eqn{\alpha}-band (main peak)
#' and a \eqn{\beta}-band (short-wavelength shoulder). The \eqn{\alpha}-band
#' follows eqn 1 of Govardovskii et al. (2000):
#' \deqn{S_\alpha(\lambda) = \left[
#'   e^{A(a - x)} + e^{B(b - x)} + e^{C(c - x)} + D
#' \right]^{-1}, \quad x = \frac{\lambda_{\max}}{\lambda}}
#' and the \eqn{\beta}-band is a Gaussian (eqn 4):
#' \deqn{S_\beta(\lambda) = A_\beta \exp\!\left[
#'   -\!\left(\frac{\lambda - \lambda_{m\beta}}{w}\right)^2
#' \right]}
#' The constants depend on the chromophore:
#' \itemize{
#'   \item A1 (eqns 2, 5): \eqn{A = 69.7},
#'     \eqn{a = 0.8795 + 0.0459\,e^{-(\lambda_{\max} - 300)^2/11940}},
#'     \eqn{B = 28}, \eqn{b = 0.922}, \eqn{C = -14.9}, \eqn{c = 1.104},
#'     \eqn{D = 0.674}; \eqn{A_\beta = 0.26},
#'     \eqn{\lambda_{m\beta} = 189 + 0.315\,\lambda_{\max}},
#'     \eqn{w = -40.5 + 0.195\,\lambda_{\max}}.
#'   \item A2 (eqns 6, 8): \eqn{A = 62.7 + 1.834\,e^{(\lambda_{\max} - 625)/54.2}},
#'     \eqn{a = 0.875 + 0.0268\,e^{(\lambda_{\max} - 665)/40.7}},
#'     \eqn{B = 20.85}, \eqn{b = 0.9101}, \eqn{C = -10.37}, \eqn{c = 1.1123},
#'     \eqn{D = 0.5343}; \eqn{A_\beta = 0.37},
#'     \eqn{\lambda_{m\beta} = 216.7 + 0.287\,\lambda_{\max}},
#'     \eqn{w = 317 - 1.149\,\lambda_{\max} + 0.00124\,\lambda_{\max}^2}.
#' }
#' The full template \eqn{S_\alpha + S_\beta} is normalised to its own maximum,
#' which lies within a few nm of \eqn{\lambda_{\max}} and is found numerically,
#' so the returned values do not depend on the wavelength grid supplied: a grid
#' that misses the peak returns values below 1 rather than being rescaled.
#'
#' The A2 template was fitted to pigments peaking between about 444 and 620 nm,
#' so \code{lambda_max} outside 440--620 nm is rejected for A2. A1 accepts
#' 300--700 nm.
#'
#' @param lambda      Wavelength grid in nm (numeric vector).
#' @param lambda_max  Peak absorbance wavelength in nm: 300--700 for A1,
#'   440--620 for A2.
#' @param chromophore Chromophore type: \code{"A1"} (11-cis retinal, default)
#'   or \code{"A2"} (11-cis 3,4-didehydroretinal). For the same
#'   \code{lambda_max}, the A2 spectrum is broader.
#' @return A data frame with columns \code{lambda} and \code{S} (normalised
#'   absorbance, at most 1; it reaches 1 only if \code{lambda} includes the
#'   template's peak).
#' @references
#'   Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000)
#'   In search of the visual pigment template. Visual Neuroscience 17:509–528.
#' @examples
#' lam <- seq(300, 750, by = 1)
#' govardovskii_template(lam, lambda_max = 560)
#' @export
govardovskii_template <- function(lambda, lambda_max,
                                   chromophore = c("A1", "A2")) {
  .check_template_grid(lambda)
  chromophore <- match.arg(chromophore)
  range <- .template_range[[chromophore]]
  if (!is.numeric(lambda_max) || is.complex(lambda_max) ||
      is.object(lambda_max) || !is.null(dim(lambda_max)) ||
      length(lambda_max) != 1L || !is.finite(lambda_max) ||
      lambda_max < range[1] || lambda_max > range[2]) {
    .luxr_abort(
      sprintf("'lambda_max' must be one finite number between %d and %d nm for an %s template.",
              range[1], range[2], chromophore),
      "value",
      field = "lambda_max", value = lambda_max
    )
  }

  S <- .govardovskii_raw(lambda, lambda_max, chromophore)
  # Normalise to the template's own maximum, which lies just below
  # `lambda_max`, so the values do not depend on the grid supplied. `max()`
  # with the on-grid values keeps S <= 1 despite the optimiser's tolerance.
  peak <- stats::optimize(.govardovskii_raw, lambda_max * c(0.95, 1.01),
                          lambda_max = lambda_max, chromophore = chromophore,
                          maximum = TRUE, tol = 1e-6)$objective
  data.frame(lambda = lambda, S = S / max(peak, S))
}

.check_template_grid <- function(lambda) {
  if (!is.numeric(lambda) || is.complex(lambda) || is.object(lambda) ||
      !is.null(dim(lambda)) || length(lambda) == 0L ||
      any(!is.finite(lambda)) || any(lambda <= 0) ||
      any(diff(lambda) <= 0)) {
    .luxr_abort(
      "'lambda' must be a non-empty, finite, strictly increasing vector of positive wavelengths.",
      "grid",
      field = "lambda", value = lambda
    )
  }
}

# Valid lambda_max range (nm) per chromophore. A2 is limited to the range of
# pigments the A2 template was fitted to (Govardovskii et al. 2000, Table 1).
.template_range <- list(A1 = c(300L, 700L), A2 = c(440L, 620L))

# Govardovskii et al. (2000) parameters for a given lambda_max: alpha band
# (eqn 1) and beta band (eqn 4). A1: eqns 1, 2, 5a, 5b; A2: eqns 6a, 6b, 8a, 8b
# with the constants on p. 517.
.govardovskii_coefs <- function(lambda_max, chromophore) {
  if (chromophore == "A1") {
    list(A = 69.7, a = 0.8795 + 0.0459 * exp(-(lambda_max - 300)^2 / 11940),
         B = 28, b = 0.922, C = -14.9, c = 1.104, D = 0.674,
         A_beta = 0.26, l_beta = 189 + 0.315 * lambda_max,
         w_beta = -40.5 + 0.195 * lambda_max)
  } else {
    list(A = 62.7 + 1.834 * exp((lambda_max - 625) / 54.2),
         a = 0.875 + 0.0268 * exp((lambda_max - 665) / 40.7),
         B = 20.85, b = 0.9101, C = -10.37, c = 1.1123, D = 0.5343,
         A_beta = 0.37, l_beta = 216.7 + 0.287 * lambda_max,
         w_beta = 317 - 1.149 * lambda_max + 0.00124 * lambda_max^2)
  }
}

# Un-normalised Govardovskii template (alpha band plus beta band).
.govardovskii_raw <- function(lambda, lambda_max, chromophore) {
  p     <- .govardovskii_coefs(lambda_max, chromophore)
  x     <- lambda_max / lambda
  alpha <- 1 / (exp(p$A * (p$a - x)) + exp(p$B * (p$b - x)) +
                exp(p$C * (p$c - x)) + p$D)
  beta  <- p$A_beta * exp(-((lambda - p$l_beta) / p$w_beta)^2)
  alpha + beta
}


#' Photoreceptor absorptance from a normalised absorbance template (self-screening).
#'
#' Converts a normalised visual-pigment absorbance spectrum (e.g. from
#' \code{\link{govardovskii_template}}) into the receptor's \emph{absorptance} —
#' the fraction of incident photons actually captured at each wavelength — given
#' the axial optical density of the photoreceptor. At low optical density the
#' absorptance is nearly proportional to the template; at high optical density
#' the peak saturates toward 1 and the curve broadens ("self-screening"), so the
#' realised spectral sensitivity is wider than the bare pigment absorbance. This
#' is the sensitivity that should be fed to \code{\link{quantum_catch}} for long
#' or dense photoreceptors (e.g. deep-sea rods).
#'
#' @details
#' For a peak-normalised absorbance \eqn{S(\lambda)} and axial optical density
#' \eqn{D} (base-10 absorbance along the outer segment at the peak), the
#' absorptance is
#' \deqn{A(\lambda) = 1 - 10^{-D\,S(\lambda)} = 1 - e^{-\kappa\,S(\lambda)},}
#' with \eqn{\kappa = D\ln 10}. Equivalently, supply the peak absorption
#' coefficient \eqn{a_{\max}} (\code{alpha}, per unit length) and the
#' outer-segment \code{path_length} \eqn{\ell}, giving \eqn{\kappa = a_{\max}\ell}
#' (Johnsen 2012, ch. 4, eq. 4.8).
#'
#' @param S       A data frame with columns \code{lambda} and \code{S} (a
#'   normalised absorbance template, e.g. from \code{\link{govardovskii_template}}),
#'   or a bare numeric vector of normalised absorbance values. Values must be
#'   finite and in [0, 1]; they are not rescaled, so a template sampled on a
#'   grid that misses its peak keeps its true peak of 1 and the optical
#'   density refers to that peak.
#' @param optical_density Peak axial optical density (base-10 absorbance),
#'   dimensionless. Typically ~0.3–0.5 for vertebrate cones, up to ~1 or more
#'   for long deep-sea rods. Supply this \emph{or} (\code{alpha} and
#'   \code{path_length}), not both.
#' @param alpha   Peak absorption coefficient per unit length (e.g. per µm).
#' @param path_length Outer-segment (path) length, in the same length unit as
#'   \code{alpha}.
#' @return If \code{S} is a data frame, a data frame with columns \code{lambda}
#'   and \code{S} holding the absorptance (so it drops straight into
#'   \code{\link{quantum_catch}}); if \code{S} is numeric, a numeric vector of
#'   absorptance values in \eqn{[0, 1]}.
#' @references
#'   Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
#'   Nature. Princeton University Press. (Ch. 4: absorptance and self-screening.)
#' @seealso \code{\link{govardovskii_template}}, \code{\link{quantum_catch}}
#' @examples
#' lam  <- seq(300, 750, by = 1)
#' tmpl <- govardovskii_template(lam, lambda_max = 500)
#'
#' # Realised sensitivity of a moderately dense cone (axial OD 0.4):
#' A <- receptor_absorptance(tmpl, optical_density = 0.4)
#'
#' # A long deep-sea rod via Johnsen's absorption coefficient (0.064 / um):
#' A75 <- receptor_absorptance(tmpl, alpha = 0.064, path_length = 75)
#' @export
receptor_absorptance <- function(S, optical_density = NULL,
                                 alpha = NULL, path_length = NULL) {

  fail <- function(message, field, value = NULL, index = NULL,
                   kind = "value") {
    .luxr_abort(paste0("receptor_absorptance(): ", message), kind,
                field = field, value = value, index = index)
  }
  check <- function(x, field, ...) {
    .check_numeric(x, field, function(message, field, value, index, kind) {
      fail(message, field, value, index, kind)
    }, ...)
  }

  # ---- resolve the peak natural-log absorbance (kappa) --------------------
  has_od <- !is.null(optical_density)
  has_al <- !is.null(alpha) || !is.null(path_length)
  if (has_od == has_al)
    fail(paste0("supply either `optical_density`, or both `alpha` and ",
                "`path_length` (exactly one parameterisation)."),
         c("optical_density", "alpha", "path_length"))

  if (has_od) {
    check(optical_density, "optical_density", scalar = TRUE, lower = 0,
          lower_open = TRUE)
    kappa <- optical_density * log(10)
  } else {
    if (is.null(alpha) || is.null(path_length))
      fail("supply both `alpha` and `path_length`.", c("alpha", "path_length"))
    check(alpha, "alpha", scalar = TRUE, lower = 0, lower_open = TRUE)
    check(path_length, "path_length", scalar = TRUE, lower = 0,
          lower_open = TRUE)
    kappa <- alpha * path_length
  }

  # ---- S must already be a peak-normalised template -----------------------
  is_df  <- is.data.frame(S)
  s_vals <- if (is_df) S$S else S
  if (is.null(s_vals))
    fail("`S` must be a numeric vector or a data frame with an `S` column.",
         "S", class(S), kind = "type")
  check(s_vals, "S", lower = 0)
  over <- which(s_vals > 1 + sqrt(.Machine$double.eps))
  if (length(over) > 0L)
    fail(paste0("`S` must be a peak-normalised template with values in ",
                "[0, 1]; index ", over[1L], " is ", format(s_vals[over[1L]]),
                ". Normalise it first (e.g. govardovskii_template())."),
         "S", s_vals[over[1L]], over[1L],
         kind = "value")

  A <- 1 - exp(-kappa * s_vals)
  if (is_df) data.frame(lambda = S$lambda, S = A) else A
}


#' Fit a Govardovskii visual-pigment template to measured spectral sensitivity.
#'
#' Finds the peak wavelength (\eqn{\lambda_{\max}}) that minimises the sum of
#' squared residuals between the Govardovskii (2000) template and the supplied
#' sensitivity measurements. Uses \code{\link[stats]{optimize}} for an exact
#' single-parameter search, so the result is a continuous estimate rather than
#' a grid point.
#'
#' @param lambda           Wavelengths at which sensitivity was measured (nm).
#' @param sensitivity      Measured spectral sensitivity. Normalised to
#'   \eqn{[0, 1]} internally; need not be pre-normalised. \code{NA} values are
#'   silently dropped.
#' @param chromophore      \code{"A1"} (11-cis retinal, default) or
#'   \code{"A2"} (11-cis 3,4-didehydroretinal).
#' @param lambda_max_range Length-2 numeric vector giving the search interval
#'   for \eqn{\lambda_{\max}} in nm. Default \code{NULL} searches the
#'   chromophore's whole valid range (A1 300--700 nm, A2 440--620 nm); a range
#'   outside it is an error.
#' @return A list with components:
#'   \describe{
#'     \item{\code{lambda_max}}{Best-fit peak wavelength (nm).}
#'     \item{\code{chromophore}}{Chromophore used.}
#'     \item{\code{amplitude}}{Best-fit scale applied to the template to
#'       match the input, which is first rescaled to a maximum of 1. About 1
#'       when the measured wavelengths include the template's peak, and above
#'       1 (the inverse of the template's largest measured value) when the
#'       peak lies outside them.}
#'     \item{\code{SS}}{Residual sum of squares at the optimum, between the
#'       peak-normalised input and \code{amplitude * fitted$S}.}
#'     \item{\code{fitted}}{Data frame with columns \code{lambda} and \code{S}
#'       giving the template evaluated on the input wavelength grid.}
#'   }
#' @seealso \code{\link{govardovskii_template}}
#' @references
#'   Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000)
#'   In search of the visual pigment template. Visual Neuroscience 17:509--528.
#' @examples
#' lam   <- seq(400, 700, by = 10)
#' true  <- govardovskii_template(lam, lambda_max = 530)$S
#' noisy <- pmax(0, true + rnorm(length(true), 0, 0.02))
#' fit   <- fit_sensitivity(lam, noisy)
#' fit$lambda_max  # should be close to 530
#' @export
fit_sensitivity <- function(lambda, sensitivity,
                             chromophore      = c("A1", "A2"),
                             lambda_max_range = NULL) {
  chromophore <- match.arg(chromophore)
  valid <- .template_range[[chromophore]]
  if (is.null(lambda_max_range)) lambda_max_range <- valid
  fail <- function(message, field, value = NULL, kind = "value") {
    .luxr_abort(paste0("fit_sensitivity(): ", message), kind,
                field = field, value = value)
  }
  if (!is.numeric(sensitivity) || length(lambda) != length(sensitivity))
    fail(paste0("`sensitivity` must be numeric with one value per ",
                "wavelength; got ", length(sensitivity), " values for ",
                length(lambda), " wavelengths."),
         "sensitivity", length(sensitivity),
         kind = if (is.numeric(sensitivity)) "dimension" else "type")
  if (!is.numeric(lambda_max_range) || length(lambda_max_range) != 2L ||
      anyNA(lambda_max_range) || lambda_max_range[1] >= lambda_max_range[2])
    fail("`lambda_max_range` must be two increasing wavelengths.",
         "lambda_max_range", lambda_max_range)
  if (lambda_max_range[1] < valid[1] || lambda_max_range[2] > valid[2]) {
    .luxr_abort(
      sprintf("'lambda_max_range' must lie within %d-%d nm, where the %s template is defined.",
              valid[1], valid[2], chromophore),
      "value",
      field = "lambda_max_range", value = lambda_max_range
    )
  }
  .check_template_grid(lambda)

  # NA marks an unmeasured wavelength and is dropped (documented policy);
  # infinite values are errors.
  if (any(is.infinite(sensitivity)))
    fail("`sensitivity` must not contain infinite values.", "sensitivity",
         sensitivity[is.infinite(sensitivity)][1L],
         kind = "value")
  s_max <- if (all(is.na(sensitivity))) NA_real_ else
    max(sensitivity, na.rm = TRUE)
  if (is.na(s_max) || s_max <= 0)
    fail(paste0("the largest `sensitivity` value must be positive; is the ",
                "spectrum inverted or empty?"),
         "sensitivity", s_max, kind = "value")
  sensitivity <- sensitivity / s_max

  keep <- !is.na(sensitivity)

  # The amplitude is fitted too (closed-form least squares), so a spectrum
  # whose peak lies off the measured grid is not forced to a peak of 1.
  amplitude <- function(tmpl) {
    sum(tmpl * sensitivity[keep]) / sum(tmpl^2)
  }
  obj <- function(lmax) {
    tmpl <- .govardovskii_raw(lambda[keep], lmax, chromophore)
    sum((amplitude(tmpl) * tmpl - sensitivity[keep])^2)
  }

  res    <- optimize(obj, interval = lambda_max_range)
  fitted <- govardovskii_template(lambda, res$minimum, chromophore)

  list(
    lambda_max  = res$minimum,
    chromophore = chromophore,
    amplitude   = amplitude(fitted$S[keep]),
    SS          = res$objective,
    fitted      = fitted
  )
}


#' Spectral sensitivity for a named species and photoreceptor class.
#'
#' Looks up peak wavelength and chromophore from the bundled
#' \code{species_sensitivities} table, then applies the Govardovskii (2000)
#' template to return a normalised sensitivity curve.
#'
#' @param species  Species name (character). Must match a row in
#'   \code{species_sensitivities$species}. Case-sensitive.
#' @param receptor Photoreceptor class (e.g. \code{"L-cone"}, \code{"rod"}).
#'   If \code{NULL} (default), returns all receptor classes as a named list.
#' @param lambda   Wavelength grid in nm. Default \code{seq(300, 700, by = 1)}.
#' @return A data frame (single receptor) or named list of data frames (all
#'   receptors). Each data frame has columns \code{lambda} and \code{S}.
#' @examples
#' species_LEF("Homo sapiens", receptor = "L-cone")
#' species_LEF("Danio rerio")
#' @export
species_LEF <- function(species, receptor = NULL,
                         lambda = seq(300, 700, by = 1)) {
  rows <- species_sensitivities[species_sensitivities$species == species, ]
  if (nrow(rows) == 0)
    .luxr_abort(paste0("unknown species: '", species,
                       "'. See `species_sensitivities$species` for the list."), "value")

  build <- function(r)
    govardovskii_template(lambda, r$lambda_max, r$chromophore)

  if (is.null(receptor)) {
    out <- lapply(split(rows, rows$receptor), build)
    return(out)
  }

  r <- rows[rows$receptor == receptor, ]
  if (nrow(r) == 0)
    .luxr_abort(paste0("unknown receptor '", receptor, "' for species '", species, "'."), "value")
  build(r)
}


#' Sensitivity-weighted photon irradiance.
#'
#' Computes \eqn{Q_w = \sum E_p(\lambda) S(\lambda) \Delta\lambda}, where
#' \eqn{E_p} is spectral photon irradiance and \eqn{S} is a dimensionless
#' sensitivity or absorptance curve. The result is a photon irradiance weighted
#' by the supplied curve, not an absolute photon rate for one receptor.
#'
#' @details
#' All inputs are converted to raw photon counts before integration, so the
#' returned unit is photons m^-2 s^-1. With a normalised pigment template,
#' \eqn{Q_w} is a relative sensitivity-weighted photon irradiance. With a
#' calibrated absorptance curve, it is absorbed photon irradiance per unit
#' collection area at the plane where \code{irradiance} was measured.
#'
#' Calculating photons s^-1 receptor^-1 additionally requires receptor
#' collection area, the solid angle subtended by the source, ocular
#' transmission, and quantum efficiency. This function does not accept or
#' assume those quantities and therefore does not return an absolute receptor
#' rate. Sensitivity is assigned zero outside the wavelength range supplied in
#' \code{S}; endpoint values are not extrapolated.
#'
#' @param irradiance Non-negative spectral irradiance vector, one value per
#'   wavelength bin, in the exact unit declared by \code{input_unit}.
#' @param lambda     Wavelength bin centres in nm.
#' @param S          Spectral sensitivity: a data frame with columns
#'   \code{lambda} and \code{S} (normalised 0–1). Accepts output of
#'   \code{\link{species_LEF}} or \code{\link{govardovskii_template}} directly.
#' @param input_unit Exact unit of \code{irradiance}. One of
#'   \code{"W/m2/nm"}, \code{"photon/m2/s/nm"}, \code{"mol/m2/s/nm"},
#'   \code{"mmol/m2/s/nm"}, or \code{"umol/m2/s/nm"}. Molar inputs are
#'   converted using the Avogadro constant.
#' @param total      Logical; sum across wavelengths (default \code{TRUE}) or
#'   return per-bin contributions.
#' @param binwidth   Wavelength bin width in nm. Inferred from \code{lambda}
#'   spacing if \code{NULL} (default).
#' @return A scalar (when \code{total = TRUE}) or numeric vector of integrated
#'   per-bin contributions, in photons m^-2 s^-1.
#' @references
#'   Kelber A, Vorobyev M, Osorio D (2003) Animal colour vision —
#'   behavioural tests and physiological concepts. Biological Reviews
#'   78:81–118.
#' @seealso \code{\link{species_LEF}}, \code{\link{govardovskii_template}},
#'   \code{\link{species_brightness}}, \code{\link{colour_jnd}}
#' @examples
#' lam <- Naples$wv
#' S   <- species_LEF("Danio rerio", receptor = "L-cone", lambda = lam)
#' quantum_catch(Naples$depth_0m, lam, S,
#'               input_unit = "umol/m2/s/nm")
#' @export
quantum_catch <- function(irradiance, lambda, S,
                           input_unit = NULL, total = TRUE,
                           binwidth = NULL) {
  supported_units <- c(
    "W/m2/nm", "photon/m2/s/nm", "mol/m2/s/nm",
    "mmol/m2/s/nm", "umol/m2/s/nm"
  )
  if (!is.character(input_unit) || length(input_unit) != 1L ||
      is.na(input_unit) || !input_unit %in% supported_units) {
    .luxr_abort(
      paste0("'input_unit' must be exactly one of: ",
             paste(supported_units, collapse = ", "), "."),
      "unit",
      field = "input_unit", value = input_unit,
      supported_units = supported_units
    )
  }
  if (!is.logical(total) || length(total) != 1L || is.na(total)) {
    .luxr_abort(
      "'total' must be one non-missing logical value.",
      "type",
      field = "total", value = total
    )
  }

  binwidth <- .resolve_photometric_binwidth(irradiance, lambda, binwidth)
  .validate_quantum_sensitivity(S)
  Sg <- stats::approx(S$lambda, S$S, xout = lambda,
                      yleft = 0, yright = 0)$y

  photons <- switch(
    input_unit,
    "W/m2/nm" = W2photon(irradiance, lambda),
    "photon/m2/s/nm" = irradiance,
    irradiance * .UNITS$scale[.UNITS$unit == input_unit] * .AVOGADRO
  )

  Q <- photons * Sg * binwidth
  if (total) sum(Q) else Q
}

.validate_quantum_sensitivity <- function(S) {
  if (!is.data.frame(S)) {
    .luxr_abort(
      "'S' must be a data frame with numeric 'lambda' and 'S' columns.",
      "value",
      field = "S", value = S
    )
  }
  missing_columns <- setdiff(c("lambda", "S"), names(S))
  if (length(missing_columns) > 0L) {
    .luxr_abort(
      paste0("'S' is missing required column(s): ",
             paste(missing_columns, collapse = ", "), "."),
      "value",
      field = "S", value = names(S), missing_columns = missing_columns
    )
  }
  if (nrow(S) < 2L) {
    .luxr_abort(
      "'S' must contain at least two rows for interpolation.",
      "value",
      field = "S", value = S
    )
  }
  for (field in c("lambda", "S")) {
    values <- S[[field]]
    if (!is.numeric(values) || is.complex(values) || is.object(values) ||
        !is.null(dim(values)) || any(!is.finite(values))) {
      .luxr_abort(
        paste0("'S$", field, "' must be a finite numeric vector."),
        "value",
        field = paste0("S$", field), value = values
      )
    }
  }
  if (any(diff(S$lambda) <= 0)) {
    .luxr_abort(
      "'S$lambda' must be strictly increasing and unique.",
      "value",
      field = "S$lambda", value = S$lambda
    )
  }
  invalid_S <- which(S$S < 0 | S$S > 1)
  if (length(invalid_S) > 0L) {
    i <- invalid_S[1L]
    .luxr_abort(
      paste0("'S$S' must lie in [0, 1]; index ", i, " is ", S$S[i], "."),
      "value",
      field = "S$S", value = S$S[i], index = i
    )
  }
  invisible(S)
}


#' Per-species sensitivity-weighted photon irradiance.
#'
#' Convenience wrapper around \code{\link{quantum_catch}} and
#' \code{\link{species_LEF}} that returns quantum catches for all (or one)
#' receptor class of a named species.
#'
#' @param irradiance Non-negative spectral irradiance vector, one value per
#'   wavelength bin, in the exact unit declared by \code{input_unit}.
#' @param lambda     Wavelength bin centres in nm.
#' @param species    Species name. Must appear in \code{species_sensitivities}.
#' @param input_unit Exact unit of \code{irradiance}; see
#'   \code{\link{quantum_catch}}. No photon or molar unit is inferred from a
#'   bare numeric vector.
#' @param channel    One of:
#'   \itemize{
#'     \item \code{"by_receptor"} — named numeric vector, one value per
#'       receptor class;
#'     \item \code{"all"} — scalar sum across all receptor classes;
#'     \item a specific receptor name (e.g. \code{"L-cone"}) — single scalar.
#'   }
#' @param binwidth   Wavelength bin width in nm. Inferred from \code{lambda}
#'   spacing if \code{NULL} (default).
#' @return Named numeric vector, scalar, or single numeric depending on
#'   \code{channel}.
#' @seealso \code{\link{quantum_catch}}, \code{\link{species_LEF}},
#'   \code{\link{colour_jnd}}
#' @examples
#' idx <- Naples$wv >= 400 & Naples$wv <= 700
#' lam <- Naples$wv[idx]
#' irr <- Naples$depth_0m[idx]
#' species_brightness(irr, lam, "Homo sapiens",
#'                    input_unit = "umol/m2/s/nm",
#'                    channel = "by_receptor")
#' @export
species_brightness <- function(irradiance, lambda,
                                species, input_unit = NULL,
                                channel = "by_receptor",
                                binwidth = NULL) {
  if (channel == "by_receptor") {
    senses <- species_LEF(species, receptor = NULL, lambda = lambda)
    result <- sapply(senses, function(S)
      quantum_catch(irradiance, lambda, S,
                    input_unit = input_unit, binwidth = binwidth))
    return(result)
  }

  if (channel == "all") {
    senses <- species_LEF(species, receptor = NULL, lambda = lambda)
    catches <- sapply(senses, function(S)
      quantum_catch(irradiance, lambda, S,
                    input_unit = input_unit, binwidth = binwidth))
    return(sum(catches))
  }

  S <- species_LEF(species, receptor = channel, lambda = lambda)
  quantum_catch(irradiance, lambda, S, input_unit = input_unit,
                binwidth = binwidth)
}
