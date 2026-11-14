library(luxR)

# ---- govardovskii_template ----------------------------------------------

test_that("govardovskii_template returns data frame with lambda and S", {
  lam <- seq(300, 700, by = 10)
  out <- govardovskii_template(lam, lambda_max = 560)
  expect_s3_class(out, "data.frame")
  expect_named(out, c("lambda", "S"))
  expect_equal(nrow(out), length(lam))
})

test_that("govardovskii_template peak is near lambda_max", {
  lam <- seq(300, 700, by = 1)
  for (lmax in c(420, 480, 530, 560)) {
    out    <- govardovskii_template(lam, lambda_max = lmax)
    obs_pk <- out$lambda[which.max(out$S)]
    expect_lte(abs(obs_pk - lmax), 15)
  }
})

test_that("govardovskii_template S is non-negative", {
  lam <- seq(300, 750, by = 5)
  out <- govardovskii_template(lam, 500, chromophore = "A1")
  expect_true(all(out$S >= 0))
  out2 <- govardovskii_template(lam, 500, chromophore = "A2")
  expect_true(all(out2$S >= 0))
})

test_that("govardovskii_template never exceeds one", {
  lam <- seq(300, 750, by = 1)
  for (chromophore in c("A1", "A2")) {
    out <- govardovskii_template(lam, 500, chromophore = chromophore)
    expect_true(all(out$S <= 1))
  }
})

test_that("govardovskii_template rejects invalid wavelength inputs", {
  expect_error(
    govardovskii_template(c(500, 490), 500),
    "strictly increasing",
    class = "luxR_grid_error"
  )
  expect_error(
    govardovskii_template(c(490, 500), Inf),
    "lambda_max",
    class = "luxR_value_error"
  )
})

test_that("govardovskii_template A2 has broader long-wavelength tail than A1", {
  # A2 chromophore (3,4-didehydroretinal) broadens the sensitivity curve.
  # For the same lambda_max, A2 retains more sensitivity beyond lambda_max + 100 nm.
  lam   <- seq(300, 750, by = 1)
  a1    <- govardovskii_template(lam, 500, "A1")
  a2    <- govardovskii_template(lam, 500, "A2")
  red   <- lam > 620
  expect_gt(sum(a2$S[red]), sum(a1$S[red]))
})

# ---- receptor_absorptance -----------------------------------------------

test_that("receptor_absorptance matches Johnsen's hatchetfish rod example", {
  # The Optics of Life ch.4: blue-green absorption coefficient a = 0.064 /um.
  # At the peak (normalised S = 1), absorptance = 1 - exp(-a * length):
  #   10 um -> 47%, 40 um -> 92%, 75 um -> >99%.
  lam  <- seq(400, 700, by = 1)
  tmpl <- govardovskii_template(lam, lambda_max = 490)
  pk   <- which.max(tmpl$S)
  expect_equal(receptor_absorptance(tmpl, alpha = 0.064, path_length = 10)$S[pk],
               0.47, tolerance = 0.01)
  expect_equal(receptor_absorptance(tmpl, alpha = 0.064, path_length = 40)$S[pk],
               0.92, tolerance = 0.01)
  expect_equal(receptor_absorptance(tmpl, alpha = 0.064, path_length = 75)$S[pk],
               0.99, tolerance = 0.01)
})

test_that("receptor_absorptance: optical density is base-10 (OD=1 -> 90% at peak)", {
  lam  <- seq(400, 700, by = 1)
  tmpl <- govardovskii_template(lam, 500)
  A    <- receptor_absorptance(tmpl, optical_density = 1)
  expect_equal(max(A$S), 0.9, tolerance = 1e-6)        # 1 - 10^-1
})

test_that("receptor_absorptance: weak density preserves the template shape", {
  lam  <- seq(400, 700, by = 1)
  tmpl <- govardovskii_template(lam, 500)
  A    <- receptor_absorptance(tmpl, optical_density = 0.02)
  An <- A$S / max(A$S); Sn <- tmpl$S / max(tmpl$S)
  expect_lt(max(abs(An - Sn)), 0.01)                   # self-screening negligible
})

test_that("receptor_absorptance: high density broadens the curve (self-screening)", {
  lam  <- seq(300, 750, by = 1)
  tmpl <- govardovskii_template(lam, 500)
  width <- function(A) sum(A$S / max(A$S) >= 0.5)      # points above half-max
  expect_gt(width(receptor_absorptance(tmpl, optical_density = 2)),
            width(receptor_absorptance(tmpl, optical_density = 0.05)))
})

test_that("receptor_absorptance output drops straight into quantum_catch", {
  lam  <- seq(400, 700, by = 10)
  E    <- rep(1, length(lam))
  tmpl <- govardovskii_template(seq(300, 750, by = 1), 550)
  A    <- receptor_absorptance(tmpl, optical_density = 0.4)
  q    <- quantum_catch(E, lam, A, input_unit = "photon/m2/s/nm")
  expect_true(is.numeric(q) && length(q) == 1 && q > 0)
})

test_that("receptor_absorptance accepts a bare numeric vector", {
  s <- c(0.1, 0.5, 1.0, 0.5, 0.1)
  A <- receptor_absorptance(s, optical_density = 0.5)
  expect_length(A, length(s))
  expect_true(all(A >= 0 & A <= 1))
})

test_that("receptor_absorptance requires exactly one parameterisation", {
  s <- c(0.5, 1, 0.5)
  expect_error(receptor_absorptance(s))                                   # neither
  expect_error(receptor_absorptance(s, optical_density = 0.4,
                                    alpha = 0.06, path_length = 10))       # both
})

# ---- species_LEF --------------------------------------------------------

test_that("species_LEF returns data frame for known species", {
  out <- species_LEF("Homo sapiens", receptor = "L-cone")
  expect_s3_class(out, "data.frame")
  expect_named(out, c("lambda", "S"))
})

test_that("species_LEF returns list when receptor is NULL", {
  out <- species_LEF("Danio rerio")
  expect_type(out, "list")
  expect_true(length(out) >= 2)
})

test_that("species_LEF throws informative error for unknown species", {
  expect_error(species_LEF("Homo fictus"), "unknown species")
})

test_that("species_LEF throws error for unknown receptor", {
  expect_error(species_LEF("Homo sapiens", receptor = "X-cone"),
               "unknown receptor")
})

# ---- quantum_catch ------------------------------------------------------

test_that("quantum_catch returns positive scalar", {
  irr <- Naples$depth_0m
  lam <- Naples$wv
  S   <- species_LEF("Homo sapiens", receptor = "L-cone",
                      lambda = lam)
  result <- quantum_catch(irr, lam, S, input_unit = "umol/m2/s/nm")
  expect_true(is.numeric(result) && length(result) == 1 && result > 0)
})

test_that("quantum_catch total = FALSE returns vector", {
  irr <- c(1, 2, 1)
  lam <- c(500, 550, 600)
  S   <- data.frame(lambda = lam, S = c(0.5, 1.0, 0.5))
  result <- quantum_catch(irr, lam, S, input_unit = "W/m2/nm",
                          total = FALSE)
  expect_length(result, 3)
})

test_that("quantum_catch with flat S proportional to irradiance sum", {
  irr <- c(1, 2, 4)
  lam <- c(500, 550, 600)
  S   <- data.frame(lambda = lam, S = c(1, 1, 1))
  q   <- quantum_catch(irr, lam, S, input_unit = "photon/m2/s/nm")
  # binwidth inferred from lam spacing = 50 nm
  expected <- sum(irr) * mean(diff(lam))
  expect_equal(q, expected, tolerance = 1e-6)
})

test_that("quantum_catch converts energy, photon, and molar units consistently", {
  lam <- c(500, 510)
  S <- data.frame(lambda = lam, S = c(1, 1))
  photons <- c(6.02214076e17, 6.02214076e17)
  umol <- c(1, 1)
  energy <- photon2W(photons, lam)

  q_photon <- quantum_catch(
    photons, lam, S, input_unit = "photon/m2/s/nm", binwidth = 10
  )
  q_umol <- quantum_catch(
    umol, lam, S, input_unit = "umol/m2/s/nm", binwidth = 10
  )
  q_energy <- quantum_catch(
    energy, lam, S, input_unit = "W/m2/nm", binwidth = 10
  )

  expect_equal(q_umol, q_photon, tolerance = 1e-12)
  expect_equal(q_energy, q_photon, tolerance = 1e-12)
  expect_equal(
    quantum_catch(umol, lam, S, input_unit = "mol/m2/s/nm", binwidth = 10) /
      q_umol,
    1e6
  )
})

test_that("quantum_catch assigns zero sensitivity outside the supplied range", {
  lam <- c(400, 500, 600)
  S <- data.frame(lambda = c(450, 550), S = c(1, 1))
  contributions <- quantum_catch(
    rep(1, 3), lam, S, input_unit = "photon/m2/s/nm",
    total = FALSE, binwidth = 100
  )
  expect_equal(contributions, c(0, 100, 0))
})

test_that("quantum_catch rejects ambiguous units and malformed sensitivity", {
  lam <- c(500, 510)
  S <- data.frame(lambda = lam, S = c(0.5, 1))

  expect_error(
    quantum_catch(c(1, 1), lam, S),
    "input_unit",
    class = "luxR_unit_error"
  )
  expect_error(
    quantum_catch(c(1, 1), lam, S, input_unit = "photons"),
    "input_unit",
    class = "luxR_unit_error"
  )
  expect_error(
    quantum_catch(
      c(1, 1), lam, transform(S, S = c(0.5, 1.1)),
      input_unit = "photon/m2/s/nm"
    ),
    "\\[0, 1\\]",
    class = "luxR_value_error"
  )
  expect_error(
    quantum_catch(
      c(1, 1), lam, S[2:1, ],
      input_unit = "photon/m2/s/nm"
    ),
    "strictly increasing",
    class = "luxR_value_error"
  )
})

test_that("quantum_catch: energy vs photon weighting red-shifts the catch", {
  # Johnsen (The Optics of Life, ch.2): a spectrum's energy peak is not its
  # photon peak. A spectrum flat in ENERGY carries more photons at longer
  # wavelengths (per-photon energy ~ 1/lambda), so the W->photon conversion
  # Energy input boosts a long-wave receptor relative to treating the same
  # numbers as photon counts. This guards the unit
  # discipline the book repeatedly warns about.
  lam   <- seq(400, 700, by = 10)
  Eflat <- rep(1, length(lam))                  # flat in energy units W/m2/nm
  S_L   <- species_LEF("Homo sapiens", "L-cone", lambda = lam)
  S_S   <- species_LEF("Homo sapiens", "S-cone", lambda = lam)

  ratio_energy <- quantum_catch(Eflat, lam, S_L,
                                input_unit = "W/m2/nm") /
                  quantum_catch(Eflat, lam, S_S,
                                input_unit = "W/m2/nm")
  ratio_photon <- quantum_catch(Eflat, lam, S_L,
                                input_unit = "photon/m2/s/nm") /
                  quantum_catch(Eflat, lam, S_S,
                                input_unit = "photon/m2/s/nm")

  # converting energy -> photons favours the long-wave cone
  expect_gt(ratio_energy, ratio_photon)
})

test_that("quantum_catch is larger for L-cone than S-cone under red-shifted spectrum", {
  lam <- seq(400, 700, by = 10)
  irr <- ifelse(lam >= 580, 1, 0)   # only red wavelengths lit
  S_L <- species_LEF("Homo sapiens", receptor = "L-cone", lambda = lam)
  S_S <- species_LEF("Homo sapiens", receptor = "S-cone", lambda = lam)
  expect_gt(quantum_catch(irr, lam, S_L,
                          input_unit = "photon/m2/s/nm"),
            quantum_catch(irr, lam, S_S,
                          input_unit = "photon/m2/s/nm"))
})

# ---- species_brightness -------------------------------------------------

test_that("species_brightness returns named numeric for by_receptor", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  result <- species_brightness(irr, lam, species = "Homo sapiens",
                                input_unit = "photon/m2/s/nm",
                                channel = "by_receptor")
  expect_type(result, "double")
  expect_true(!is.null(names(result)))
  expect_true(all(result > 0))
})

test_that("species_brightness returns scalar for channel = 'all'", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  result <- species_brightness(
    irr, lam, "Homo sapiens", input_unit = "photon/m2/s/nm", channel = "all"
  )
  expect_length(result, 1)
  expect_true(result > 0)
})

test_that("species_brightness named-receptor channel returns single value", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  result <- species_brightness(
    irr, lam, "Homo sapiens",
    input_unit = "photon/m2/s/nm", channel = "L-cone"
  )
  expect_length(result, 1)
})

test_that("species_brightness zebrafish has more receptors than human L-cone alone", {
  lam <- seq(400, 700, by = 10)
  irr <- rep(1, length(lam))
  zf <- species_brightness(
    irr, lam, "Danio rerio",
    input_unit = "photon/m2/s/nm", channel = "by_receptor"
  )
  expect_gte(length(zf), 3)
})

# ---- template normalisation is independent of the wavelength grid ---------

test_that("govardovskii_template does not depend on the wavelength grid", {
  wide   <- govardovskii_template(seq(300, 750, by = 1), 360)
  narrow <- govardovskii_template(seq(400, 700, by = 1), 360)
  expect_equal(narrow$S, wide$S[wide$lambda >= 400 & wide$lambda <= 700],
               tolerance = 1e-12)
  expect_lt(max(narrow$S), 0.5)
})

test_that("govardovskii_template stays small when the peak is far off the grid", {
  out <- govardovskii_template(seq(600, 700, by = 1), 360)
  expect_true(all(out$S >= 0 & out$S < 0.01))
})

# Long-wave half-maximum wavelength of a template (lambda > lambda_max).
half_max_long <- function(lmax, chromophore) {
  f <- function(l) govardovskii_template(l, lmax, chromophore)$S - 0.5
  uniroot(f, c(lmax + 1, lmax + 200), tol = 1e-8)$root
}

test_that("A1 template reproduces Govardovskii et al. (2000) eqn 3", {
  # Eqn 3 is the paper's independent regression of lambda_max on the
  # long-wave half-maximum, so it checks the template's constants.
  for (lmax in c(400, 500, 560)) {
    l05 <- half_max_long(lmax, "A1")
    expect_equal(45.02 + 0.756 * l05 + 0.000141 * l05^2, lmax, tolerance = 0.5 / lmax)
  }
})

test_that("A2 template reproduces Govardovskii et al. (2000) eqn 7", {
  for (lmax in c(460, 523, 620)) {
    l05 <- half_max_long(lmax, "A2")
    expect_equal(30.6 + 0.7907 * l05 + 0.000102 * l05^2, lmax, tolerance = 0.5 / lmax)
  }
})

test_that("A2 beta band agrees with the cones fitted in Govardovskii et al. (2000) Fig. 10", {
  # Individually fitted beta bands of A. stellatus cones, which scatter around
  # the eqn 8 regressions: red (563.7 nm) and blue (459.4 nm).
  fig10 <- list(list(lmax = 563.7, A = 0.37, l = 378, w = 69),
                list(lmax = 459.4, A = 0.38, l = 339, w = 52.4))
  for (f in fig10) {
    p <- luxR:::.govardovskii_coefs(f$lmax, "A2")
    expect_equal(p$A_beta, f$A, tolerance = 0.02 / f$A)
    expect_lt(abs(p$l_beta - f$l), 10)
    expect_lt(abs(p$w_beta - f$w), 7)
  }
})

test_that("A2 template is broader than A1 at the same long-wave peak", {
  fwhm <- function(ch) {
    lam <- seq(450, 800, by = 0.05)
    S   <- govardovskii_template(lam, 620, ch)$S
    diff(range(lam[S >= 0.5]))
  }
  expect_gt(fwhm("A2"), fwhm("A1") + 15)
})

test_that("A2 template is limited to the fitted 440-620 nm range", {
  lam <- seq(400, 700, by = 1)
  for (lmax in c(439, 621)) {
    expect_error(govardovskii_template(lam, lmax, "A2"),
                 "440 and 620", class = "luxR_value_error")
  }
  expect_no_error(govardovskii_template(lam, 344, "A1"))
  expect_error(fit_sensitivity(lam, govardovskii_template(lam, 500, "A2")$S,
                               chromophore = "A2",
                               lambda_max_range = c(400, 600)),
               class = "luxR_value_error")
  fit <- fit_sensitivity(lam, govardovskii_template(lam, 523, "A2")$S,
                         chromophore = "A2")
  expect_equal(fit$lambda_max, 523, tolerance = 0.1 / 523)
})

test_that("govardovskii_template never exceeds one on a fine grid", {
  peaks <- list(A1 = c(300, 360, 500, 620, 700), A2 = c(440, 500, 620))
  for (ch in names(peaks)) for (lmax in peaks[[ch]]) {
    S <- govardovskii_template(seq(250, 750, by = 0.01), lmax, ch)$S
    expect_lte(max(S), 1)
    expect_equal(max(S), 1, tolerance = 1e-6)
  }
})

test_that("govardovskii_template rejects lambda_max outside 300-700 nm", {
  lam <- seq(300, 750, by = 1)
  expect_error(govardovskii_template(lam, 260),
               class = "luxR_value_error")
  expect_error(govardovskii_template(lam, 701),
               class = "luxR_value_error")
})

test_that("fit_sensitivity recovers a peak that lies off the measured grid", {
  lam  <- seq(400, 700, by = 5)
  true <- govardovskii_template(lam, 380)$S
  fit  <- fit_sensitivity(lam, true)
  expect_equal(fit$lambda_max, 380, tolerance = 0.5 / 380)
  expect_lt(fit$SS, 1e-8)
  expect_equal(fit$amplitude * fit$fitted$S, true / max(true), tolerance = 1e-4)
})

test_that("fit_sensitivity amplitude is the inverse of the template's on-grid maximum", {
  lam  <- seq(400, 700, by = 5)
  true <- govardovskii_template(lam, 380)$S
  expect_equal(fit_sensitivity(lam, true)$amplitude, 1 / max(true),
               tolerance = 1e-3)
  on_grid <- govardovskii_template(lam, 530)$S
  expect_equal(fit_sensitivity(lam, on_grid)$amplitude, 1 / max(on_grid),
               tolerance = 1e-3)
})

test_that("fit_sensitivity raises typed errors before fitting", {
  lam <- seq(400, 700, by = 5)
  S   <- govardovskii_template(lam, 530)$S
  expect_error(fit_sensitivity(lam, S, lambda_max_range = c(250, 700)),
               class = "luxR_value_error")
  bad <- lam
  bad[3] <- NA
  expect_error(expect_no_warning(fit_sensitivity(bad, S)),
               class = "luxR_grid_error")
})

test_that("receptor_absorptance does not rescale an off-peak template", {
  tmpl <- govardovskii_template(seq(300, 700, by = 10), 503)
  expect_equal(receptor_absorptance(tmpl, optical_density = 1)$S,
               1 - exp(-log(10) * tmpl$S))
})

test_that("receptor_absorptance rejects unnormalised or invalid S", {
  tmpl <- govardovskii_template(300:700, 500)
  expect_error(receptor_absorptance(transform(tmpl, S = S * 2),
                                    optical_density = 0.5),
               "peak-normalised", class = "luxR_value_error")
  expect_error(receptor_absorptance(c(0.5, -0.1), optical_density = 0.5),
               class = "luxR_value_error")
  expect_error(receptor_absorptance(c(0.5, NA), optical_density = 0.5),
               class = "luxR_value_error")
  expect_error(receptor_absorptance(c(0.5, 1), optical_density = -1),
               class = "luxR_value_error")
  expect_error(receptor_absorptance(c(0.5, 1)), class = "luxR_value_error")
})

test_that("fit_sensitivity rejects inverted spectra and bad arguments", {
  tmpl <- govardovskii_template(300:700, 500)
  expect_error(fit_sensitivity(tmpl$lambda, -tmpl$S),
               "largest `sensitivity`", class = "luxR_value_error")
  expect_error(fit_sensitivity(1:3, 1:2), class = "luxR_dimension_error")
  expect_error(fit_sensitivity(tmpl$lambda, tmpl$S,
                               lambda_max_range = c(600, 400)),
               class = "luxR_value_error")
})

test_that("fit_sensitivity drops NA as unmeasured wavelengths (documented policy)", {
  tmpl <- govardovskii_template(300:700, 520)
  s <- tmpl$S
  s[c(10, 200, 350)] <- NA
  fit <- fit_sensitivity(tmpl$lambda, s)
  expect_equal(fit$lambda_max, 520, tolerance = 1e-3)
  expect_error(fit_sensitivity(tmpl$lambda, rep(NA_real_, nrow(tmpl))),
               class = "luxR_value_error")
})
