# Per-species sensitivity-weighted photon irradiance.

Convenience wrapper around
[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)
and
[`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
that returns quantum catches for all (or one) receptor class of a named
species.

## Usage

``` r
species_brightness(
  irradiance,
  lambda,
  species,
  input_unit = NULL,
  channel = "by_receptor",
  binwidth = NULL
)
```

## Arguments

- irradiance:

  Non-negative spectral irradiance vector, one value per wavelength bin,
  in the exact unit declared by `input_unit`.

- lambda:

  Wavelength bin centres in nm.

- species:

  Species name. Must appear in `species_sensitivities`.

- input_unit:

  Exact unit of `irradiance`; see
  [`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md).
  No photon or molar unit is inferred from a bare numeric vector.

- channel:

  One of:

  - `"by_receptor"` — named numeric vector, one value per receptor
    class;

  - `"all"` — scalar sum across all receptor classes;

  - a specific receptor name (e.g. `"L-cone"`) — single scalar.

- binwidth:

  Wavelength bin width in nm. Inferred from `lambda` spacing if `NULL`
  (default).

## Value

Named numeric vector, scalar, or single numeric depending on `channel`.

## See also

[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md),
[`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md),
[`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)

## Examples

``` r
idx <- Naples$wv >= 400 & Naples$wv <= 700
lam <- Naples$wv[idx]
irr <- Naples$depth_0m[idx]
species_brightness(irr, lam, "Homo sapiens",
                   input_unit = "umol/m2/s/nm",
                   channel = "by_receptor")
#>       L-cone       M-cone       S-cone        ipRGC          rod 
#> 1.213061e+20 1.159709e+20 7.042054e+19 9.997104e+19 1.068896e+20 
```
