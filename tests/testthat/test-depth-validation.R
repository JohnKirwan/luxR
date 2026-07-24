# Analytical validation: luxR's depth-propagation functions against the
# closed-form Beer-Lambert law E(z) = E0 * exp(-Kd * z), computed inline here
# rather than through any luxR helper. This distinguishes the physics from the
# internal manual-sum comparisons in test-depth-propagation.R. No dependency.

library(luxR)

test_that("attenuate_depth matches Beer-Lambert closed form", {
  E0    <- 500
  Kd    <- 0.12
  depth <- c(0, 1, 5, 10, 25)
  analytic <- E0 * exp(-Kd * depth)
  expect_equal(attenuate_depth(E0, Kd, depth), analytic, tolerance = 1e-12)
})

test_that("attenuate_spectrum matches per-wavelength Beer-Lambert", {
  lam <- c(450, 500, 550, 600)
  E0  <- c(1.0, 2.0, 1.5, 0.8)
  Kd  <- c(0.10, 0.08, 0.06, 0.20)
  z   <- 8
  out <- attenuate_spectrum(E0, Kd, depths = z, lambda = lam, format = "long")
  out <- out[order(out$lambda), ]
  analytic <- E0 * exp(-Kd * z)
  expect_equal(out$E, analytic, tolerance = 1e-12)
})

test_that("propagate_spectrum depth-to-depth matches closed form", {
  lam  <- c(450, 500, 550)
  E0   <- c(1.0, 2.0, 3.0)
  Kd   <- c(0.10, 0.08, 0.06)
  from <- 3
  to   <- 11
  out  <- propagate_spectrum(E0, Kd, from = from, to = to,
                             lambda = lam, format = "long")
  out  <- out[order(out$lambda), ]
  # E supplied at `from`; propagate the extra (to - from) metres.
  analytic <- E0 * exp(-Kd * (to - from))
  expect_equal(out$E, analytic, tolerance = 1e-12)
})
