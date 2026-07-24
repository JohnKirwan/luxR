library(luxR)
library(shiny)

APP_TABS <- luxR:::.app_tabs()
APP_TAB_TITLES <- stats::setNames(APP_TABS$title, APP_TABS$id)

JERLOV_TYPES <- c("I", "IA", "IB", "II", "III", "C1", "C2", "C3")

SOLAR_LABELS <- c(
  "Clear sky (noon)"   = "clear_noon",
  "Clear sky (dawn)"   = "clear_dawn",
  "Overcast"           = "overcast",
  "Underwater 1 m"     = "underwater_1m",
  "Underwater 10 m"    = "underwater_10m"
)

# Flat-interface Fresnel model used whenever a bundled source is referenced in
# air. These defaults match light_at_depth() and the seeing-through-water
# vignette.
SURFACE_SOURCE <- "direct"
SURFACE_ANGLE_DEG <- 30
SURFACE_REFRACTIVE_INDEX <- 1.333

SPECIES_LIST <- sort(unique(species_sensitivities$species))
CHROMATIC_SPECIES_LIST <- sort(unique(species_channels$species[
  species_channels$channel_role == "chromatic" &
    species_channels$is_default
]))
ACHROMATIC_SPECIES_LIST <- sort(unique(species_channels$species[
  species_channels$channel_role == "achromatic" &
    species_channels$is_default
]))
DETECTION_SPECIES_LIST <- sort(union(
  CHROMATIC_SPECIES_LIST,
  ACHROMATIC_SPECIES_LIST
))

chromatic_receptors <- function(species) {
  rows <- species_channels[
    species_channels$species == species &
      species_channels$channel_role == "chromatic" &
      species_channels$is_default,
    ,
    drop = FALSE
  ]
  rows$receptor
}

detection_channel <- function(species) {
  has_chromatic <- species %in% CHROMATIC_SPECIES_LIST
  has_achromatic <- species %in% ACHROMATIC_SPECIES_LIST
  if (has_chromatic && has_achromatic) return("both")
  if (has_chromatic) return("chromatic")
  if (has_achromatic) return("achromatic")
  stop("Species '", species, "' has no validated detection channel.")
}

channel_source <- function(species, channel_role) {
  rows <- species_channels[
    species_channels$species == species &
      species_channels$channel_role == channel_role &
      species_channels$is_default,
    ,
    drop = FALSE
  ]
  paste(unique(rows$source), collapse = "; ")
}

# ---- Literature references (rendered beneath each tab's plot) -------------
# Citations match the package's function/data documentation verbatim.
REF_ASTM     <- "Light field — solar spectrum: ASTM G173-03 reference solar spectral irradiance."
REF_NAPLES   <- "Example field spectrum — Mare Chiaro, Gulf of Naples: M. J. Bok & J. D. Kirwan (2021), unpublished."
REF_UPLOAD   <- "Light field — user-uploaded spectrum."
REF_JERLOV   <- "Water type Kd(λ): Jerlov (1976) Marine Optics, Elsevier; Solonenko & Mobley (2015) Appl. Opt. 54:5392–5401."
REF_GOVARD   <- "Visual-pigment template: Govardovskii et al. (2000) Vis. Neurosci. 17:509–528."
REF_ABSORPTANCE <- "Self-screening (absorptance): Johnsen (2012) The Optics of Life, ch. 4."
REF_VOROBYEV <- "Colour model: Vorobyev & Osorio (1998) Proc. R. Soc. B 265:351–358; Vorobyev et al. (2001) Vision Res. 41:639–653."
REF_SECCHI   <- "Secchi & photic depth: Tyler (1968) Limnol. Oceanogr. 13:1–6; Preisendorfer (1986) Limnol. Oceanogr. 31:909–926."
REF_VISRANGE <- paste(
  "Heuristic horizontal visual-range scenario: Duntley (1963) J. Opt. Soc.",
  "Am. 53:214–233; Zaneveld & Pegau (2003) Opt. Express 11:2997–3009;",
  "not an empirically validated observer detection range."
)
REF_DETECT   <- paste(
  "Heuristic contrast-threshold sighting-distance scenario: Johnsen (2012)",
  "The Optics of Life, ch. 5 (contrast decays as exp(-c·r)); not an",
  "empirically validated detection-range prediction."
)
REF_IOP      <- "Beam attenuation c = a + b (absorption + scattering): Johnsen (2012) ch. 5; via beam_attenuation()."

# Per-species lambda_max sources, collapsed from species_sensitivities$source.
SPECIES_SOURCE <- vapply(
  split(species_sensitivities$source, species_sensitivities$species),
  function(x) paste(unique(x), collapse = "; "),
  character(1)
)
