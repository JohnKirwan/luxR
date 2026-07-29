# Load a reference solar spectrum as a lux_spectrum

Load a reference solar spectrum as a lux_spectrum

## Usage

``` r
from_solar(condition = "clear_noon")
```

## Arguments

- condition:

  One of `"clear_noon"`, `"clear_dawn"`, `"overcast"`,
  `"underwater_1m"`, or `"underwater_10m"`.

## Value

A `lux_spectrum` with unit `"W/m2/nm"`.

## See also

[`solar_irradiance`](https://johnkirwan.github.io/luxR/reference/solar_irradiance.md),
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)

## Examples

``` r
x <- from_solar("clear_noon")
print(x)
#> <lux_spectrum> irradiance [W/m2/nm] | 300-800 nm, 10 nm bins (51 pts)
#>   condition: clear_noon
#>   source: ASTM G173-03
#>   reference_depth_m: 0
#>   reference_medium: air
#>   provenance: solar_spectra
#>    provenance: astm-g173-derived-legacy
#>    provenance: c("astmG1732012", "jerlovMarineOptics1976")
#>    provenance: https://www.nrel.gov/grid/solar-resource/spectra-am1.5
#>    provenance: not-applicable
#>    provenance: 2026-05-24
#>    provenance: ASTM source terms apply; derived legacy snapshot
#>    provenance: legacy canonical snapshot extracted from luxR commit 2375244
#>    provenance: data-raw/solar_spectra_legacy_snapshot.csv
#>    provenance: d85c574eff45c07906b6d806cc792c94
#>    provenance: condition=category;wavelength=nm;irradiance=W/m2/nm
#>    provenance: c(300, 800)
#>    provenance: 10
#>    provenance: parse five-condition snapshot; validate grids; retain documented scaling and Jerlov legacy assumptions
#>    provenance: solar-legacy-v1
#>    provenance: list(source_conditions = c("clear_noon", "clear_dawn", "overcast", "underwater_1m", "underwater_10m"), solar_source_metadata_md5 = "c105c39ef020553e8cf12052dce9fa8d", jerlov_source_md5 = "5d2e7745624fb78d4c513ee70af50ee4")
#>   import: bundled/reference source
#>    import: legacy canonical snapshot extracted from luxR commit 2375244
#>    import: data-raw/solar_spectra_legacy_snapshot.csv
#>    import: d85c574eff45c07906b6d806cc792c94
#>    import: solar-legacy-v1
#>    import: 0.1.1
#>    import: 3bd871ca23f845c97359de9d7571cc98acfca7ae
#>    import: parse five-condition snapshot; validate grids; retain documented scaling and Jerlov legacy assumptions
```
