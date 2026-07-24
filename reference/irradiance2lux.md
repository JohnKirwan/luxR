# Provide lux values for measures of spectral irradiance.

Computes photopic illuminance (lux) by weighting spectral irradiance
with the CIE 1931 V(\\\lambda\\) luminous efficiency function. The
default `LEF` argument can be swapped for `CIE_scotopic` to obtain
scotopic lux, or for any user-supplied spectral sensitivity curve.

## Usage

``` r
irradiance2lux(irradiance, ...)

# Default S3 method
irradiance2lux(irradiance, ...)

# S3 method for class 'numeric'
irradiance2lux(
  irradiance,
  lambda,
  photonic = FALSE,
  molar_unit = "photons",
  total = TRUE,
  LEF = CIE1931,
  binwidth = NULL,
  integration = c("rectangle", "trapezoid"),
  verbose = FALSE,
  ...
)

# S3 method for class 'lux_spectrum'
irradiance2lux(
  irradiance,
  total = TRUE,
  LEF = CIE1931,
  integration = c("rectangle", "trapezoid"),
  verbose = FALSE,
  ...
)
```

## Arguments

- irradiance:

  Spectral irradiance (W/m^2/nm or photons/m^2/s/nm) at each wavelength
  bin, or a `lux_spectrum` object whose quantity is `"irradiance"`.
  Photonic `lux_spectrum` inputs are converted to energy units before
  photometric integration; radiance and reflectance spectra are
  rejected.

- ...:

  Ignored.

- lambda:

  Wavelength in nm (not needed for `lux_spectrum`).

- photonic:

  Logical; if `TRUE`, input is in photon or molar units — specify which
  via `molar_unit`. Note: `photonic = TRUE` means raw photon counts only
  in
  [`par_irradiance`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md),
  and molar units only in
  [`n2W_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md).

- molar_unit:

  If photonic, unit string such as `"umol"`. Defaults to `"photons"`.

- total:

  Logical; sum per-bin values into a scalar. Defaults to TRUE.

- LEF:

  Luminous efficiency function data frame. Defaults to CIE1931.

- binwidth:

  Wavelength bin width in nm for rectangular integration. For numeric
  input, inferred from a regularly spaced wavelength grid when `NULL`. A
  single-bin input requires an explicit width. Must be `NULL` for
  trapezoidal integration because the wavelength intervals determine the
  integration weights.

- integration:

  Integration method: `"rectangle"` (default) retains the existing
  bin-centre sum and requires a regular grid; `"trapezoid"` supports
  strictly increasing regular or irregular numeric grids with at least
  two wavelengths.

- verbose:

  Logical; emit diagnostic messages. Defaults to FALSE.

## Value

A scalar lux value (total = TRUE) or numeric vector.

## Details

Photopic illuminance is a spectrally weighted integral of irradiance
using the CIE 1931 photopic luminous efficiency function \\V(\lambda)\\.
The maximum luminous efficacy \\K_m = 683\\ lm W\\^{-1}\\ occurs at 555
nm: \$\$E_v = 683 \int\_{360}^{830} E(\lambda)\\V(\lambda)\\d\lambda\$\$
With the default rectangular method, the integral is approximated as
\\E_v \approx 683 \sum_i E(\lambda_i)\\V(\lambda_i)\\\Delta\lambda\\.
For irregular numeric wavelength grids, callers can explicitly select
composite trapezoidal integration. This treats the weighted spectrum as
piecewise linear between measured wavelengths and integrates only over
`[min(lambda), max(lambda)]`; it does not infer outer bin edges.
\\V(\lambda)\\ values are taken from the `LEF` data frame by linear
interpolation at each measured wavelength. Wavelengths outside the range
of the supplied `LEF` receive zero weight.

## References

CIE Publication 15: Colorimetry, 3rd edn (2004). Commission
Internationale de l'Eclairage, Vienna.

## See also

[`lux2irradiance`](https://johnkirwan.github.io/luxR/reference/lux2irradiance.md),
[`scotopic_lux`](https://johnkirwan.github.io/luxR/reference/scotopic_lux.md),
[`par_irradiance`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)

## Examples

``` r
utils::data(Naples)
irradiance2lux(Naples$depth_0m, Naples$wv, photonic = TRUE, molar_unit = "umol")
#> [1] 24725.63
irradiance2lux(c(0.2, 0.8, 0.4), c(500, 515, 540),
               integration = "trapezoid")
#> [1] 10235.23
```
