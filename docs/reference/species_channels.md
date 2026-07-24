# Validated visual-channel memberships for selected species.

Defines cited receptor combinations that package models may use by
default. Receptors marked with a role in
[`species_sensitivities`](https://johnkirwan.github.io/luxR/reference/species_sensitivities.md)
are not model-eligible unless they occur in this table.

## Usage

``` r
species_channels
```

## Format

A data frame with 13 rows and 7 columns:

- species:

  Scientific name matching `species_sensitivities$species`.

- channel:

  Stable channel identifier within a species.

- channel_role:

  Biological role from the controlled vocabulary.

- receptor:

  Receptor member matching a species/receptor pair in
  `species_sensitivities`.

- weight:

  Finite positive channel membership weight. Chromatic JND currently
  uses receptor-noise weighting rather than this field.

- is_default:

  Whether this is the default channel for its species and role. A
  species can have at most one default channel per role.

- source:

  Literature citation supporting the receptor set.

## Details

The curated set contains default chromatic channels for *Homo sapiens*,
*Danio rerio*, and *Apis mellifera*, plus behavioural achromatic
channels for adult light-adapted *Danio rerio*, *Apis mellifera*, and
*Drosophila melanogaster*. Species with incomplete or ambiguous receptor
sets are deliberately absent and therefore fail rather than falling back
to every known receptor.

## References

Krauss A, Neumeyer C (2003) Wavelength dependence of the optomotor
response in zebrafish (Danio rerio). Vision Research 43:1275-1284.
[doi:10.1016/S0042-6989(03)00090-7](https://doi.org/10.1016/S0042-6989%2803%2900090-7)

Niggebrugge C, Hempel de Ibarra N (2003) Colour-dependent target
detection by bees. Journal of Comparative Physiology A 189:915-918.
[doi:10.1007/s00359-003-0466-3](https://doi.org/10.1007/s00359-003-0466-3)

Yamaguchi S, Wolf R, Desplan C, Heisenberg M (2008) Motion vision is
independent of color in Drosophila. PNAS 105:4910-4915.
[doi:10.1073/pnas.0711484105](https://doi.org/10.1073/pnas.0711484105)

## Examples

``` r
data(species_channels)
subset(species_channels, species == "Homo sapiens")
#>        species       channel channel_role receptor weight is_default
#> 1 Homo sapiens cone_opponent    chromatic   S-cone      1       TRUE
#> 2 Homo sapiens cone_opponent    chromatic   M-cone      1       TRUE
#> 3 Homo sapiens cone_opponent    chromatic   L-cone      1       TRUE
#>                     source
#> 1 Bowmaker & Dartnall 1980
#> 2 Bowmaker & Dartnall 1980
#> 3 Bowmaker & Dartnall 1980
```
