library(luxR)

test_that("species data schemas and controlled roles are valid", {
  expect_named(
    species_sensitivities,
    c("species", "receptor", "lambda_max", "chromophore", "channel_role", "source")
  )
  expect_named(
    species_channels,
    c(
      "species", "channel", "channel_role", "receptor", "weight",
      "is_default", "source"
    )
  )
  expect_named(
    species_channel_support,
    c("species", "channel_role", "status", "reason", "source")
  )
  expect_true(all(species_sensitivities$channel_role %in% c(
    "chromatic", "achromatic", "irradiance", "polarization", "fluorescence"
  )))
  expect_true(all(species_channels$channel_role %in% c(
    "chromatic", "achromatic", "irradiance", "polarization", "fluorescence"
  )))
  expect_true(all(is.finite(species_channels$weight)))
  expect_true(all(species_channels$weight > 0))
  expect_true(all(species_channels$is_default))
  expect_true(luxR:::.validate_species_model_data())
})

test_that("support decisions cover every species and both model roles", {
  expected <- as.vector(outer(
    unique(species_sensitivities$species),
    c("chromatic", "achromatic"),
    paste,
    sep = "\r"
  ))
  actual <- paste(
    species_channel_support$species,
    species_channel_support$channel_role,
    sep = "\r"
  )
  expect_setequal(actual, expected)

  defaults <- unique(species_channels[
    species_channels$is_default,
    c("species", "channel_role")
  ])
  default_key <- paste(defaults$species, defaults$channel_role, sep = "\r")
  supported_key <- actual[species_channel_support$status == "supported"]
  expect_setequal(supported_key, default_key)
})

test_that("every configured channel member has a receptor record", {
  sensitivity_key <- paste(
    species_sensitivities$species,
    species_sensitivities$receptor,
    sep = "\r"
  )
  membership_key <- paste(
    species_channels$species,
    species_channels$receptor,
    sep = "\r"
  )
  expect_setequal(membership_key, intersect(membership_key, sensitivity_key))
  expect_identical(anyDuplicated(paste(
    species_channels$species,
    species_channels$channel,
    species_channels$channel_role,
    species_channels$receptor,
    sep = "\r"
  )), 0L)
})

test_that("unsupported GFP and unidentified mantis-shrimp records are absent", {
  expect_false(any(species_sensitivities$species == "Aequorea victoria"))
  expect_false(any(species_sensitivities$species == "Mantis shrimp"))
  expect_false(any(species_sensitivities$receptor == "GFP"))
})

test_that("human receptor roles and default chromatic channel are explicit", {
  human <- subset(species_sensitivities, species == "Homo sapiens")
  expect_setequal(
    human$receptor[human$channel_role == "chromatic"],
    c("S-cone", "M-cone", "L-cone")
  )
  expect_equal(human$channel_role[human$receptor == "rod"], "achromatic")
  expect_equal(human$channel_role[human$receptor == "ipRGC"], "irradiance")

  selected <- luxR:::.default_channel_receptors(
    "Homo sapiens",
    "chromatic"
  )
  expect_equal(selected$receptor, c("S-cone", "M-cone", "L-cone"))
  expect_equal(attr(selected, "channel"), "cone_opponent")
  expect_equal(attr(selected, "channel_weights"), c(1, 1, 1))

  expect_error(
    luxR:::.default_channel_receptors("Homo sapiens", "achromatic"),
    "No adaptation-specific photopic or scotopic default",
    class = "lux_channel_unavailable_error"
  )
})

test_that("behaviourally supported achromatic defaults are explicit", {
  expected <- list(
    "Danio rerio" = c(channel = "l_cone_motion", receptor = "L-cone"),
    "Apis mellifera" = c(channel = "green_contrast", receptor = "green"),
    "Drosophila melanogaster" = c(channel = "r1_6_motion", receptor = "R1-6")
  )

  for (species in names(expected)) {
    selected <- luxR:::.default_channel_receptors(species, "achromatic")
    expect_equal(selected$receptor, unname(expected[[species]]["receptor"]))
    expect_equal(attr(selected, "channel"), unname(expected[[species]]["channel"]))
    expect_equal(attr(selected, "channel_weights"), 1)
  }
})

test_that("incomplete species do not acquire an implicit colour channel", {
  expect_error(
    luxR:::.default_channel_receptors("Callorhinchus milii", "chromatic"),
    "no unique default chromatic channel",
    class = "lux_channel_unavailable_error"
  )
})

test_that("species data validation rejects dangling channel memberships", {
  invalid_channels <- species_channels
  invalid_channels$receptor[1] <- "not-a-receptor"
  expect_error(
    luxR:::.validate_species_model_data(channels = invalid_channels),
    "unknown species/receptor pair",
    class = "lux_species_data_error"
  )
})

test_that("species data validation rejects empty datasets", {
  expect_error(
    luxR:::.validate_species_model_data(
      sensitivities = species_sensitivities[0, , drop = FALSE]
    ),
    "non-empty data frame",
    class = "lux_species_data_error"
  )
  expect_error(
    luxR:::.validate_species_model_data(
      channels = species_channels[0, , drop = FALSE]
    ),
    "non-empty data frame",
    class = "lux_species_data_error"
  )
  expect_error(
    luxR:::.validate_species_model_data(
      support = species_channel_support[0, , drop = FALSE]
    ),
    "non-empty data frame",
    class = "lux_species_data_error"
  )
})

test_that("support declarations cannot disagree with configured defaults", {
  invalid_support <- species_channel_support
  invalid_support$status[
    invalid_support$species == "Homo sapiens" &
      invalid_support$channel_role == "achromatic"
  ] <- "supported"
  expect_error(
    luxR:::.validate_species_model_data(support = invalid_support),
    "exactly match configured default channels",
    class = "lux_species_data_error"
  )
})
