# Convert luxR spectra to a colourvision input data frame

Reshapes luxR data into the plain data frame colourvision expects for an
illuminant (`I`) or reflectance (`R1`, `R2`, `Rb`): the first column is
wavelength and each remaining column is one spectrum. luxR handles the
water (depth propagation, the in-water light field); colourvision
handles the colour-space / visual model (`RNLmodel()`, `CTTKmodel()`,
colour spaces). Build the receptor matrix `C` with
[`species_sensitivity_matrix`](https://johnkirwan.github.io/luxR/reference/species_sensitivity_matrix.md).

## Usage

``` r
as_colourvision(x, ...)

# S3 method for class 'lux_spectrum'
as_colourvision(x, name = NULL, ...)

# S3 method for class 'list'
as_colourvision(x, ...)
```

## Arguments

- x:

  A
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
  or a (named) list of them. Every list element must already share the
  first spectrum's wavelength grid; mismatched grids are an error, so
  resample explicitly before conversion rather than relying on silent
  extrapolation.

- ...:

  Currently unused; present for method consistency.

- name:

  Single-spectrum method only: the value column name. Defaults to the
  spectrum's `meta$label`, then `meta$source`, then `"spec"`.

## Value

A `data.frame` with a `wl` column plus one column per spectrum, ready to
pass as colourvision's `I`, `R1`, `R2`, or `Rb`.

## Details

Unlike
[`as_rspec`](https://johnkirwan.github.io/luxR/reference/as_rspec.md),
this performs no interpolation: colourvision resamples inputs itself via
its `nm`/`interpolate` arguments at model time, so the converter is a
pure reshape with no hidden resampling. colourvision is an optional
(`Suggests`) dependency.

## See also

[`species_sensitivity_matrix`](https://johnkirwan.github.io/luxR/reference/species_sensitivity_matrix.md)
for the `C` matrix;
[`as_rspec`](https://johnkirwan.github.io/luxR/reference/as_rspec.md)
for the pavo equivalent;
[`colourvision::RNLmodel`](https://rdrr.io/pkg/colourvision/man/RNLmodel.html)

## Examples

``` r
if (FALSE) { # \dontrun{
  I  <- as_colourvision(from_solar("clear_noon"), name = "I")
} # }
```
