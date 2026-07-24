library(luxR)

# ---- colour_jnd ------------------------------------------------------------

test_that("identical stimuli give ΔS = 0", {
  sp <- solar_irradiance("clear_noon")
  ds <- colour_jnd(sp$irradiance, sp$irradiance,
                   lambda  = sp$wavelength,
                   species = "Danio rerio",
                   binwidth = 10)
  expect_equal(ds, 0, tolerance = 1e-10)
})

test_that("colour_jnd returns non-negative scalar", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("underwater_10m")
  ds  <- colour_jnd(sp1$irradiance, sp2$irradiance,
                    lambda  = sp1$wavelength,
                    species = "Danio rerio",
                    binwidth = 10)
  expect_type(ds, "double")
  expect_length(ds, 1)
  expect_gte(ds, 0)
})

test_that("more spectrally different stimuli give larger ΔS", {
  sp0  <- solar_irradiance("clear_noon")
  sp10 <- solar_irradiance("underwater_10m")
  Kd   <- jerlov_Kd(
    "III", lambda = sp0$wavelength, extrapolation = "constant"
  )
  sp50 <- attenuate_spectrum(sp0$irradiance, Kd, depths = 50,
                             lambda = sp0$wavelength, format = "matrix")[, 1]

  ds_shallow <- colour_jnd(sp0$irradiance, sp10$irradiance,
                           lambda = sp0$wavelength, species = "Danio rerio",
                           binwidth = 10)
  ds_deep    <- colour_jnd(sp0$irradiance, sp50,
                           lambda = sp0$wavelength, species = "Danio rerio",
                           binwidth = 10)
  expect_gt(ds_deep, ds_shallow)
})

test_that("colour_jnd is symmetric (ΔS(a,b) == ΔS(b,a))", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("overcast")
  ds1 <- colour_jnd(sp1$irradiance, sp2$irradiance,
                    lambda = sp1$wavelength, species = "Homo sapiens",
                    binwidth = 10)
  ds2 <- colour_jnd(sp2$irradiance, sp1$irradiance,
                    lambda = sp1$wavelength, species = "Homo sapiens",
                    binwidth = 10)
  expect_equal(ds1, ds2, tolerance = 1e-10)
})

test_that("colour_jnd is invariant to overall intensity (it is chromatic)", {
  # The Vorobyev-Osorio distance measures CHROMATIC, not achromatic, difference:
  # scaling a stimulus by any positive factor changes every receptor's quantum
  # catch by the same log-amount, so all Δf_i shift equally and ΔS must be
  # exactly 0. This exercises the achromatic-projection term (term2) directly
  # and is independent of the internal sensitivity/quantum-catch machinery.
  sp <- solar_irradiance("clear_noon")
  ds <- colour_jnd(sp$irradiance, 3.7 * sp$irradiance,
                   lambda = sp$wavelength, species = "Homo sapiens",
                   receptor = c("L-cone", "M-cone", "S-cone"), binwidth = 10)
  # ~0 to floating-point tolerance; a real chromatic ΔS is order 1 or more.
  expect_equal(ds, 0, tolerance = 1e-5)
})

test_that("colour_jnd dichromat matches the analytic |Δf1-Δf2|/sqrt(e1^2+e2^2)", {
  # For exactly two receptors the general n-receptor formula must reduce to the
  # closed-form Vorobyev-Osorio dichromat result. Reproduce the two receptor
  # quantum catches independently and check the closed form against colour_jnd.
  sp1  <- solar_irradiance("clear_noon")
  sp2  <- solar_irradiance("underwater_10m")
  lam  <- sp1$wavelength
  recs <- c("L-cone", "M-cone")
  e    <- 0.05

  lam_s <- seq(300, 750, by = 1)
  qc <- function(stim, rec) {
    row <- subset(species_sensitivities,
                  species == "Homo sapiens" & receptor == rec)
    S <- govardovskii_template(lam_s, row$lambda_max[1], row$chromophore[1])
    quantum_catch(stim, lam, S, input_unit = "W/m2/nm",
                  total = TRUE, binwidth = 10)
  }
  df <- vapply(recs, function(r)
    log(qc(sp2$irradiance, r)) - log(qc(sp1$irradiance, r)), numeric(1))
  expected <- abs(df[[1]] - df[[2]]) / sqrt(e^2 + e^2)

  got <- colour_jnd(sp1$irradiance, sp2$irradiance, lambda = lam,
                    species = "Homo sapiens", receptor = recs,
                    noise = e, binwidth = 10)
  expect_equal(got, expected, tolerance = 1e-8)
})

test_that("colour_jnd noise can be named per receptor", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("overcast")
  recs <- c("L-cone", "M-cone", "S-cone")
  noise_vec <- c("L-cone" = 0.05, "M-cone" = 0.07, "S-cone" = 0.10)
  ds <- colour_jnd(sp1$irradiance, sp2$irradiance,
                   lambda = sp1$wavelength, species = "Homo sapiens",
                   receptor = recs, noise = noise_vec, binwidth = 10)
  expect_gte(ds, 0)
  expect_length(ds, 1)
})

test_that("colour_jnd errors on unknown species", {
  sp <- solar_irradiance("clear_noon")
  expect_error(
    colour_jnd(sp$irradiance, sp$irradiance,
               lambda = sp$wavelength, species = "Fake species"),
    "species"
  )
})

test_that("colour_jnd errors with fewer than 2 receptors", {
  sp <- solar_irradiance("clear_noon")
  expect_error(
    colour_jnd(sp$irradiance, sp$irradiance,
               lambda = sp$wavelength, species = "Homo sapiens",
               receptor = "rod"),
    "Unsupported chromatic receptor",
    class = "lux_invalid_receptor_error"
  )
})

test_that("colour_jnd works for tetrachromat (zebrafish, 4 cones)", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("underwater_10m")
  ds  <- colour_jnd(sp1$irradiance, sp2$irradiance,
                    lambda = sp1$wavelength, species = "Danio rerio",
                    binwidth = 10)
  expect_gte(ds, 0)
  expect_true(is.finite(ds))
})

test_that("human default colour channel excludes rod and ipRGC", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("overcast")
  default <- colour_jnd(
    sp1$irradiance,
    sp2$irradiance,
    lambda = sp1$wavelength,
    species = "Homo sapiens",
    binwidth = 10
  )
  cones_only <- colour_jnd(
    sp1$irradiance,
    sp2$irradiance,
    lambda = sp1$wavelength,
    species = "Homo sapiens",
    receptor = c("S-cone", "M-cone", "L-cone"),
    binwidth = 10
  )
  expect_equal(default, cones_only, tolerance = 1e-12)
})

test_that("colour_jnd rejects mixed valid and non-chromatic receptors", {
  sp <- solar_irradiance("clear_noon")
  expect_error(
    colour_jnd(
      sp$irradiance,
      sp$irradiance,
      lambda = sp$wavelength,
      species = "Homo sapiens",
      receptor = c("S-cone", "M-cone", "rod"),
      binwidth = 10
    ),
    "rod",
    class = "lux_invalid_receptor_error"
  )
  expect_error(
    colour_jnd(
      sp$irradiance,
      sp$irradiance,
      lambda = sp$wavelength,
      species = "Homo sapiens",
      receptor = c("S-cone", "M-cone", "not-a-receptor"),
      binwidth = 10
    ),
    "not-a-receptor",
    class = "lux_invalid_receptor_error"
  )
})

test_that("colour_jnd requires finite strictly positive receptor noise", {
  sp <- solar_irradiance("clear_noon")
  invalid_noise <- list(0, -0.1, NA_real_, NaN, Inf)
  for (value in invalid_noise) {
    expect_error(
      colour_jnd(
        sp$irradiance,
        sp$irradiance,
        lambda = sp$wavelength,
        species = "Homo sapiens",
        noise = value,
        binwidth = 10
      ),
      "finite, strictly positive",
      class = "lux_invalid_noise_error",
      info = paste("noise:", value)
    )
  }
})

test_that("multi-receptor noise must exactly name selected receptors", {
  sp <- solar_irradiance("clear_noon")
  call_jnd <- function(noise) {
    colour_jnd(
      sp$irradiance,
      sp$irradiance,
      lambda = sp$wavelength,
      species = "Homo sapiens",
      noise = noise,
      binwidth = 10
    )
  }
  expect_error(
    call_jnd(c(0.05, 0.05, 0.05)),
    "must have unique",
    class = "lux_invalid_noise_error"
  )
  expect_error(
    call_jnd(c("S-cone" = 0.05, "M-cone" = 0.05)),
    "Missing: L-cone",
    class = "lux_invalid_noise_error"
  )
  expect_error(
    call_jnd(c(
      "S-cone" = 0.05,
      "M-cone" = 0.05,
      "L-cone" = 0.05,
      "rod" = 0.05
    )),
    "extra: rod",
    class = "lux_invalid_noise_error"
  )
})

test_that("colour_jnd rejects zero catches instead of substituting epsilon", {
  sp <- solar_irradiance("clear_noon")
  dark <- numeric(length(sp$irradiance))
  expect_error(
    colour_jnd(
      dark,
      sp$irradiance,
      lambda = sp$wavelength,
      species = "Homo sapiens",
      binwidth = 10
    ),
    "strictly positive quantum catches",
    class = "lux_invalid_catch_error"
  )
})

test_that("colour_jnd rejects species without a validated chromatic channel", {
  sp <- solar_irradiance("clear_noon")
  expect_error(
    colour_jnd(
      sp$irradiance,
      sp$irradiance,
      lambda = sp$wavelength,
      species = "Callorhinchus milii",
      binwidth = 10
    ),
    "no unique default chromatic channel",
    class = "lux_channel_unavailable_error"
  )
})
