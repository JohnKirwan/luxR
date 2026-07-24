# colour_jnd.R — Vorobyev-Osorio noise-limited colour discrimination

#' Chromatic distance between two illuminants (Vorobyev-Osorio model).
#'
#' Computes the just-noticeable difference (JND) between two spectral stimuli
#' as seen by a named species, using the receptor-noise-limited colour
#' discrimination model of Vorobyev & Osorio (1998). A \eqn{\Delta S < 1}
#' indicates the pair is not reliably discriminable; \eqn{\Delta S \geq 1}
#' indicates discrimination is possible.
#'
#' @details
#' For each receptor type \eqn{i}, the log-ratio of quantum catches
#' \eqn{\Delta f_i = \ln(Q_{2i} / Q_{1i})} is computed, then the chromatic
#' distance is:
#' \deqn{\Delta S^2 = \Delta\mathbf{f}^\top \Sigma^{-1} \Delta\mathbf{f}
#'        - \frac{(\mathbf{1}^\top \Sigma^{-1} \Delta\mathbf{f})^2}
#'                {\mathbf{1}^\top \Sigma^{-1} \mathbf{1}}}
#' where \eqn{\Sigma = \mathrm{diag}(e_i^2)} and \eqn{e_i} is the noise
#' (Weber fraction) of receptor \eqn{i}. The formula is general for any
#' number of receptor types \eqn{\geq 2}.
#'
#' @param stim1,stim2 Numeric vectors of spectral irradiance (W m\eqn{^{-2}}
#'   nm\eqn{^{-1}}) on the same \code{lambda} grid.
#' @param lambda   Wavelength vector in nm.
#' @param species  Species name matching \code{species_sensitivities$species}.
#' @param receptor Character vector of receptor class(es) to include (e.g.
#'   \code{c("L-cone","M-cone","S-cone")}). Default \code{NULL} uses the
#'   species' validated default chromatic channel from
#'   \code{\link{species_channels}}. Explicit receptors must belong to that
#'   channel.
#' @param noise    Weber fraction(s). Either a single value applied to all
#'   receptors, or a named numeric vector with one entry per receptor class.
#'   Default 0.05 (5\% noise), typical for cones in well-lit conditions.
#' @param binwidth Wavelength bin width in nm. Inferred from \code{lambda}
#'   spacing if \code{NULL} (default).
#' @return Scalar: chromatic distance \eqn{\Delta S} in just-noticeable
#'   differences (JNDs).
#' @references
#'   Vorobyev M, Osorio D (1998) Receptor noise as a determinant of colour
#'   thresholds. Proc. R. Soc. B 265:351–358.
#'
#'   Vorobyev M et al. (2001) Colour thresholds and receptor noise: behaviour
#'   and physiology compared. Vision Res. 41:639–653.
#' @seealso \code{\link{quantum_catch}}, \code{\link{species_brightness}},
#'   \code{\link{species_LEF}}
#' @examples
#' sp1 <- solar_irradiance("clear_noon")
#' sp2 <- solar_irradiance("underwater_10m")
#'
#' # Human trichromat
#' colour_jnd(sp1$irradiance, sp2$irradiance,
#'            lambda = sp1$wavelength, species = "Homo sapiens",
#'            receptor = c("L-cone", "M-cone", "S-cone"))
#'
#' # Zebrafish tetrachromat (all cones)
#' colour_jnd(sp1$irradiance, sp2$irradiance,
#'            lambda = sp1$wavelength, species = "Danio rerio")
#' @export
colour_jnd <- function(stim1, stim2, lambda, species,
                       receptor = NULL,
                       noise    = 0.05,
                       binwidth = NULL) {

  # ---- validate species and chromatic channel -----------------------------
  sp_data <- .default_channel_receptors(
    species = species,
    channel_role = "chromatic",
    receptor = receptor
  )
  channel <- attr(sp_data, "channel")

  if (nrow(sp_data) < 2)
    .stop_species_model(
      sprintf(
        paste(
          "At least 2 validated chromatic receptors are required for colour",
          "discrimination; %d found for species '%s'."
        ),
        nrow(sp_data),
        species
      ),
      "lux_channel_unavailable_error",
      species = species,
      channel_role = "chromatic",
      channel = channel,
      receptor = sp_data$receptor
    )

  # ---- binwidth -----------------------------------------------------------
  if (is.null(binwidth))
    binwidth <- if (length(lambda) > 1) mean(diff(lambda)) else 1

  # ---- quantum catches for each receptor ----------------------------------
  lam_s <- seq(300, 750, by = 1)

  q1 <- q2 <- numeric(nrow(sp_data))
  for (i in seq_len(nrow(sp_data))) {
    S  <- govardovskii_template(lam_s,
                                lambda_max  = sp_data$lambda_max[i],
                                chromophore = sp_data$chromophore[i])
    q1[i] <- quantum_catch(stim1, lambda, S,
                           input_unit = "W/m2/nm", total = TRUE,
                           binwidth = binwidth)
    q2[i] <- quantum_catch(stim2, lambda, S,
                           input_unit = "W/m2/nm", total = TRUE,
                           binwidth = binwidth)
  }
  names(q1) <- names(q2) <- sp_data$receptor

  invalid_q1 <- !is.finite(q1) | q1 <= 0
  invalid_q2 <- !is.finite(q2) | q2 <= 0
  if (any(invalid_q1) || any(invalid_q2)) {
    details <- c(
      if (any(invalid_q1)) {
        paste0("stim1:", paste(names(q1)[invalid_q1], collapse = ","))
      },
      if (any(invalid_q2)) {
        paste0("stim2:", paste(names(q2)[invalid_q2], collapse = ","))
      }
    )
    .stop_species_model(
      paste(
        "Chromatic modelling requires finite, strictly positive quantum catches;",
        paste(details, collapse = "; "),
        "were invalid."
      ),
      "lux_invalid_catch_error",
      species = species,
      channel_role = "chromatic",
      channel = channel,
      receptor = sp_data$receptor,
      q1 = q1,
      q2 = q2
    )
  }

  # ---- log-ratio differences ----------------------------------------------
  delta_f <- log(q2) - log(q1)

  # ---- noise vector -------------------------------------------------------
  recs <- sp_data$receptor
  if (!is.numeric(noise) || length(noise) == 0L ||
      anyNA(noise) || any(!is.finite(noise)) || any(noise <= 0)) {
    .stop_species_model(
      "`noise` must contain finite, strictly positive numeric values.",
      "lux_invalid_noise_error",
      species = species,
      channel_role = "chromatic",
      channel = channel,
      receptor = recs,
      noise = noise
    )
  }
  if (length(noise) == 1) {
    e <- setNames(rep(noise, length(recs)), recs)
  } else {
    # named vector — align to receptor order
    if (is.null(names(noise)) || anyNA(names(noise)) ||
        any(!nzchar(names(noise))) || anyDuplicated(names(noise))) {
      .stop_species_model(
        "Multi-receptor `noise` must have unique, non-empty receptor names.",
        "lux_invalid_noise_error",
        species = species,
        channel_role = "chromatic",
        channel = channel,
        receptor = recs,
        noise = noise
      )
    }
    missing_noise <- setdiff(recs, names(noise))
    extra_noise <- setdiff(names(noise), recs)
    if (length(missing_noise) > 0L || length(extra_noise) > 0L) {
      .stop_species_model(
        paste0(
          "`noise` names must exactly match the selected receptors. Missing: ",
          if (length(missing_noise)) paste(missing_noise, collapse = ", ") else "none",
          "; extra: ",
          if (length(extra_noise)) paste(extra_noise, collapse = ", ") else "none",
          "."
        ),
        "lux_invalid_noise_error",
        species = species,
        channel_role = "chromatic",
        channel = channel,
        receptor = recs,
        noise = noise,
        missing_receptors = missing_noise,
        extra_receptors = extra_noise
      )
    }
    e <- noise[recs]
  }

  # ---- Vorobyev-Osorio distance (general n-receptor formula) --------------
  # ΔS² = Δf' Σ⁻¹ Δf  -  (1' Σ⁻¹ Δf)² / (1' Σ⁻¹ 1)
  inv_e2  <- 1 / e^2
  term1   <- sum(delta_f^2 * inv_e2)
  term2   <- sum(delta_f   * inv_e2)^2 / sum(inv_e2)
  sqrt(max(term1 - term2, 0))
}
