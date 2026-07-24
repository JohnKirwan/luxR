# Compute scotopic illuminance (V'(lambda) weighting).

Drop-in replacement for
[`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md)
using the CIE 1951 scotopic luminous efficiency function V'(lambda). The
scotopic luminous efficacy K_m' = 1700 lm/W replaces the photopic K_m =
683 lm/W.

## Usage

``` r
scotopic_lux(irradiance, ...)

# Default S3 method
scotopic_lux(irradiance, ...)

# S3 method for class 'numeric'
scotopic_lux(
  irradiance,
  lambda,
  photonic = FALSE,
  molar_unit = "photons",
  total = TRUE,
  binwidth = NULL,
  integration = c("rectangle", "trapezoid"),
  verbose = FALSE,
  ...
)

# S3 method for class 'lux_spectrum'
scotopic_lux(
  irradiance,
  total = TRUE,
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

  Logical; if `TRUE`, irradiance is in photon or molar units. Default
  `FALSE`.

- molar_unit:

  Molar unit string when `photonic = TRUE` (e.g. `"umol"`). Default
  `"photons"`.

- total:

  Logical; sum per-bin values into a scalar. Default `TRUE`.

- binwidth:

  Wavelength bin width in nm. Inferred from a regular multi-bin
  wavelength grid when `NULL`; required for a single bin under
  rectangular integration. Must be `NULL` for trapezoidal integration.

- integration:

  Integration method passed to
  [`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md):
  `"rectangle"` (default) or `"trapezoid"`.

- verbose:

  Logical; emit diagnostic messages. Default `FALSE`.

## Value

A scalar scotopic lux value (when `total = TRUE`) or numeric vector.

## Details

Scotopic illuminance uses the CIE 1951 scotopic luminous efficiency
function \\V'(\lambda)\\, which peaks at 507 nm. The maximum scotopic
luminous efficacy is \\K_m' = 1700\\ lm W\\^{-1}\\: \$\$E_v' = 1700
\int\_{380}^{780} E(\lambda)\\V'(\lambda)\\d\lambda\$\$ Computed
internally by calling
[`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md)
with `LEF = CIE_scotopic` and applying the efficacy ratio \\1700/683\\.

## Note

The scotopic/photopic crossover occurs near 10 lx. Below that threshold
— twilight, moonlight, deep water — scotopic readings better reflect
perceived brightness.

## Examples

``` r
data(Naples)
scotopic_lux(Naples$depth_10m, Naples$wv,
             photonic = TRUE, molar_unit = "umol")
#> [1] 40379.36
```
