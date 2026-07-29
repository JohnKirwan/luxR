# Load a Naples depth spectrum as a lux_spectrum

Load a Naples depth spectrum as a lux_spectrum

## Usage

``` r
from_naples(depth = c("0m", "5m", "10m"))
```

## Arguments

- depth:

  One of `"0m"`, `"5m"`, `"10m"`.

## Value

A `lux_spectrum` with unit `"umol/m2/s/nm"`.

## See also

[`Naples`](https://johnkirwan.github.io/luxR/reference/Naples.md),
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)

## Examples

``` r
x <- from_naples("0m")
print(x)
#> <lux_spectrum> irradiance [umol/m2/s/nm] | 352.5-862.5 nm, 5 nm bins (103 pts)
#>   depth: 0m
#>   source: Naples
#>   reference_depth_m: 0
#>   reference_medium: water
#>   provenance: Naples
#>    provenance: naples-mare-chiaro-legacy
#>    provenance: naplesBokKirwan2021
#>    provenance: unpublished-author-provided-data
#>    provenance: not-applicable
#>    provenance: 2021-12-31
#>    provenance: legacy bundled snapshot; redistribution terms not documented
#>    provenance: legacy canonical snapshot extracted from luxR commit 2375244
#>    provenance: data-raw/naples_legacy_snapshot.csv
#>    provenance: 5952acfab4a04ea1b02eb085e6a768d5
#>    provenance: wv=nm;depth_0m|depth_5m|depth_10m=umol/m2/s/nm
#>    provenance: c(352.5, 862.5)
#>    provenance: 5
#>    provenance: parse canonical processed snapshot; validate schema grid and non-negative irradiance
#>    provenance: naples-legacy-v1
#>    provenance: list(reference_depth_m = c(0, 5, 10), reference_medium = "water")
#>   import: bundled/reference source
#>    import: legacy canonical snapshot extracted from luxR commit 2375244
#>    import: data-raw/naples_legacy_snapshot.csv
#>    import: 5952acfab4a04ea1b02eb085e6a768d5
#>    import: naples-legacy-v1
#>    import: 0.1.1
#>    import: c65df75052bc5337706b58f773130f978e1d903d
#>    import: parse canonical processed snapshot; validate schema grid and non-negative irradiance
```
