# Rebuild the bundled species receptor and channel datasets from reviewable CSV
# sources. Run from the package root with:
#
#   Rscript data-raw/build_species_data.R

source(file.path("data-raw", "provenance_helpers.R"))
assert_package_root()
manifest <- read_manifest()
arguments <- commandArgs(trailingOnly = TRUE)
output_argument <- grep("^--output-dir=", arguments, value = TRUE)
output_dir <- if (length(output_argument)) {
  sub("^--output-dir=", "", output_argument[[1L]])
} else {
  "data"
}
if (length(output_argument) > 1L || !nzchar(output_dir)) {
  stop("Use at most one non-empty --output-dir=PATH argument.", call. = FALSE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

role_vocabulary <- c(
  "chromatic", "achromatic", "irradiance", "polarization", "fluorescence"
)

read_source <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

fail <- function(message, path) {
  stop(message, "\nSource: ", normalizePath(path, mustWork = FALSE), call. = FALSE)
}

validate_text <- function(x, field, path) {
  if (!is.character(x) || anyNA(x) || any(!nzchar(trimws(x)))) {
    fail(sprintf("`%s` must contain non-empty character values.", field), path)
  }
}

sensitivities_path <- file.path("data-raw", "species_sensitivities.csv")
channels_path <- file.path("data-raw", "species_channels.csv")
support_path <- file.path("data-raw", "species_channel_support.csv")
source_map_path <- file.path("data-raw", "species_source_map.csv")

source_map <- read_source(source_map_path)
if (!identical(names(source_map),
               c("source", "citation_key", "citation_status")) ||
    !nrow(source_map)) {
  fail("`species_source_map.csv` has an invalid schema.", source_map_path)
}
for (field in names(source_map)) {
  validate_text(source_map[[field]], field, source_map_path)
}
if (anyDuplicated(source_map$source) || anyDuplicated(source_map$citation_key)) {
  fail("Species sources and citation keys must each be unique.", source_map_path)
}

species_sensitivities <- read_source(sensitivities_path)
if (nrow(species_sensitivities) == 0L) {
  fail("`species_sensitivities.csv` must contain at least one row.", sensitivities_path)
}
expected_sensitivity_columns <- c(
  "species", "receptor", "lambda_max", "chromophore", "channel_role", "source"
)
if (!identical(names(species_sensitivities), expected_sensitivity_columns)) {
  fail(
    paste(
      "`species_sensitivities.csv` columns must be:",
      paste(expected_sensitivity_columns, collapse = ", ")
    ),
    sensitivities_path
  )
}
for (field in c("species", "receptor", "chromophore", "channel_role", "source")) {
  validate_text(species_sensitivities[[field]], field, sensitivities_path)
}
if (!is.numeric(species_sensitivities$lambda_max) ||
    anyNA(species_sensitivities$lambda_max) ||
    any(!is.finite(species_sensitivities$lambda_max)) ||
    any(species_sensitivities$lambda_max <= 0)) {
  fail("`lambda_max` must contain finite positive numeric values.", sensitivities_path)
}
if (any(!species_sensitivities$chromophore %in% c("A1", "A2"))) {
  fail("`chromophore` contains values outside the A1/A2 vocabulary.", sensitivities_path)
}
if (any(!species_sensitivities$channel_role %in% role_vocabulary)) {
  fail("`channel_role` contains values outside the controlled vocabulary.", sensitivities_path)
}
sensitivity_key <- paste(
  species_sensitivities$species,
  species_sensitivities$receptor,
  sep = "\r"
)
if (anyDuplicated(sensitivity_key)) {
  fail("Each species/receptor pair must be unique.", sensitivities_path)
}

species_channels <- read_source(channels_path)
if (nrow(species_channels) == 0L) {
  fail("`species_channels.csv` must contain at least one row.", channels_path)
}
expected_channel_columns <- c(
  "species", "channel", "channel_role", "receptor", "weight", "is_default",
  "source"
)
if (!identical(names(species_channels), expected_channel_columns)) {
  fail(
    paste(
      "`species_channels.csv` columns must be:",
      paste(expected_channel_columns, collapse = ", ")
    ),
    channels_path
  )
}
for (field in c("species", "channel", "channel_role", "receptor", "source")) {
  validate_text(species_channels[[field]], field, channels_path)
}
if (any(!species_channels$channel_role %in% role_vocabulary)) {
  fail("`channel_role` contains values outside the controlled vocabulary.", channels_path)
}
if (!is.numeric(species_channels$weight) ||
    anyNA(species_channels$weight) ||
    any(!is.finite(species_channels$weight)) ||
    any(species_channels$weight <= 0)) {
  fail("`weight` must contain finite positive numeric values.", channels_path)
}
if (!is.logical(species_channels$is_default) || anyNA(species_channels$is_default)) {
  fail("`is_default` must contain non-missing logical values.", channels_path)
}
channel_key <- paste(
  species_channels$species,
  species_channels$channel,
  species_channels$channel_role,
  species_channels$receptor,
  sep = "\r"
)
if (anyDuplicated(channel_key)) {
  fail("Each species/channel/role/receptor membership must be unique.", channels_path)
}
membership_key <- paste(
  species_channels$species,
  species_channels$receptor,
  sep = "\r"
)
if (any(!membership_key %in% sensitivity_key)) {
  fail(
    "Every channel member must reference a receptor in `species_sensitivities`.",
    channels_path
  )
}

default_channels <- unique(species_channels[
  species_channels$is_default,
  c("species", "channel_role", "channel"),
  drop = FALSE
])
default_key <- paste(
  default_channels$species,
  default_channels$channel_role,
  sep = "\r"
)
if (anyDuplicated(default_key)) {
  fail("A species may have only one default channel for each role.", channels_path)
}

species_channel_support <- read_source(support_path)
if (nrow(species_channel_support) == 0L) {
  fail("`species_channel_support.csv` must contain at least one row.", support_path)
}
expected_support_columns <- c(
  "species", "channel_role", "status", "reason", "source"
)
if (!identical(names(species_channel_support), expected_support_columns)) {
  fail(
    paste(
      "`species_channel_support.csv` columns must be:",
      paste(expected_support_columns, collapse = ", ")
    ),
    support_path
  )
}
for (field in expected_support_columns) {
  validate_text(species_channel_support[[field]], field, support_path)
}
model_roles <- c("chromatic", "achromatic")
if (any(!species_channel_support$channel_role %in% model_roles)) {
  fail("`channel_role` must be chromatic or achromatic.", support_path)
}
if (any(!species_channel_support$status %in% c("supported", "unavailable"))) {
  fail("`status` must be supported or unavailable.", support_path)
}
support_key <- paste(
  species_channel_support$species,
  species_channel_support$channel_role,
  sep = "\r"
)
if (anyDuplicated(support_key)) {
  fail("Each species/role support decision must be unique.", support_path)
}
expected_support_key <- as.vector(outer(
  unique(species_sensitivities$species),
  model_roles,
  paste,
  sep = "\r"
))
if (!setequal(support_key, expected_support_key)) {
  fail(
    "Support decisions must cover every bundled species for both model roles.",
    support_path
  )
}
supported_key <- support_key[species_channel_support$status == "supported"]
if (!setequal(supported_key, default_key)) {
  fail(
    "Supported species/role decisions must exactly match configured defaults.",
    support_path
  )
}

observed_sources <- unique(c(
  species_sensitivities$source,
  species_channels$source,
  species_channel_support$source
))
if (!setequal(observed_sources, source_map$source)) {
  fail(
    "Species source labels must exactly match `species_source_map.csv`.",
    source_map_path
  )
}
citation_key_map <- setNames(source_map$citation_key, source_map$source)
citation_status_map <- setNames(source_map$citation_status, source_map$source)
source_map_md5 <- file_md5(source_map_path)

species_sensitivities <- attach_provenance(
  species_sensitivities, manifest_row("species_sensitivities", manifest),
  configuration = list(role_vocabulary = role_vocabulary,
                       chromophore_vocabulary = c("A1", "A2"),
                       citation_key_map = citation_key_map,
                       citation_status_map = citation_status_map,
                       species_source_map_md5 = source_map_md5)
)
species_channels <- attach_provenance(
  species_channels, manifest_row("species_channels", manifest),
  configuration = list(role_vocabulary = role_vocabulary,
                       default_policy = "one per species and role",
                       citation_key_map = citation_key_map,
                       citation_status_map = citation_status_map,
                       species_source_map_md5 = source_map_md5)
)
species_channel_support <- attach_provenance(
  species_channel_support,
  manifest_row("species_channel_support", manifest),
  configuration = list(model_roles = model_roles,
                       status_vocabulary = c("supported", "unavailable"),
                       citation_key_map = citation_key_map,
                       citation_status_map = citation_status_map,
                       species_source_map_md5 = source_map_md5)
)

objects <- list(
  species_sensitivities = species_sensitivities,
  species_channels = species_channels,
  species_channel_support = species_channel_support
)
destinations <- file.path(output_dir, paste0(names(objects), ".rda"))
write_rda_transaction(objects, destinations)
message("Rebuilt species datasets: ", paste(destinations, collapse = ", "))
