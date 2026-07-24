library(luxR)

# Cross-validation: luxR's colour_jnd() against pavo's vismodel() + coldist().
#
# Both implement the Vorobyev-Osorio receptor-noise-limited model, so given the
# same receptor sensitivities, stimuli, and noise they must return the same
# chromatic distance dS. Matching the conventions:
#   * sensitivities  — feed pavo luxR's own Govardovskii templates;
#   * photon weighting — luxR integrates photon catch (proportional to E * lambda);
#       reproduced in pavo with an illuminant proportional to wavelength;
#   * noise          — luxR uses e_i = Weber fraction per receptor; reproduced in
#       pavo with equal cone ratios n = 1 so that e_i = weber;
#   * raw catches    — vismodel(qcatch = "Qi", vonkries = FALSE, relative = FALSE).
# pavo is a Suggests dependency, so these tests skip when it is absent.

pavo_dS <- function(s1, s2, lam, species, weber) {
  members <- species_channels[
    species_channels$species == species &
      species_channels$channel_role == "chromatic" &
      species_channels$is_default,
    ,
    drop = FALSE
  ]
  species_rows <- species_sensitivities[
    species_sensitivities$species == species,
    ,
    drop = FALSE
  ]
  recs <- species_rows[match(members$receptor, species_rows$receptor), , drop = FALSE]
  S <- sapply(seq_len(nrow(recs)), function(i)
    govardovskii_template(lam, recs$lambda_max[i], recs$chromophore[i])$S)
  colnames(S) <- make.unique(recs$receptor)
  vm <- pavo::vismodel(
    pavo::as.rspec(data.frame(wl = lam, s1 = s1, s2 = s2), lim = range(lam)),
    visual    = pavo::as.rspec(data.frame(wl = lam, S), lim = range(lam)),
    illum     = lam,                # illuminant proportional to wavelength
    qcatch    = "Qi", vonkries = FALSE, relative = FALSE, achromatic = "none")
  pavo::coldist(vm, noise = "neural", n = rep(1, nrow(recs)),
                weber = weber, weber.ref = 1, achromatic = FALSE)$dS[1]
}

make_stimuli <- function(lam) {
  s1 <- stats::approx(solar_spectra$clear_noon$wavelength,
                      solar_spectra$clear_noon$irradiance, lam, rule = 2)$y
  s2 <- stats::approx(solar_spectra$underwater_10m$wavelength,
                      solar_spectra$underwater_10m$irradiance, lam, rule = 2)$y
  list(s1 = s1, s2 = s2)
}

test_that("colour_jnd matches pavo coldist across receptor counts", {
  skip_if_not_installed("pavo")
  lam <- 300:750
  st  <- make_stimuli(lam)
  w   <- 0.05
  for (sp in c("Homo sapiens", "Apis mellifera", "Danio rerio")) {
    dl <- colour_jnd(st$s1, st$s2, lambda = lam, species = sp, noise = w)
    dp <- suppressMessages(pavo_dS(st$s1, st$s2, lam, sp, w))
    expect_equal(dl, dp, tolerance = 1e-4,
                 info = paste("species:", sp))
  }
})

test_that("colour_jnd matches pavo under a different Weber fraction", {
  skip_if_not_installed("pavo")
  lam <- 300:750
  st  <- make_stimuli(lam)
  w   <- 0.02
  dl <- colour_jnd(st$s1, st$s2, lambda = lam, species = "Homo sapiens", noise = w)
  dp <- suppressMessages(pavo_dS(st$s1, st$s2, lam, "Homo sapiens", w))
  expect_equal(dl, dp, tolerance = 1e-4)
})

test_that("spectral-path chromatic signal benchmarks against pavo", {
  skip_if_not_installed("pavo")
  # Reproducibility record: deterministic benchmark (no random seed), luxR
  # model version 0.1.0, pavo >= 2.9.0, and the bundled input checksum below.
  dataset_path <- "data/solar_spectra.rda"
    expected_dataset_md5 <- "4f6d0f01294028dcad7e13fdf3484227"
  workspace <- Sys.getenv("GITHUB_WORKSPACE", unset = "")
  dataset_candidates <- c(
    if (nzchar(workspace)) file.path(workspace, dataset_path),
    testthat::test_path("..", "..", dataset_path)
  )
  dataset_file <- dataset_candidates[file.exists(dataset_candidates)][1L]
  if (!is.na(dataset_file)) {
    expect_identical(
      unname(tools::md5sum(dataset_file)),
      expected_dataset_md5
    )
  }
  benchmark_config <- list(
    dataset = dataset_path,
    dataset_md5 = expected_dataset_md5,
    package_model_version = "0.1.0",
    species = "Danio rerio",
    receptor_noise = 0.05,
    distance_m = 7,
    random_seed = NA_integer_
  )
  lam <- 300:750
  illuminant <- stats::approx(
    solar_spectra$clear_noon$wavelength,
    solar_spectra$clear_noon$irradiance,
    lam,
    rule = 2
  )$y
  background <- rep(0.3, length(lam))
  object <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
  veiling <- background * illuminant
  beam_c <- 0.12 + 0.08 * (lam - min(lam)) / diff(range(lam))
  distance <- benchmark_config$distance_m
  transmission <- exp(-beam_c * distance)
  object_seen <- veiling + (object * illuminant - veiling) * transmission
  background_seen <- veiling +
    (background * illuminant - veiling) * transmission

  luxr_ds <- luxR:::.spectral_signals(
    distance = distance,
    object_radiance = object * illuminant,
    background_radiance = background * illuminant,
    veiling_radiance = veiling,
    lambda = lam,
    effective_c = beam_c,
    species = benchmark_config$species,
    receptor = NULL,
    noise = benchmark_config$receptor_noise,
    channel = "chromatic",
    binwidth = 1
  )$chromatic
  pavo_ds <- suppressMessages(
    pavo_dS(
      object_seen, background_seen, lam, benchmark_config$species,
      benchmark_config$receptor_noise
    )
  )
  expect_equal(luxr_ds, pavo_ds, tolerance = 1e-4)
})

# Cross-validation: luxR's quantum_catch() against pavo's vismodel(qcatch="Qi").
# Both integrate photon catch per receptor, proportional to sum(E * lambda * S).
# They differ by an overall constant (luxR's 1/(h c) and pavo's internal
# sensitivity normalization), so absolute scale is not comparable; each
# per-receptor vector is normalized to sum 1 and the relative distribution is
# compared. This isolates the spectral integration and photon weighting.

pavo_qcatch <- function(E, lam, S) {
  vm <- pavo::vismodel(
    pavo::as.rspec(data.frame(wl = lam, r = E), lim = range(lam)),
    visual   = pavo::as.rspec(data.frame(wl = lam, S), lim = range(lam)),
    illum    = lam,                 # illuminant proportional to wavelength
    qcatch   = "Qi", vonkries = FALSE, relative = FALSE, achromatic = "none")
  as.numeric(vm[1, setdiff(names(vm), "lum")])
}

luxr_qcatch <- function(E, lam, S) {
  vapply(seq_len(ncol(S)), function(i)
    quantum_catch(E, lam, data.frame(lambda = lam, S = S[, i]),
                  input_unit = "W/m2/nm", total = TRUE),
    numeric(1))
}

receptor_sensitivities <- function(lam, species) {
  members <- species_channels[
    species_channels$species == species &
      species_channels$channel_role == "chromatic" &
      species_channels$is_default, , drop = FALSE]
  rows <- species_sensitivities[
    species_sensitivities$species == species, , drop = FALSE]
  recs <- rows[match(members$receptor, rows$receptor), , drop = FALSE]
  S <- sapply(seq_len(nrow(recs)), function(i)
    govardovskii_template(lam, recs$lambda_max[i], recs$chromophore[i])$S)
  colnames(S) <- make.unique(recs$receptor)
  S
}

test_that("quantum_catch relative distribution matches pavo Qi", {
  skip_if_not_installed("pavo")
  lam <- 300:750
  E   <- stats::approx(solar_spectra$clear_noon$wavelength,
                       solar_spectra$clear_noon$irradiance, lam, rule = 2)$y
  for (sp in c("Homo sapiens", "Apis mellifera", "Danio rerio")) {
    S  <- receptor_sensitivities(lam, sp)
    lx <- luxr_qcatch(E, lam, S); lx <- lx / sum(lx)
    pv <- suppressMessages(pavo_qcatch(E, lam, S)); pv <- pv / sum(pv)
    expect_equal(lx, pv, tolerance = 1e-8, info = paste("species:", sp))
  }
})
