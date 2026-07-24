# Species visual-channel support decisions.

Records whether every bundled species has a supported default chromatic
and achromatic model. Unsupported combinations remain explicit rather
than being inferred from receptor-role labels.

## Usage

``` r
species_channel_support
```

## Format

A data frame with 16 rows and 5 columns:

- species:

  Scientific name matching `species_sensitivities`.

- channel_role:

  Either `"chromatic"` or `"achromatic"`.

- status:

  Either `"supported"` or `"unavailable"`.

- reason:

  Evidence summary or reason no default is available.

- source:

  Literature citation or explicit package review decision.

## Details

Every supported row must correspond to exactly one default in
[`species_channels`](https://johnkirwan.github.io/luxR/reference/species_channels.md).
Every unavailable row must have no default. Dataset generation and
runtime validation enforce this invariant.

## Examples

``` r
data(species_channel_support)
subset(species_channel_support, species == "Homo sapiens")
#>        species channel_role      status
#> 1 Homo sapiens    chromatic   supported
#> 2 Homo sapiens   achromatic unavailable
#>                                                           reason
#> 1                          Validated S M and L cone opponent set
#> 2 No adaptation-specific photopic or scotopic default is encoded
#>                     source
#> 1 Bowmaker & Dartnall 1980
#> 2  Package review decision
```
