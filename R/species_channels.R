# species_channels.R -- validated biological channel selection

.CHANNEL_ROLE_VOCABULARY <- c(
  "chromatic", "achromatic", "irradiance", "polarization", "fluorescence"
)

.stop_species_model <- function(message, class, ...) {
  condition <- structure(
    c(list(message = message, call = NULL), list(...)),
    class = c(class, "lux_species_model_error", "luxR_error", "error", "condition")
  )
  stop(condition)
}

.validate_species_model_data <- function(
    sensitivities = species_sensitivities,
    channels = species_channels,
    support = species_channel_support) {
  if (!is.data.frame(sensitivities) || nrow(sensitivities) == 0L) {
    .stop_species_model(
      "`species_sensitivities` must be a non-empty data frame.",
      "lux_species_data_error",
      dataset = "species_sensitivities"
    )
  }
  sensitivity_columns <- c(
    "species", "receptor", "lambda_max", "chromophore", "channel_role", "source"
  )
  if (!identical(names(sensitivities), sensitivity_columns)) {
    .stop_species_model(
      paste(
        "`species_sensitivities` has an invalid schema; expected columns:",
        paste(sensitivity_columns, collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_sensitivities",
      expected_columns = sensitivity_columns,
      actual_columns = names(sensitivities)
    )
  }
  text_columns <- c("species", "receptor", "chromophore", "channel_role", "source")
  bad_text <- vapply(text_columns, function(field) {
    value <- sensitivities[[field]]
    !is.character(value) || anyNA(value) || any(!nzchar(trimws(value)))
  }, logical(1))
  if (any(bad_text)) {
    .stop_species_model(
      paste(
        "`species_sensitivities` contains invalid text fields:",
        paste(text_columns[bad_text], collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_sensitivities",
      invalid_fields = text_columns[bad_text]
    )
  }
  if (!is.numeric(sensitivities$lambda_max) ||
      anyNA(sensitivities$lambda_max) ||
      any(!is.finite(sensitivities$lambda_max)) ||
      any(sensitivities$lambda_max <= 0)) {
    .stop_species_model(
      "`species_sensitivities$lambda_max` must be finite and strictly positive.",
      "lux_species_data_error",
      dataset = "species_sensitivities",
      field = "lambda_max"
    )
  }
  if (any(!sensitivities$chromophore %in% c("A1", "A2"))) {
    .stop_species_model(
      "`species_sensitivities$chromophore` contains an unsupported value.",
      "lux_species_data_error",
      dataset = "species_sensitivities",
      field = "chromophore"
    )
  }
  if (any(!sensitivities$channel_role %in% .CHANNEL_ROLE_VOCABULARY)) {
    .stop_species_model(
      "`species_sensitivities$channel_role` contains an unsupported value.",
      "lux_species_data_error",
      dataset = "species_sensitivities",
      field = "channel_role"
    )
  }
  sensitivity_key <- paste(
    sensitivities$species, sensitivities$receptor, sep = "\r"
  )
  if (anyDuplicated(sensitivity_key)) {
    .stop_species_model(
      "`species_sensitivities` contains a duplicated species/receptor pair.",
      "lux_species_data_error",
      dataset = "species_sensitivities",
      key = c("species", "receptor")
    )
  }

  if (!is.data.frame(channels) || nrow(channels) == 0L) {
    .stop_species_model(
      "`species_channels` must be a non-empty data frame.",
      "lux_species_data_error",
      dataset = "species_channels"
    )
  }
  channel_columns <- c(
    "species", "channel", "channel_role", "receptor", "weight", "is_default",
    "source"
  )
  if (!identical(names(channels), channel_columns)) {
    .stop_species_model(
      paste(
        "`species_channels` has an invalid schema; expected columns:",
        paste(channel_columns, collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_channels",
      expected_columns = channel_columns,
      actual_columns = names(channels)
    )
  }
  channel_text_columns <- c(
    "species", "channel", "channel_role", "receptor", "source"
  )
  bad_channel_text <- vapply(channel_text_columns, function(field) {
    value <- channels[[field]]
    !is.character(value) || anyNA(value) || any(!nzchar(trimws(value)))
  }, logical(1))
  if (any(bad_channel_text)) {
    .stop_species_model(
      paste(
        "`species_channels` contains invalid text fields:",
        paste(channel_text_columns[bad_channel_text], collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_channels",
      invalid_fields = channel_text_columns[bad_channel_text]
    )
  }
  if (any(!channels$channel_role %in% .CHANNEL_ROLE_VOCABULARY)) {
    .stop_species_model(
      "`species_channels$channel_role` contains an unsupported value.",
      "lux_species_data_error",
      dataset = "species_channels",
      field = "channel_role"
    )
  }
  if (!is.numeric(channels$weight) ||
      anyNA(channels$weight) ||
      any(!is.finite(channels$weight)) ||
      any(channels$weight <= 0)) {
    .stop_species_model(
      "`species_channels$weight` must be finite and strictly positive.",
      "lux_species_data_error",
      dataset = "species_channels",
      field = "weight"
    )
  }
  if (!is.logical(channels$is_default) || anyNA(channels$is_default)) {
    .stop_species_model(
      "`species_channels$is_default` must be non-missing logical data.",
      "lux_species_data_error",
      dataset = "species_channels",
      field = "is_default"
    )
  }
  channel_key <- paste(
    channels$species,
    channels$channel,
    channels$channel_role,
    channels$receptor,
    sep = "\r"
  )
  if (anyDuplicated(channel_key)) {
    .stop_species_model(
      "`species_channels` contains a duplicated channel membership.",
      "lux_species_data_error",
      dataset = "species_channels",
      key = c("species", "channel", "channel_role", "receptor")
    )
  }
  membership_key <- paste(channels$species, channels$receptor, sep = "\r")
  if (any(!membership_key %in% sensitivity_key)) {
    .stop_species_model(
      "`species_channels` references an unknown species/receptor pair.",
      "lux_species_data_error",
      dataset = "species_channels",
      key = c("species", "receptor")
    )
  }

  channel_identity <- paste(
    channels$species, channels$channel_role, channels$channel, sep = "\r"
  )
  default_consistency <- tapply(
    channels$is_default,
    channel_identity,
    function(value) length(unique(value)) == 1L
  )
  if (any(!default_consistency)) {
    .stop_species_model(
      "Every member of a channel must have the same `is_default` value.",
      "lux_species_data_error",
      dataset = "species_channels",
      field = "is_default"
    )
  }
  default_channels <- unique(channels[
    channels$is_default,
    c("species", "channel_role", "channel"),
    drop = FALSE
  ])
  default_key <- paste(
    default_channels$species, default_channels$channel_role, sep = "\r"
  )
  if (anyDuplicated(default_key)) {
    .stop_species_model(
      "A species may have only one default channel for each role.",
      "lux_species_data_error",
      dataset = "species_channels",
      key = c("species", "channel_role")
    )
  }

  if (!is.data.frame(support) || nrow(support) == 0L) {
    .stop_species_model(
      "`species_channel_support` must be a non-empty data frame.",
      "lux_species_data_error",
      dataset = "species_channel_support"
    )
  }
  support_columns <- c(
    "species", "channel_role", "status", "reason", "source"
  )
  if (!identical(names(support), support_columns)) {
    .stop_species_model(
      paste(
        "`species_channel_support` has an invalid schema; expected columns:",
        paste(support_columns, collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_channel_support",
      expected_columns = support_columns,
      actual_columns = names(support)
    )
  }
  bad_support_text <- vapply(support_columns, function(field) {
    value <- support[[field]]
    !is.character(value) || anyNA(value) || any(!nzchar(trimws(value)))
  }, logical(1))
  if (any(bad_support_text)) {
    .stop_species_model(
      paste(
        "`species_channel_support` contains invalid text fields:",
        paste(support_columns[bad_support_text], collapse = ", ")
      ),
      "lux_species_data_error",
      dataset = "species_channel_support",
      invalid_fields = support_columns[bad_support_text]
    )
  }
  model_roles <- c("chromatic", "achromatic")
  if (any(!support$channel_role %in% model_roles) ||
      any(!support$status %in% c("supported", "unavailable"))) {
    .stop_species_model(
      "`species_channel_support` contains an unsupported role or status.",
      "lux_species_data_error",
      dataset = "species_channel_support"
    )
  }
  support_key <- paste(support$species, support$channel_role, sep = "\r")
  if (anyDuplicated(support_key)) {
    .stop_species_model(
      "`species_channel_support` contains a duplicated species/role decision.",
      "lux_species_data_error",
      dataset = "species_channel_support",
      key = c("species", "channel_role")
    )
  }
  expected_support_key <- as.vector(outer(
    unique(sensitivities$species), model_roles, paste, sep = "\r"
  ))
  if (!setequal(support_key, expected_support_key)) {
    .stop_species_model(
      paste(
        "`species_channel_support` must cover every bundled species for both",
        "chromatic and achromatic roles."
      ),
      "lux_species_data_error",
      dataset = "species_channel_support"
    )
  }
  supported_key <- support_key[support$status == "supported"]
  if (!setequal(supported_key, default_key)) {
    .stop_species_model(
      paste(
        "Supported species/role decisions must exactly match configured",
        "default channels."
      ),
      "lux_species_data_error",
      dataset = "species_channel_support"
    )
  }

  invisible(TRUE)
}

.default_channel_receptors <- function(species, channel_role, receptor = NULL) {
  if (!is.character(species) || length(species) != 1L ||
      is.na(species) || !nzchar(trimws(species))) {
    .stop_species_model(
      "`species` must be one non-empty character value.",
      "lux_unknown_species_error",
      species = species,
      channel_role = channel_role
    )
  }
  if (!is.character(channel_role) || length(channel_role) != 1L ||
      is.na(channel_role) || !channel_role %in% .CHANNEL_ROLE_VOCABULARY) {
    .stop_species_model(
      paste(
        "`channel_role` must be one of:",
        paste(.CHANNEL_ROLE_VOCABULARY, collapse = ", ")
      ),
      "lux_channel_unavailable_error",
      species = species,
      channel_role = channel_role
    )
  }

  .validate_species_model_data()

  species_rows <- species_sensitivities[
    species_sensitivities$species == species,
    ,
    drop = FALSE
  ]
  if (nrow(species_rows) == 0L) {
    .stop_species_model(
      sprintf("Unknown species '%s'.", species),
      "lux_unknown_species_error",
      species = species,
      channel_role = channel_role
    )
  }

  candidates <- species_channels[
    species_channels$species == species &
      species_channels$channel_role == channel_role &
      species_channels$is_default,
    ,
    drop = FALSE
  ]
  channel_names <- unique(candidates$channel)
  if (length(channel_names) != 1L) {
    decision <- species_channel_support[
      species_channel_support$species == species &
        species_channel_support$channel_role == channel_role,
      ,
      drop = FALSE
    ]
    reason <- if (nrow(decision) == 1L) decision$reason else "No support decision."
    .stop_species_model(
      sprintf(
        "Species '%s' has no unique default %s channel: %s",
        species,
        channel_role,
        reason
      ),
      "lux_channel_unavailable_error",
      species = species,
      channel_role = channel_role,
      available_channels = unique(
        species_channels$channel[species_channels$species == species]
      ),
      reason = reason
    )
  }

  configured_receptors <- candidates$receptor
  if (is.null(receptor)) {
    selected_receptors <- configured_receptors
  } else {
    if (!is.character(receptor) || length(receptor) == 0L ||
        anyNA(receptor) || any(!nzchar(trimws(receptor))) ||
        anyDuplicated(receptor)) {
      .stop_species_model(
        "`receptor` must contain unique, non-empty receptor names.",
        "lux_invalid_receptor_error",
        species = species,
        channel_role = channel_role,
        channel = channel_names,
        receptor = receptor
      )
    }
    invalid <- receptor[!receptor %in% configured_receptors]
    if (length(invalid) > 0L) {
      .stop_species_model(
        sprintf(
          "Unsupported %s receptor(s) for species '%s': %s. Valid receptors: %s.",
          channel_role,
          species,
          paste(invalid, collapse = ", "),
          paste(configured_receptors, collapse = ", ")
        ),
        "lux_invalid_receptor_error",
        species = species,
        channel_role = channel_role,
        channel = channel_names,
        receptor = receptor,
        invalid_receptors = invalid,
        valid_receptors = configured_receptors
      )
    }
    selected_receptors <- receptor
  }

  selected_rows <- species_rows[
    match(selected_receptors, species_rows$receptor),
    ,
    drop = FALSE
  ]
  attr(selected_rows, "channel") <- channel_names
  attr(selected_rows, "channel_weights") <- candidates$weight[
    match(selected_receptors, candidates$receptor)
  ]
  selected_rows
}

.validated_channel_species <- function(channel_role) {
  .validate_species_model_data()
  sort(unique(species_channels$species[
    species_channels$channel_role == channel_role &
      species_channels$is_default
  ]))
}
