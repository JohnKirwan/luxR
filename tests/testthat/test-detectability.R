library(luxR)

# ---- inherent_contrast --------------------------------------------------

test_that("inherent_contrast is zero for an object identical to its background", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  grey <- rep(0.3, length(lam))
  ic   <- inherent_contrast(grey, grey, sp$irradiance, lam,
                            species = "Danio rerio")
  expect_equal(ic$achromatic, 0, tolerance = 1e-10)
  expect_equal(ic$chromatic,  0, tolerance = 1e-8)
})

test_that("inherent_contrast: a black object has Weber contrast -1", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  black <- rep(0,   length(lam))
  grey  <- rep(0.3, length(lam))
  ic <- inherent_contrast(black, grey, sp$irradiance, lam,
                          channel = "achromatic")
  expect_equal(ic$achromatic, -1, tolerance = 1e-10)
})

test_that("inherent_contrast: a coloured object differs chromatically from grey", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  grey <- rep(0.3, length(lam))
  red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  ic <- inherent_contrast(red, grey, sp$irradiance, lam,
                          species = "Danio rerio", channel = "chromatic")
  expect_gt(ic$chromatic, 0)
})

test_that("species achromatic contrast requires a validated default channel", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  expect_error(
    inherent_contrast(
      rep(0.2, length(lam)), rep(0.3, length(lam)), sp$irradiance, lam,
      species = "Homo sapiens", channel = "achromatic"
    ),
    "No adaptation-specific photopic or scotopic default",
    class = "lux_channel_unavailable_error"
  )
})

test_that("achromatic brightness uses the configured receptor only", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  red <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  grey <- rep(0.3, length(lam))

  via_default <- inherent_contrast(
    red, grey, sp$irradiance, lam,
    species = "Danio rerio", channel = "achromatic"
  )
  via_explicit <- inherent_contrast(
    red, grey, sp$irradiance, lam,
    species = "Danio rerio", receptor = "L-cone", channel = "achromatic"
  )
  expect_equal(via_default$achromatic, via_explicit$achromatic)
})

test_that("inherent_contrast requires a species for the chromatic channel", {
  sp  <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  expect_error(
    inherent_contrast(rep(0.3, length(lam)), rep(0.5, length(lam)),
                      sp$irradiance, lam, channel = "chromatic"),
    "species")
})

# ---- contrast_at_distance -----------------------------------------------

test_that("contrast_at_distance: C0 at zero distance, exp decay with c = Kd*kd_to_c", {
  expect_equal(contrast_at_distance(0.8, 0, Kd = 0.1), 0.8)
  expect_equal(contrast_at_distance(1, c(0, 5, 10), Kd = 0.06, kd_to_c = 1.5),
               exp(-0.06 * 1.5 * c(0, 5, 10)))
})

test_that("contrast_at_distance: looking up decays slower than horizontal than down", {
  C_up   <- contrast_at_distance(1, 10, Kd = 0.06, kd_to_c = 2, direction = "up")
  C_horz <- contrast_at_distance(1, 10, Kd = 0.06, kd_to_c = 2, direction = "horizontal")
  C_down <- contrast_at_distance(1, 10, Kd = 0.06, kd_to_c = 2, direction = "down")
  expect_gt(C_up, C_horz)       # c - Kd < c  -> more contrast remains looking up
  expect_gt(C_horz, C_down)     # c + Kd > c  -> less contrast remains looking down
})

test_that("contrast_at_distance errors if looking up with kd_to_c <= 1", {
  expect_error(contrast_at_distance(1, 5, Kd = 0.06, kd_to_c = 1, direction = "up"))
})

# ---- detection_range ----------------------------------------------------

test_that("detection_range of a black object equals visual_range (C0 = -1)", {
  # A black silhouette has inherent Weber contrast -1, so the achromatic
  # detection range reduces exactly to visual_range (which assumes C0 = 1).
  sp    <- solar_irradiance("clear_noon")
  lam   <- sp$wavelength
  black <- rep(0,   length(lam))
  grey  <- rep(0.3, length(lam))
  Kd    <- jerlov_Kd("IA", lambda = 490)
  dr <- detection_range(black, grey, sp$irradiance, lam, Kd = Kd,
                        channel = "achromatic", contrast_threshold = 0.02)
  expect_equal(dr$achromatic,
               visual_range(Kd, contrast_threshold = 0.02, kd_to_c = 1.5),
               tolerance = 1e-8)
})

test_that("detection_range round-trips with contrast_at_distance at threshold", {
  sp    <- solar_irradiance("clear_noon")
  lam   <- sp$wavelength
  red   <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  grey  <- rep(0.3, length(lam))
  Kd    <- jerlov_Kd("IA", lambda = 490)
  Ct    <- 0.02

  ic <- inherent_contrast(red, grey, sp$irradiance, lam, channel = "achromatic")
  dr <- detection_range(red, grey, sp$irradiance, lam, Kd = Kd,
                        channel = "achromatic", contrast_threshold = Ct)
  # at the detection range the remaining contrast equals the threshold
  remaining <- contrast_at_distance(ic$achromatic, dr$achromatic, Kd = Kd)
  expect_equal(abs(remaining), Ct, tolerance = 1e-6)
})

test_that("detection_range: clearer water sees further; looking up beats horizontal", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  grey <- rep(0.3, length(lam))
  red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)

  clear  <- detection_range(red, grey, sp$irradiance, lam,
                            Kd = jerlov_Kd("I",  lambda = 490),
                            species = "Danio rerio")
  turbid <- detection_range(red, grey, sp$irradiance, lam,
                            Kd = jerlov_Kd("C2", lambda = 490),
                            species = "Danio rerio")
  expect_gt(clear$achromatic, turbid$achromatic)
  expect_gt(clear$chromatic,  turbid$chromatic)

  horz <- detection_range(red, grey, sp$irradiance, lam,
                          Kd = jerlov_Kd("IA", lambda = 490), kd_to_c = 2,
                          channel = "achromatic", direction = "horizontal")
  up   <- detection_range(red, grey, sp$irradiance, lam,
                          Kd = jerlov_Kd("IA", lambda = 490), kd_to_c = 2,
                          channel = "achromatic", direction = "up")
  expect_gt(up$achromatic, horz$achromatic)
})

test_that("detection_range is 0 when inherent contrast is below threshold", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  grey <- rep(0.3, length(lam))
  dr <- detection_range(grey, grey, sp$irradiance, lam,
                        Kd = jerlov_Kd("IA", lambda = 490),
                        channel = "achromatic")
  expect_equal(dr$achromatic, 0)
})

test_that("detection_range requires a scalar positive Kd", {
  sp  <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  expect_error(
    detection_range(rep(0, length(lam)), rep(0.3, length(lam)),
                    sp$irradiance, lam, Kd = c(0.05, 0.06),
                    channel = "achromatic"),
    "single positive")
})

test_that("detection calculations reject non-finite and non-physical inputs", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  black <- rep(0, length(lam))
  grey <- rep(0.3, length(lam))

  invalid_calls <- list(
    function() contrast_at_distance(1, -1, Kd = 0.1),
    function() contrast_at_distance(NA_real_, 1, Kd = 0.1),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = NA_real_, channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, beam_c = Inf,
                               channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, beam_c = 0,
                               channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = -0.1, channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, contrast_threshold = 0,
                               channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, contrast_threshold = 1,
                               channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, jnd_threshold = -1,
                               channel = "achromatic"),
    function() detection_range(black, grey, sp$irradiance, lam,
                               Kd = 0.1, max_distance = Inf,
                               channel = "achromatic")
  )
  for (call in invalid_calls) {
    expect_error(call(), class = "lux_detection_error")
  }
  err <- tryCatch(
    contrast_at_distance(1, -1, Kd = 0.1),
    error = identity
  )
  expect_s3_class(err, "lux_detection_error")
  expect_true(all(c("model_version", "code_commit", "random_seed",
                    "operation", "field", "value") %in% names(err)))
})

test_that("detection calculations enforce spectral schemas and regular grids", {
  lam <- c(400, 410, 425)
  object <- c(0.2, 0.3, 0.4)
  background <- rep(0.3, 3)
  illuminant <- rep(1, 3)
  expect_error(
    inherent_contrast(object, background, illuminant, lam,
                      channel = "achromatic", binwidth = 10),
    "regularly spaced", class = "lux_detection_error"
  )

  lam <- c(400, 410, 420)
  wrong_object <- lux_spectrum(
    object, lam, quantity = "irradiance", unit = "W/m2/nm"
  )
  expect_error(
    inherent_contrast(wrong_object, background, illuminant, lam,
                      channel = "achromatic"),
    "reflectance lux_spectrum", class = "lux_detection_error"
  )

  wrong_illuminant <- lux_spectrum(
    illuminant, lam, quantity = "radiance", unit = "W/m2/sr/nm"
  )
  expect_error(
    inherent_contrast(object, background, wrong_illuminant, lam,
                      channel = "achromatic"),
    "irradiance lux_spectrum", class = "lux_detection_error"
  )
})

test_that("detection_range reports below-origin and censored criteria", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  grey <- rep(0.3, length(lam))

  below <- detection_range(grey, grey, sp$irradiance, lam, Kd = 0.1,
                           channel = "achromatic")
  expect_equal(below$achromatic, 0)
  expect_identical(attr(below, "status")[["achromatic"]],
                   "below_at_origin")

  censored <- detection_range(rep(0, length(lam)), grey, sp$irradiance, lam,
                              Kd = 0.01, channel = "achromatic",
                              max_distance = 1)
  expect_true(is.na(censored$achromatic))
  expect_identical(attr(censored, "status")[["achromatic"]],
                   "not_crossed_within_limit")
})

test_that("spectral-path model requires wavelength-resolved optical inputs", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  black <- rep(0, length(lam))
  grey <- rep(0.3, length(lam))

  expect_error(
    detection_range(black, grey, sp$irradiance, lam, Kd = 0.06,
                    model = "spectral_path", channel = "achromatic",
                    veiling = grey * irradiance2radiance(sp$irradiance)),
    "beam_c.*required", class = "lux_detection_error"
  )
  expect_error(
    detection_range(black, grey, sp$irradiance, lam, Kd = 0.06,
                    beam_c = 0.2, model = "spectral_path",
                    channel = "achromatic",
                    veiling = grey * irradiance2radiance(sp$irradiance)),
    "same length", class = "lux_detection_error"
  )
  expect_error(
    detection_range(black, grey, sp$irradiance, lam, Kd = 0.06,
                    beam_c = rep(0.2, length(lam)),
                    model = "spectral_path", channel = "achromatic"),
    "veiling", class = "lux_detection_error"
  )
  expect_error(
    detection_range(
      black, grey, sp$irradiance, lam, Kd = 0.06,
      beam_c = rep(0.2, length(lam)), model = "spectral_path",
      channel = "achromatic",
      veiling = grey * irradiance2radiance(sp$irradiance),
      geometry = "custom"
    ),
    "solid_angle", class = "lux_detection_error"
  )
})

test_that("neutral spectral path reproduces the analytical achromatic case", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  black <- rep(0, length(lam))
  grey <- rep(0.3, length(lam))
  c_lambda <- rep(0.2, length(lam))

  spectral <- detection_range(
    black, grey, sp$irradiance, lam, Kd = 0.06, beam_c = c_lambda,
    channel = "achromatic", model = "spectral_path",
    veiling = grey * irradiance2radiance(sp$irradiance), max_distance = 50,
    search_points = 101
  )
  expected <- -log(0.02) / 0.2
  expect_equal(spectral$achromatic, expected, tolerance = 1e-5)
  expect_identical(attr(spectral, "model"), "spectral_path")
  expect_match(attr(spectral, "validation"), "not empirically validated")

  censored <- detection_range(
    black, grey, sp$irradiance, lam, Kd = 0.001,
    beam_c = rep(0.001, length(lam)), channel = "achromatic",
    model = "spectral_path",
    veiling = grey * irradiance2radiance(sp$irradiance),
    max_distance = 1, search_points = 11
  )
  expect_true(is.na(censored$achromatic))
  expect_identical(attr(censored, "status")[["achromatic"]],
                   "not_crossed_within_limit")
})

test_that("spectral chromatic catches are recomputed rather than scaling JND", {
  sp <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  grey <- rep(0.3, length(lam))
  red <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  c_lambda <- rep(0.2, length(lam))
  distance <- 3

  initial <- inherent_contrast(red, grey, sp$irradiance, lam,
                               species = "Danio rerio",
                               channel = "chromatic")$chromatic
  propagated <- luxR:::.spectral_signals(
    distance, red * sp$irradiance, grey * sp$irradiance,
    grey * sp$irradiance, lam, c_lambda, "Danio rerio", NULL, 0.05,
    "chromatic", diff(lam)[1]
  )$chromatic
  expect_false(isTRUE(all.equal(propagated, initial * exp(-0.2 * distance),
                                tolerance = 1e-6)))
  expect_gt(propagated, 0)
  expect_lt(propagated, initial)
})

# ---- detectability wrapper ----------------------------------------------

test_that("detectability bundles inherent contrast, range, and a curve", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  grey <- rep(0.3, length(lam))
  red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  Kd   <- jerlov_Kd("IA", lambda = 490)

  d <- detectability(red, grey, sp$irradiance, lam, Kd = Kd,
                     species = "Danio rerio")
  expect_s3_class(d, "lux_detection")
  expect_named(d$inherent, c("achromatic", "chromatic"))
  expect_named(d$range,    c("achromatic", "chromatic"))
  expect_true(all(c("distance", "achromatic", "chromatic") %in% names(d$curve)))

  # curve at distance 0 equals the inherent contrast; range matches the
  # standalone detection_range()
  expect_equal(d$curve$achromatic[1], d$inherent$achromatic, tolerance = 1e-10)
  dr <- detection_range(red, grey, sp$irradiance, lam, Kd = Kd,
                        species = "Danio rerio")
  expect_equal(d$range$achromatic, dr$achromatic, tolerance = 1e-10)
})

test_that("detectability print and plot methods work", {
  sp   <- solar_irradiance("clear_noon")
  lam  <- sp$wavelength
  d <- detectability(rep(0, length(lam)), rep(0.3, length(lam)),
                     sp$irradiance, lam, Kd = jerlov_Kd("IA", lambda = 490),
                     channel = "achromatic")
  expect_output(print(d), "lux_detection")
  pf <- tempfile(fileext = ".pdf"); pdf(pf); on.exit({ dev.off(); unlink(pf) })
  expect_silent(plot(d))
})

# ---- beam_c override (measured beam attenuation) ------------------------

test_that("beam_c overrides the Kd*kd_to_c proxy across the detection family", {
  sp     <- solar_irradiance("clear_noon")
  lam    <- sp$wavelength
  black  <- rep(0,   length(lam))
  grey   <- rep(0.3, length(lam))
  Kd     <- jerlov_Kd("IA", lambda = 490)
  c_meas <- 0.2                                   # e.g. beam_attenuation(a, b)

  # contrast_at_distance: horizontal uses beam_c; up still uses Kd (c - Kd)
  expect_equal(contrast_at_distance(1, 10, Kd = Kd, beam_c = c_meas),
               exp(-c_meas * 10))
  expect_equal(contrast_at_distance(1, 10, Kd = Kd, beam_c = c_meas,
                                    direction = "up"),
               as.numeric(exp(-(c_meas - Kd) * 10)))

  # detection_range of a black object -> ln(1/Ct)/c, equal to visual_range(beam_c)
  dr <- detection_range(black, grey, sp$irradiance, lam, Kd = Kd,
                        beam_c = c_meas, channel = "achromatic",
                        contrast_threshold = 0.02)
  expect_equal(dr$achromatic, -log(0.02) / c_meas, tolerance = 1e-8)
  expect_equal(dr$achromatic, visual_range(Kd, beam_c = c_meas), tolerance = 1e-8)

  # detectability threads beam_c through to the range
  d <- detectability(black, grey, sp$irradiance, lam, Kd = Kd,
                     beam_c = c_meas, channel = "achromatic")
  expect_equal(d$range$achromatic, -log(0.02) / c_meas, tolerance = 1e-8)
})
