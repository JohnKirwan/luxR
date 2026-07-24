library(luxR)

# ---- attenuate_depth ----------------------------------------------------

test_that("attenuate_depth at z = 0 returns E0", {
  expect_equal(attenuate_depth(100, Kd = 0.1, depth = 0), 100)
})

test_that("attenuate_depth is vectorised over depth", {
  result <- attenuate_depth(100, Kd = 0.1, depth = c(0, 10, 20))
  expect_equal(result, c(100, 100 * exp(-1), 100 * exp(-2)))
})

test_that("attenuate_depth rejects negative depth", {
  expect_error(attenuate_depth(100, 0.1, -5))
})

test_that("attenuate_depth rejects negative Kd", {
  expect_error(
    attenuate_depth(100, -0.1, 5),
    "`Kd` must contain only non-negative values",
    class = "lux_spectrum_value_error"
  )
})

test_that("attenuate_depth rejects non-finite inputs", {
  expect_error(
    attenuate_depth(100, NA_real_, 5),
    "`Kd` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    attenuate_depth(100, 0.1, Inf),
    "`depth` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
})

# ---- photic_depth -------------------------------------------------------

test_that("photic_depth default 1% fraction gives correct result", {
  expect_equal(photic_depth(0.06), -log(0.01) / 0.06, tolerance = 1e-10)
})

test_that("photic_depth 50% fraction", {
  expect_equal(photic_depth(0.06, fraction = 0.5),
               -log(0.5) / 0.06, tolerance = 1e-10)
})

test_that("photic_depth is vectorised over Kd", {
  Kds <- c(0.06, 0.12)
  result <- photic_depth(Kds)
  expect_equal(result, -log(0.01) / Kds, tolerance = 1e-10)
})

test_that("photic_depth rejects fraction = 0", {
  expect_error(photic_depth(0.06, fraction = 0))
})

test_that("photic_depth rejects fraction = 1", {
  expect_error(photic_depth(0.06, fraction = 1))
})

# ---- fit_Kd -------------------------------------------------------------

test_that("fit_Kd recovers known Kd", {
  E0 <- 100; Kd_true <- 0.05; z1 <- 10; z2 <- 30
  E1 <- E0 * exp(-Kd_true * z1)
  E2 <- E0 * exp(-Kd_true * z2)
  expect_equal(fit_Kd(E1, z1, E2, z2), Kd_true, tolerance = 1e-10)
})

test_that("fit_Kd round-trips with attenuate_depth", {
  E0 <- 500; Kd <- 0.062; z2 <- 25
  E2 <- attenuate_depth(E0, Kd, z2)
  expect_equal(fit_Kd(E0, 0, E2, z2), Kd, tolerance = 1e-10)
})

test_that("fit_Kd works on spectral vectors", {
  E0_vec <- c(100, 80, 60)
  Kd_vec <- c(0.02, 0.06, 0.3)
  z2 <- 20
  E2_vec <- E0_vec * exp(-Kd_vec * z2)
  result <- fit_Kd(E0_vec, rep(0, 3), E2_vec, rep(z2, 3))
  expect_equal(result, Kd_vec, tolerance = 1e-10)
})

test_that("fit_Kd rejects z2 <= z1", {
  expect_error(fit_Kd(100, 20, 50, 10))
})

test_that("fit_Kd rejects non-positive irradiance", {
  expect_error(fit_Kd(0, 0, 50, 25))
  expect_error(fit_Kd(100, 0, 0, 25))
})

# ---- light_at_depth -----------------------------------------------------

test_that("light_at_depth fails on unsupported source wavelengths by default", {
  expect_error(
    light_at_depth("clear_noon", "IA", depth = 5),
    class = "luxR_jerlov_range_error"
  )
})

test_that("light_at_depth explicitly trims to the supported Jerlov domain", {
  surf <- convert_unit(from_solar("clear_noon"), "W/m2/nm")
  res  <- light_at_depth(
    "clear_noon", "IA", depth = 5, wavelength_policy = "trim"
  )
  expect_s3_class(res, "data.frame")
  expect_named(res, c("lambda", "irradiance"))
  expect_equal(res$lambda, surf$lambda[surf$lambda >= 350 & surf$lambda <= 700])
  metadata <- attr(res, "luxR.jerlov")
  expect_identical(metadata$wavelength_policy, "trim")
  expect_identical(metadata$calculated_wavelength_range_nm, c(350, 700))
  expect_gt(metadata$trimmed_wavelength_count, 0)
  propagation <- attr(res, "luxR.propagation", exact = TRUE)
  expect_identical(propagation$model,
                   "spectral Beer-Lambert diffuse attenuation")
  expect_identical(propagation$model_version, "beer-lambert-kd-v1")
  expect_identical(propagation$from_depth_m, 0)
  expect_identical(propagation$target_depth_m, 5)
  expect_identical(propagation$jerlov$type, "IA")
})

test_that("light_at_depth records explicit constant endpoint extension", {
  result <- light_at_depth(
    "clear_noon", "IA", depth = 5, wavelength_policy = "constant"
  )
  expect_identical(range(result$lambda), c(300, 800))
  metadata <- attr(result, "luxR.jerlov")
  expect_identical(metadata$wavelength_policy, "constant")
  expect_identical(metadata$extrapolation, "constant")
  expect_true(metadata$extrapolated)
})

test_that("light_at_depth applies the default surface model at depth 0", {
  surf <- convert_unit(from_solar("clear_noon"), "W/m2/nm")
  res  <- light_at_depth(
    "clear_noon", "IA", depth = 0, wavelength_policy = "trim"
  )
  tau <- surface_transmittance(angle = 30)
  keep <- surf$lambda >= 350 & surf$lambda <= 700
  expect_equal(res$irradiance, as.numeric(surf$E[keep]) * tau)
})

test_that("light_at_depth attenuates with depth", {
  surf <- light_at_depth(
    "clear_noon", "IA", depth = 0, wavelength_policy = "trim"
  )$irradiance
  deep <- light_at_depth(
    "clear_noon", "IA", depth = 20, wavelength_policy = "trim"
  )$irradiance
  expect_true(all(deep <= surf + 1e-12))
  expect_true(any(deep < surf))   # Kd > 0 somewhere -> strict loss
})

test_that("light_at_depth matches a manual propagate at depth", {
  sp_w <- convert_unit(from_solar("overcast"), "W/m2/nm")
  keep <- sp_w$lambda >= 350 & sp_w$lambda <= 700
  lambda <- sp_w$lambda[keep]
  Kd <- jerlov_Kd("II", lambda = lambda)
  E_sub <- sp_w$E[keep] * surface_transmittance(angle = 30)
  manual <- as.numeric(attenuate_spectrum(E_sub, Kd, depths = 12,
                                          lambda = lambda,
                                          format = "matrix")[, 1])
  expect_equal(
    light_at_depth(
      "overcast", "II", depth = 12, wavelength_policy = "trim"
    )$irradiance,
    manual
  )
})

test_that("light_at_depth supports explicit diffuse surface transmission", {
  sp_w <- convert_unit(from_solar("overcast"), "W/m2/nm")
  result <- light_at_depth(
    "overcast", "II", depth = 0, surface_source = "diffuse",
    wavelength_policy = "trim"
  )

  keep <- sp_w$lambda >= 350 & sp_w$lambda <= 700
  expect_equal(
    result$irradiance,
    as.numeric(sp_w$E[keep]) * surface_transmittance(source = "diffuse")
  )
})

test_that("surface transmission validates physical model inputs", {
  expect_error(
    light_at_depth("clear_noon", "IA", 0, surface_angle = NA_real_),
    "surface_angle.*finite",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    light_at_depth("clear_noon", "IA", 0, surface_angle = 91),
    "between 0 and 90",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    light_at_depth("clear_noon", "IA", 0, refractive_index = 1),
    "greater than 1",
    class = "lux_spectrum_value_error"
  )
})

test_that("light_at_depth preserves an underwater source at its reference depth", {
  for (condition in c("underwater_1m", "underwater_10m")) {
    source <- convert_unit(from_solar(condition), "W/m2/nm")
    result <- light_at_depth(
      condition,
      "IA",
      depth = source$meta$reference_depth_m,
      wavelength_policy = "trim"
    )

    keep <- source$lambda >= 350 & source$lambda <= 700
    expect_equal(result$lambda, source$lambda[keep])
    expect_equal(result$irradiance, source$E[keep])
  }
})

test_that("light_at_depth propagates only below the source reference depth", {
  source <- convert_unit(from_solar("underwater_10m"), "W/m2/nm")
  keep <- source$lambda >= 350 & source$lambda <= 700
  lambda <- source$lambda[keep]
  E <- source$E[keep]
  Kd <- jerlov_Kd("II", lambda = lambda)
  expected <- propagate_spectrum(
    E, Kd, from = 10, to = 20, format = "matrix"
  )

  result <- light_at_depth(
    "underwater_10m", "II", depth = 20, wavelength_policy = "trim"
  )
  expect_equal(result$irradiance, as.numeric(expected[, 1]))
})

test_that("light_at_depth rejects targets shallower than an underwater source", {
  err <- tryCatch(
    light_at_depth("underwater_10m", "II", depth = 5),
    error = identity
  )

  expect_s3_class(err, "lux_spectrum_depth_error")
  expect_match(conditionMessage(err), "underwater_10m")
  expect_match(conditionMessage(err), "referenced at 10 m")
  expect_identical(err$field, "target_depth_m")
  expect_identical(err$value, 5)
  expect_identical(err$context$water_type, "II")
  expect_identical(err$context$reference_depth_m, 10)
  expect_identical(err$context$target_depth_m, 5)
})

test_that("light_at_depth rejects non-scalar or negative depth", {
  expect_error(
    light_at_depth("clear_noon", "IA", depth = c(0, 5)),
    "one numeric value",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    light_at_depth("clear_noon", "IA", depth = -1),
    "non-negative",
    class = "lux_spectrum_value_error"
  )
})

# ---- propagate_depth ----------------------------------------------------

test_that("propagate_depth forward from 0 matches attenuate_depth", {
  E0 <- 100; Kd <- 0.062; z <- 30
  expect_equal(
    propagate_depth(E0, Kd, from = 0, to = z),
    attenuate_depth(E0, Kd, z)
  )
})

test_that("propagate_depth inverse round-trips", {
  E0 <- 100; Kd <- 0.062; z <- 22
  E_z <- attenuate_depth(E0, Kd, z)
  recovered <- propagate_depth(E_z, Kd, from = z, to = 0)
  expect_equal(recovered, E0, tolerance = 1e-8)
})

test_that("propagate_depth depth-to-depth is correct", {
  E0 <- 100; Kd <- 0.058; z1 <- 10; z2 <- 50
  E1 <- attenuate_depth(E0, Kd, z1)
  expect_equal(
    propagate_depth(E1, Kd, from = z1, to = z2),
    attenuate_depth(E0, Kd, z2),
    tolerance = 1e-10
  )
})

test_that("propagate_depth rejects negative to without flag", {
  expect_error(propagate_depth(100, 0.1, from = 0, to = -5))
})

test_that("propagate_depth allows negative to with allow_above_surface", {
  expect_no_error(
    propagate_depth(100, 0.1, from = 0, to = -5,
                    allow_above_surface = TRUE)
  )
})

test_that("propagate_depth validates attenuation and absolute depths", {
  expect_error(
    propagate_depth(100, -0.1, from = 0, to = 5),
    "`Kd` must contain only non-negative values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    propagate_depth(100, 0.1, from = NA_real_, to = 5),
    "`from` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    propagate_depth(100, 0.1, from = -1, to = 5),
    "non-negative absolute depths",
    class = "lux_spectrum_value_error"
  )
})

# ---- attenuate_spectrum -------------------------------------------------

test_that("attenuate_spectrum long format has correct structure", {
  E0  <- c(10, 20, 30)
  Kd  <- c(0.01, 0.05, 0.2)
  out <- attenuate_spectrum(E0, Kd, depths = c(0, 10))
  expect_s3_class(out, "data.frame")
  expect_named(out, c("depth", "lambda", "E"))
  expect_equal(nrow(out), 6)   # 3 wavelengths * 2 depths
})

test_that("attenuate_spectrum at depth 0 equals E0", {
  E0  <- c(10, 20, 30)
  Kd  <- c(0.01, 0.05, 0.2)
  out <- attenuate_spectrum(E0, Kd, depths = 0, format = "matrix")
  expect_equal(as.vector(out), E0)
})

test_that("attenuate_spectrum matrix format has correct dimensions", {
  out <- attenuate_spectrum(c(10, 20, 30), c(0.01, 0.05, 0.2),
                            depths = c(5, 10, 20), format = "matrix")
  expect_equal(dim(out), c(3L, 3L))
})

test_that("attenuate_spectrum lambda arg passes through to long format", {
  E0  <- c(10, 20, 30)
  Kd  <- c(0.01, 0.05, 0.2)
  lam <- c(450, 550, 650)
  out <- attenuate_spectrum(E0, Kd, depths = 10, lambda = lam)
  expect_equal(out$lambda, lam)
})

test_that("attenuate_spectrum requires equal-length E0 and Kd", {
  expect_error(attenuate_spectrum(c(1, 2), c(0.1, 0.2, 0.3), depths = 10))
})

test_that("attenuate_spectrum rejects invalid attenuation boundaries", {
  expect_error(
    attenuate_spectrum(c(1, 2), c(0.1, -0.2), depths = 10),
    "`Kd_lambda` must contain only non-negative values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    attenuate_spectrum(c(1, 2), c(0.1, NA_real_), depths = 10),
    "`Kd_lambda` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    attenuate_spectrum(c(1, 2), c(0.1, 0.2), depths = Inf),
    "`depths` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
})

test_that("attenuate_spectrum rejects non-irradiance lux_spectrum inputs", {
  lambda <- c(450, 550, 650)
  reflectance <- lux_spectrum(
    rep(0.5, 3), lambda, "reflectance", "dimensionless"
  )
  radiance <- lux_spectrum(
    rep(1, 3), lambda, "radiance", "W/m2/sr/nm"
  )

  for (input in list(reflectance, radiance)) {
    error <- expect_error(
      attenuate_spectrum(input, rep(0.1, 3), depths = 10),
      "must contain spectral irradiance",
      class = "lux_spectrum_quantity_error"
    )
    expect_identical(error$context$model,
                     "spectral Beer-Lambert diffuse attenuation")
    expect_identical(error$context$model_version, "beer-lambert-kd-v1")
  }
})

# ---- propagate_spectrum -------------------------------------------------

test_that("propagate_spectrum from=0 matches attenuate_spectrum", {
  E0  <- c(10, 20, 30)
  Kd  <- c(0.01, 0.05, 0.2)
  depths <- c(5, 10)
  r1 <- attenuate_spectrum(E0, Kd, depths, format = "matrix")
  r2 <- propagate_spectrum(E0, Kd, from = 0, to = depths, format = "matrix")
  expect_equal(r1, r2)
})

test_that("propagate_spectrum inverse round-trips", {
  E_10m <- c(8, 15, 20)
  Kd    <- c(0.02, 0.06, 0.25)
  E_0m  <- propagate_spectrum(E_10m, Kd, from = 10, to = 0,
                               format = "matrix")
  E_back <- propagate_spectrum(as.vector(E_0m), Kd, from = 0, to = 10,
                                format = "matrix")
  expect_equal(as.vector(E_back), E_10m, tolerance = 1e-8)
})

test_that("propagate_spectrum rejects invalid attenuation boundaries", {
  expect_error(
    propagate_spectrum(c(1, 2), c(0.1, -0.2), from = 0, to = 10),
    "`Kd_lambda` must contain only non-negative values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    propagate_spectrum(c(1, 2), c(0.1, Inf), from = 0, to = 10),
    "`Kd_lambda` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    propagate_spectrum(c(1, 2), c(0.1, 0.2), from = 0, to = NA_real_),
    "`to` must contain only finite values",
    class = "lux_spectrum_value_error"
  )
})

test_that("propagate_spectrum records its model and Jerlov provenance", {
  lambda <- c(450, 500, 550)
  input <- lux_spectrum(
    rep(1, 3), lambda, "irradiance", "W/m2/nm",
    meta = list(source = "test")
  )
  Kd <- jerlov_Kd("II", lambda)

  result <- propagate_spectrum(input, Kd, from = 0, to = c(5, 10))
  for (i in seq_along(result)) {
    context <- result[[i]]$meta$propagation
    expect_identical(context$model,
                     "spectral Beer-Lambert diffuse attenuation")
    expect_identical(context$model_version, "beer-lambert-kd-v1")
    expect_identical(context$from_depth_m, 0)
    expect_identical(context$target_depth_m, c(5, 10)[[i]])
    expect_identical(context$jerlov$type, "II")
    expect_identical(context$jerlov$supported_wavelength_range_nm, c(350, 700))
  }
})

test_that("propagate_spectrum rejects non-irradiance lux_spectrum inputs", {
  input <- lux_spectrum(
    rep(1, 3), c(450, 550, 650), "radiance", "W/m2/sr/nm"
  )
  expect_error(
    propagate_spectrum(input, rep(0.1, 3), from = 0, to = 10),
    "must contain spectral irradiance",
    class = "lux_spectrum_quantity_error"
  )
})

test_that("inverse propagation fails on non-finite numerical output", {
  error <- expect_error(
    propagate_spectrum(1, Kd_lambda = 1000, from = 1, to = 0,
                       format = "matrix"),
    "produced a non-finite result",
    class = "lux_spectrum_numerical_error"
  )
  expect_identical(error$context$from_depth_m, 1)
  expect_identical(error$context$target_depth_m, 0)
  expect_identical(error$context$model_version, "beer-lambert-kd-v1")
})
