# Convert a lux_spectrum to a different unit

Converts the spectral values in a `lux_spectrum` between energy and
photon-flux units, or between mW and W for radiance spectra. Supported
conversions: `"W/m2/nm"` \\\leftrightarrow\\ `"umol/m2/s/nm"` /
`"mmol/m2/s/nm"` / `"mol/m2/s/nm"`, and the corresponding `"/sr"`
photonic units. Energy radiance units `"W/m2/sr/nm"` and `"mW/m2/sr/nm"`
are also interchangeable.

## Usage

``` r
convert_unit(x, to, ...)
```

## Arguments

- x:

  A `lux_spectrum` object.

- to:

  Target unit string from the controlled vocabulary.

- ...:

  Ignored.

## Value

A new `lux_spectrum` with updated `unit` and `E`.

## Examples

``` r
lam   <- seq(400, 700, by = 10)
x_W   <- lux_spectrum(rep(1, length(lam)), lam, "irradiance", "W/m2/nm")
x_mol <- convert_unit(x_W, "umol/m2/s/nm")
x_mol$unit
#> [1] "umol/m2/s/nm"
```
