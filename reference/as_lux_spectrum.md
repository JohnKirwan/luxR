# Coerce an object to lux_spectrum

Converts a numeric vector or data frame to a
[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
object. The data-frame method auto-detects the wavelength column
(`lambda` \> `wavelength` \> `wv`) and the spectral-value column (`E` \>
`irradiance` \> `radiance` \> `value`). Passing an existing
`lux_spectrum` returns it unchanged.

## Usage

``` r
as_lux_spectrum(x, ...)

# S3 method for class 'numeric'
as_lux_spectrum(
  x,
  lambda,
  quantity = "irradiance",
  unit = "W/m2/nm",
  binwidth = NULL,
  meta = list(),
  ...
)

# S3 method for class 'data.frame'
as_lux_spectrum(
  x,
  lambda_col = NULL,
  E_col = NULL,
  quantity = "irradiance",
  unit = "W/m2/nm",
  binwidth = NULL,
  meta = list(),
  ...
)

# S3 method for class 'lux_spectrum'
as_lux_spectrum(x, ...)

# S3 method for class 'lux_instrument_spectrum'
as_lux_spectrum(
  x,
  quantity = NULL,
  unit = NULL,
  calibration = NULL,
  negative_policy = "error",
  ...
)

# S3 method for class 'rspec'
as_lux_spectrum(
  x,
  column = 2,
  quantity = "irradiance",
  unit = "W/m2/nm",
  meta = list(),
  ...
)

# S3 method for class 'source_spct'
as_lux_spectrum(
  x,
  measurement = NULL,
  negative_policy = "error",
  interpolate = FALSE,
  ...
)

# S3 method for class 'reflector_spct'
as_lux_spectrum(x, negative_policy = "error", interpolate = FALSE, ...)
```

## Arguments

- x:

  Object to coerce.

- ...:

  Additional arguments passed to methods.

- lambda:

  Wavelength vector in nm (required for numeric method).

- quantity:

  Physical quantity string. Default `"irradiance"`.

- unit:

  Unit string from the controlled vocabulary. Default `"W/m2/nm"`.

- binwidth:

  Bin width in nm; inferred if `NULL`.

- meta:

  Named list of metadata.

- lambda_col:

  Column name for wavelengths. Auto-detected from `lambda` \>
  `wavelength` \> `wv` if `NULL`.

- E_col:

  Column name for spectral values. Auto-detected from `E` \>
  `irradiance` \> `radiance` \> `value` if `NULL`.

- calibration:

  For an instrument spectrum, a non-empty calibration identifier or
  description.

- negative_policy:

  For an instrument spectrum, either error on negative processed values
  or explicitly replace them with zero and record the affected indices.

- column:

  For the `rspec` method (pavo), which spectrum column to convert: a
  column name or index. Default the first spectrum (column 2, after
  `wl`).

- measurement:

  For a photobiology `source_spct` carrying both an energy and a photon
  column, which to import: `"energy"` or `"photon"`. Required only when
  the choice is ambiguous.

- interpolate:

  For a photobiology spectrum, whether an irregular wavelength grid may
  be resampled onto integer nanometres. Defaults to `FALSE`, so
  irregular grids fail with guidance to opt in.

## Value

A `lux_spectrum` object.

## See also

[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
[`from_naples`](https://johnkirwan.github.io/luxR/reference/from_naples.md),
[`from_solar`](https://johnkirwan.github.io/luxR/reference/from_solar.md)

## Examples

``` r
# from a numeric vector
lam <- seq(400, 700, by = 10)
as_lux_spectrum(rep(1, length(lam)), lambda = lam)
#> <lux_spectrum> irradiance [W/m2/nm] | 400-700 nm, 10 nm bins (31 pts)

# from a data frame
df <- data.frame(lambda = lam, E = rep(1, length(lam)))
as_lux_spectrum(df)
#> <lux_spectrum> irradiance [W/m2/nm] | 400-700 nm, 10 nm bins (31 pts)
```
