# Read a declared, calibrated spectrum with lightr

Parses one instrument file with
[`read_instrument_spectrum`](https://johnkirwan.github.io/luxR/reference/read_instrument_spectrum.md),
then applies explicit scale and negative-value policies before
constructing a
[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md).
Typical native spectrometer grids are irregular, so `interpolate = TRUE`
is normally required. Use
`read_instrument_spectrum(interpolate = FALSE)` to inspect or retain
native sampling without claiming it satisfies the `lux_spectrum` grid
contract.

## Usage

``` r
read_spectrum(
  path,
  measurement = NULL,
  value_scale = NULL,
  quantity = NULL,
  unit = NULL,
  calibration = NULL,
  range = NULL,
  interpolate = FALSE,
  negative_policy = "error",
  parser_args = list(),
  warning_policy = "error"
)
```

## Arguments

- path:

  Path to one spectral file.

- measurement:

  Declared measurement represented by lightr's processed values. See
  [`read_instrument_spectrum`](https://johnkirwan.github.io/luxR/reference/read_instrument_spectrum.md).

- value_scale:

  Declared input scale: `"percent"` or `"fraction"` for reflectance, and
  `"absolute"` for irradiance or radiance.

- quantity:

  Explicit luxR physical quantity. It must match `measurement`.

- unit:

  Explicit unit compatible with `quantity`.

- calibration:

  Non-empty calibration identifier or description.

- range:

  Required finite increasing wavelength limits in nm.

- interpolate:

  Whether lightr should interpolate to integer nanometres. Defaults to
  `FALSE`; irregular native grids will fail construction with guidance
  to opt in or retain the instrument record.

- negative_policy:

  Either `"error"` (default) or an explicit, recorded `"zero"` floor.

- parser_args:

  Named list of simple scalar arguments passed to the lightr parser.

- warning_policy:

  Whether lightr warnings should fail the import or be explicitly
  retained. Defaults to fail-fast behavior.

## Value

A validated
[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
with calibration, instrument metadata, parser provenance, notices,
scaling, and resampling policy.

## See also

[`read_instrument_spectrum`](https://johnkirwan.github.io/luxR/reference/read_instrument_spectrum.md),
[`from_ocean_optics`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md),
[`read_ocean_optics`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md),
[`from_trios`](https://johnkirwan.github.io/luxR/reference/from_trios.md)

## Examples

``` r
# A reflectance spectrum from an Ocean Optics Jaz file shipped with lightr:
f <- system.file("testdata", "jazspec.jaz", package = "lightr")
if (requireNamespace("lightr", quietly = TRUE) && nzchar(f)) {
  x <- read_spectrum(
    f,
    measurement = "reflectance", value_scale = "percent",
    quantity = "reflectance", unit = "dimensionless",
    calibration = "white standard",
    range = c(400, 700), interpolate = TRUE
  )
  range(x$E)
}
#> [1] 0.1704821 0.7287551
```
