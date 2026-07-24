library(luxR)

# Cross-validation: luxR's colour_jnd() against colourvision's RNLmodel().
# Both implement the Vorobyev-Osorio (log) receptor-noise-limited model. Mapping
# the conventions so they agree:
#   * sensitivities C   — species_sensitivity_matrix(weight = "photon") emits
#       S * lambda, so colourvision's energy integral reproduces luxR's photon
#       catch; the h*c constant cancels in the log difference.
#   * illuminant/reflectance — colour_jnd compares two full stimulus spectra, so
#       the stimuli enter colourvision as R1/R2 with a flat illuminant I = 1;
#       the product I*R is then each stimulus.
#   * von Kries — colourvision normalises catches to the background Rb, but the
#       same factor appears for both stimuli and cancels in log(Qr2)-log(Qr1),
#       so Rb is arbitrary (flat here).
#   * noise — colour_jnd uses e_i = Weber fraction per receptor; reproduced with
#       RNLmodel(noise = TRUE, e = rep(weber, nreceptors)).
# colourvision is a Suggests dependency, so the test skips when it is absent.

cv_dS <- function(s1, s2, lam, species, weber) {
  C  <- species_sensitivity_matrix(species, lambda = lam, weight = "photon")
  I  <- data.frame(wl = lam, I = rep(1, length(lam)))
  R1 <- data.frame(wl = lam, R = s1)
  R2 <- data.frame(wl = lam, R = s2)
  Rb <- data.frame(wl = lam, R = rep(1, length(lam)))
  m <- suppressWarnings(suppressMessages(
    colourvision::RNLmodel(
      model = "log", photo = ncol(C) - 1L,
      R1 = R1, R2 = R2, Rb = Rb, I = I, C = C,
      noise = TRUE, e = rep(weber, ncol(C) - 1L),
      interpolate = FALSE, nm = lam
    )
  ))
  m[["deltaS"]]
}

make_stimuli <- function(lam) {
  s1 <- stats::approx(solar_spectra$clear_noon$wavelength,
                      solar_spectra$clear_noon$irradiance, lam, rule = 2)$y
  s2 <- stats::approx(solar_spectra$underwater_10m$wavelength,
                      solar_spectra$underwater_10m$irradiance, lam, rule = 2)$y
  list(s1 = s1, s2 = s2)
}

test_that("colour_jnd matches colourvision RNLmodel across receptor counts", {
  skip_if_not_installed("colourvision")
  lam <- 300:700                       # colourvision's default nm grid
  st  <- make_stimuli(lam)
  w   <- 0.05
  for (sp in c("Homo sapiens", "Apis mellifera", "Danio rerio")) {
    dl <- colour_jnd(st$s1, st$s2, lambda = lam, species = sp, noise = w)
    dc <- cv_dS(st$s1, st$s2, lam, sp, w)
    expect_equal(dl, dc, tolerance = 1e-6, info = paste("species:", sp))
  }
})

test_that("colour_jnd matches colourvision under a different Weber fraction", {
  skip_if_not_installed("colourvision")
  lam <- 300:700
  st  <- make_stimuli(lam)
  w   <- 0.02
  dl <- colour_jnd(st$s1, st$s2, lambda = lam, species = "Homo sapiens", noise = w)
  dc <- cv_dS(st$s1, st$s2, lam, "Homo sapiens", w)
  expect_equal(dl, dc, tolerance = 1e-6)
})
