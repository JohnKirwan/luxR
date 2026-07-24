# Cross-validation: luxR's par_irradiance() against photobiology's q_irrad().
#
# par_irradiance() always returns PHOTON PAR in umol/m2/s (the `photonic`
# argument describes the input unit, not the output). The independent
# reference is photobiology::q_irrad() over a 400-700 nm waveband, which
# returns photon irradiance in mol/m2/s. Both rest on the same per-photon
# energy relation n(lambda) = E * lambda / (h c), so they must agree up to the
# quadrature convention: luxR sums E * binwidth (rectangle rule) while
# photobiology integrates trapezoidally, differing by the endpoint-bin weight
# (~0.2 percent on a 1 nm grid). This benchmark validates the per-photon
# conversion and band weighting, not the choice of quadrature rule.
# photobiology is a Suggests dependency, so these tests skip when it is absent.

library(luxR)

test_that("par_irradiance matches photobiology q_irrad on a reference spectrum", {
  skip_if_not_installed("photobiology")
  sp  <- solar_irradiance("clear_noon")
  lam <- seq(400, 700, by = 1)
  E   <- stats::approx(sp$wavelength, sp$irradiance, lam, rule = 2)$y

  luxr_umol <- par_irradiance(E, lam, photonic = FALSE)      # umol/m2/s

  spct   <- photobiology::source_spct(w.length = lam, s.e.irrad = E)
  wb     <- photobiology::waveband(c(400, 700), wb.name = "PAR")
  pb_mol <- as.numeric(photobiology::q_irrad(spct, wb))       # mol/m2/s

  # tolerance = 1e-2 relative: rectangle vs trapezoidal endpoint convention.
  expect_equal(luxr_umol, pb_mol * 1e6, tolerance = 1e-2)
})

test_that("par_irradiance and photobiology agree on a flat spectrum", {
  skip_if_not_installed("photobiology")
  lam <- seq(400, 700, by = 1)
  E   <- rep(1, length(lam))                                  # 1 W/m2/nm flat

  luxr_umol <- par_irradiance(E, lam, photonic = FALSE)
  spct   <- photobiology::source_spct(w.length = lam, s.e.irrad = E)
  pb_mol <- as.numeric(
    photobiology::q_irrad(spct, photobiology::waveband(c(400, 700)))
  )
  expect_equal(luxr_umol, pb_mol * 1e6, tolerance = 1e-2)
})
