# Create a lux_spectrum object

Constructs a validated `lux_spectrum` — the core spectral container used
throughout luxR. The object carries spectral values, wavelength grid,
physical quantity, unit, bin width, and free-form metadata together, so
unit conversions and arithmetic operations stay consistent.

## Usage

``` r
lux_spectrum(
  E,
  lambda,
  quantity = "irradiance",
  unit = "W/m2/nm",
  binwidth = NULL,
  meta = list()
)
```

## Arguments

- E:

  Numeric vector of spectral values, one per wavelength bin.

- lambda:

  Numeric vector of bin-centre wavelengths in nm.

- quantity:

  Physical quantity: `"irradiance"`, `"radiance"`, or `"reflectance"`.

- unit:

  Unit string from the controlled vocabulary. See Details.

- binwidth:

  Bin width in nm. Inferred from the wavelength spacing when `NULL`;
  defaults to 1 for a single-bin spectrum. An explicit value must be
  finite, positive, scalar, and match the regular wavelength spacing.

- meta:

  Named list of free-form metadata (depth, instrument, etc.).

## Value

An S3 object of class `"lux_spectrum"`.

## Details

Valid unit strings: `"W/m2/nm"`, `"W/m2/sr/nm"`, `"mW/m2/sr/nm"`,
`"umol/m2/s/nm"`, `"mmol/m2/s/nm"`, `"mol/m2/s/nm"`,
`"umol/m2/s/sr/nm"`, `"mmol/m2/s/sr/nm"`, `"mol/m2/s/sr/nm"`,
`"dimensionless"`.

Both spectral vectors must be non-empty, numeric, finite, and equal in
length. Wavelengths must be strictly increasing, unique, and regularly
spaced. Irradiance and radiance values must be non-negative; reflectance
values must lie in `[0, 1]`. Units without `"/sr"` describe irradiance,
units with `"/sr"` describe radiance, and `"dimensionless"` is valid
only for reflectance.

**S3 methods available on `lux_spectrum` objects:**
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html),
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html), `[`
(wavelength subsetting), and the arithmetic operators `+`, `-`, `*`,
`/`. A list of `lux_spectrum` objects can be plotted with
[`plot_spectra`](https://johnkirwan.github.io/luxR/reference/plot_spectra.md).

## See also

[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md),
[`convert_unit`](https://johnkirwan.github.io/luxR/reference/convert_unit.md),
[`plot_spectra`](https://johnkirwan.github.io/luxR/reference/plot_spectra.md)

## Examples

``` r
lam <- seq(400, 700, by = 10)
x   <- lux_spectrum(rep(1, length(lam)), lam, "irradiance", "W/m2/nm")
print(x)
#> <lux_spectrum> irradiance [W/m2/nm] | 400-700 nm, 10 nm bins (31 pts)
```
