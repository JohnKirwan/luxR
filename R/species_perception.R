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
#' follows the four-parameter expression:
#' \deqn{S_\alpha(\lambda) = \left[
#'   e^{A(a - x)} + e^{B(0.922 - x)} + e^{C(1.104 - x)} + D
#' \right]^{-1}, \quad x = \frac{\lambda_{\max}}{\lambda}}
#' where \eqn{A}, \eqn{B}, \eqn{C}, \eqn{D}, and \eqn{a} are chromophore-specific
#' constants (A1: \eqn{A=69.7}, \eqn{B=28}, \eqn{C=-14.9}, \eqn{D=0.674},
#' \eqn{a} wavelength-dependent; A2: \eqn{A=62.7}, \eqn{B=26.5},
#' \eqn{C=-15.6}, \eqn{D=0.530}). The \eqn{\beta}-band is a Gaussian:
#' \deqn{S_\beta(\lambda) = 0.26\,\exp\!\left[
#'   -\!\left(\frac{\lambda - \lambda_\beta}{b}\right)^2
#' \right]}
#' with \eqn{\lambda_\beta = 189 + 0.315\,\lambda_{\max}} and
#' \eqn{b = -40.5 + 0.195\,\lambda_{\max}}. The full template is
#' \eqn{S(\lambda) = \max(0,\, S_\alpha + S_\beta)}, normalised to a peak of 1.
#'
#' @param lambda      Wavelength grid in nm (numeric vector).
#' @param lambda_max  Peak absorbance wavelength in nm.
#' @param chromophore Chromophore type: \code{"A1"} (11-cis retinal, default)
#'   or \code{"A2"} (11-cis 3,4-didehydroretinal). A2 shifts the peak toward
#'   longer wavelengths and broadens the spectrum.
#' @return A data frame with columns \code{lambda} and \code{S} (normalised
#'   absorbance, 0–1).
#' @references
#'   Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000)
#'   In search of the visual pigment template. Visual Neuroscience 17:509–528.
#' @examples
#' lam <- seq(300, 750, by = 1)
#' govardovskii_template(lam, lambda_max = 560)
#' @export
govardovskii_template <- function(lambda, lambda_max,
                                   chromophore = c("A1", "A2")) {
  if (!is.numeric(lambda) || is.complex(lambda) || is.object(lambda) ||
      !is.null(dim(lambda)) || length(lambda) == 0L ||
      any(!is.finite(lambda)) || any(lambda <= 0) ||
      any(diff(lambda) <= 0)) {
    .stop_species_model(
      "'lambda' must be a non-empty, finite, strictly increasing vector of positive wavelengths.",
      "lux_invalid_sensitivity_grid_error",
      field = "lambda", value = lambda
    )
  }
  if (!is.numeric(lambda_max) || is.complex(lambda_max) ||
      is.object(lambda_max) || !is.null(dim(lambda_max)) ||
      length(lambda_max) != 1L || !is.finite(lambda_max) ||
      lambda_max <= 0) {
    .stop_species_model(
      "'lambda_max' must be one finite, strictly positive number.",
      "lux_invalid_sensitivity_peak_error",
      field = "lambda_max", value = lambda_max
    )
  }
  chromophore <- match.arg(chromophore)

  if (chromophore == "A1") {
    a_coef <- 0.8795 + 0.0459 * exp(-(lambda_max - 300)^2 / 11940)
    coefs  <- list(A = 69.7, B = 28, C = -14.9, D = 0.674, a = a_coef)
  } else {
    a_coef <- 0.875 + 0.0268 * exp(-(lambda_max - 665)^2 / 25000)
    coefs  <- list(A = 62.7, B = 26.5, C = -15.6, D = 0.530, a = a_coef)
  }

  x     <- lambda_max / lambda
  alpha <- 1 / (exp(coefs$A * (coefs$a - x)) +
                exp(coefs$B * (0.922 - x))  +
                exp(coefs$C * (1.104 - x))  +
                coefs$D)

  lmb  <- 189 + 0.315 * lambda_max
  b    <- -40.5 + 0.195 * lambda_max
  beta <- 0.26 * exp(-((lambda - lmb) / b)^2)

  S <- pmax(0, alpha + beta)
  S <- S / max(S)
  data.frame(lambda = lambda, S = S)
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
#'   or a bare numeric vector of normalised absorbance values. Re-normalised to a
#'   peak of 1 internally, so the optical density refers to the peak.
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

  # ---- resolve the peak natural-log absorbance (kappa) --------------------
  has_od <- !is.null(optical_density)
  has_al <- !is.null(alpha) || !is.null(path_length)
  if (has_od == has_al)
    stop("Supply either `optical_density`, or both `alpha` and `path_length` ",
         "(exactly one parameterisation).")

  if (has_od) {
    if (!is.numeric(optical_density) || length(optical_density) != 1L ||
        optical_density <= 0)
      stop("`optical_density` must be a single positive number.")
    kappa <- optical_density * log(10)
  } else {
    if (is.null(alpha) || is.null(path_length))
      stop("Supply both `alpha` and `path_length`.")
    if (!is.numeric(alpha) || !is.numeric(path_length) ||
        length(alpha) != 1L || length(path_length) != 1L ||
        alpha <= 0 || path_length <= 0)
      stop("`alpha` and `path_length` must be single positive numbers.")
    kappa <- alpha * path_length
  }

  # ---- normalise the template to a peak of 1 ------------------------------
  is_df  <- is.data.frame(S)
  s_vals <- if (is_df) S$S else S
  if (is.null(s_vals) || !is.numeric(s_vals))
    stop("`S` must be a numeric vector or a data frame with an `S` column.")
  peak <- max(s_vals, na.rm = TRUE)
  if (!is.finite(peak) || peak <= 0)
    stop("`S` has no positive values to normalise.")

  A <- 1 - exp(-kappa * (s_vals / peak))
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
#'   for \eqn{\lambda_{\max}} in nm. Default \code{c(300, 700)}.
#' @return A list with components:
#'   \describe{
#'     \item{\code{lambda_max}}{Best-fit peak wavelength (nm).}
#'     \item{\code{chromophore}}{Chromophore used.}
#'     \item{\code{SS}}{Residual sum of squares at the optimum.}
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
                             lambda_max_range = c(300, 700)) {
  chromophore <- match.arg(chromophore)
  stopifnot(
    length(lambda) == length(sensitivity),
    length(lambda_max_range) == 2,
    lambda_max_range[1] < lambda_max_range[2]
  )

  s_max <- max(sensitivity, na.rm = TRUE)
  if (!is.finite(s_max) || s_max == 0)
    stop("`sensitivity` must contain at least one finite non-zero value.")
  sensitivity <- sensitivity / s_max

  keep <- !is.na(sensitivity)

  obj <- function(lmax) {
    tmpl <- govardovskii_template(lambda[keep], lmax, chromophore)
    sum((tmpl$S - sensitivity[keep])^2)
  }

  res    <- optimize(obj, interval = lambda_max_range)
  fitted <- govardovskii_template(lambda, res$minimum, chromophore)

  list(
    lambda_max  = res$minimum,
    chromophore = chromophore,
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
    stop("unknown species: '", species,
         "'. See `species_sensitivities$species` for the list.")

  build <- function(r)
    govardovskii_template(lambda, r$lambda_max, r$chromophore)

  if (is.null(receptor)) {
    out <- lapply(split(rows, rows$receptor), build)
    return(out)
  }

  r <- rows[rows$receptor == receptor, ]
  if (nrow(r) == 0)
    stop("unknown receptor '", receptor, "' for species '", species, "'.")
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
    .stop_species_model(
      paste0("'input_unit' must be exactly one of: ",
             paste(supported_units, collapse = ", "), "."),
      "lux_invalid_quantum_unit_error",
      field = "input_unit", value = input_unit,
      supported_units = supported_units
    )
  }
  if (!is.logical(total) || length(total) != 1L || is.na(total)) {
    .stop_species_model(
      "'total' must be one non-missing logical value.",
      "lux_invalid_quantum_input_error",
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
    "mol/m2/s/nm" = irradiance * 6.02214076e23,
    "mmol/m2/s/nm" = irradiance * 6.02214076e20,
    "umol/m2/s/nm" = irradiance * 6.02214076e17
  )

  Q <- photons * Sg * binwidth
  if (total) sum(Q) else Q
}

.validate_quantum_sensitivity <- function(S) {
  if (!is.data.frame(S)) {
    .stop_species_model(
      "'S' must be a data frame with numeric 'lambda' and 'S' columns.",
      "lux_invalid_quantum_sensitivity_error",
      field = "S", value = S
    )
  }
  missing_columns <- setdiff(c("lambda", "S"), names(S))
  if (length(missing_columns) > 0L) {
    .stop_species_model(
      paste0("'S' is missing required column(s): ",
             paste(missing_columns, collapse = ", "), "."),
      "lux_invalid_quantum_sensitivity_error",
      field = "S", value = names(S), missing_columns = missing_columns
    )
  }
  if (nrow(S) < 2L) {
    .stop_species_model(
      "'S' must contain at least two rows for interpolation.",
      "lux_invalid_quantum_sensitivity_error",
      field = "S", value = S
    )
  }
  for (field in c("lambda", "S")) {
    values <- S[[field]]
    if (!is.numeric(values) || is.complex(values) || is.object(values) ||
        !is.null(dim(values)) || any(!is.finite(values))) {
      .stop_species_model(
        paste0("'S$", field, "' must be a finite numeric vector."),
        "lux_invalid_quantum_sensitivity_error",
        field = paste0("S$", field), value = values
      )
    }
  }
  if (any(diff(S$lambda) <= 0)) {
    .stop_species_model(
      "'S$lambda' must be strictly increasing and unique.",
      "lux_invalid_quantum_sensitivity_error",
      field = "S$lambda", value = S$lambda
    )
  }
  invalid_S <- which(S$S < 0 | S$S > 1)
  if (length(invalid_S) > 0L) {
    i <- invalid_S[1L]
    .stop_species_model(
      paste0("'S$S' must lie in [0, 1]; index ", i, " is ", S$S[i], "."),
      "lux_invalid_quantum_sensitivity_error",
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
