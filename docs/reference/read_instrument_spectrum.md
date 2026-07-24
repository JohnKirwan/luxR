# Parse one instrument spectrum with lightr

Uses lightr for file-format dispatch while retaining a strict,
single-spectrum record that can represent irregular wavelength grids and
signed processed values. This function does not claim that processed
values are a physically valid
[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md);
use
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
or
[`read_spectrum`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)
for that step.

## Usage

``` r
read_instrument_spectrum(
  path,
  measurement = NULL,
  value_scale = NULL,
  range = NULL,
  interpolate = FALSE,
  parser_args = list(),
  warning_policy = "error"
)
```

## Arguments

- path:

  Path to one spectral file.

- measurement:

  Declared measurement represented by the processed values: one of
  `"reflectance"`, `"irradiance"`, `"radiance"`, `"transmittance"`,
  `"absorbance"`, or `"raw"`.

- value_scale:

  Declared scale of the processed values: `"fraction"`, `"percent"`,
  `"absolute"`, or `"raw"`.

- range:

  Two finite increasing wavelength limits in nm.

- interpolate:

  Whether lightr should interpolate to integer nanometres. The default
  preserves native sampling in the instrument record.

- parser_args:

  Named list of simple scalar arguments passed to lightr's individual
  parser. Arguments controlling file discovery, wavelength range, or
  interpolation cannot be overridden.

- warning_policy:

  Whether parser and metadata warnings should cause an error (the
  default) or be explicitly retained in the import record.

## Value

A `lux_instrument_spectrum` containing wavelengths, processed values,
declarations, instrument metadata, notices, and reproducibility context.

## See also

[`read_spectrum`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md),
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
