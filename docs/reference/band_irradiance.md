# Band-integrated irradiance at one or more depths

Propagates a spectrum from a known depth to one or more target depths
via Beer-Lambert attenuation and integrates the result over a wavelength
band. Works in both directions: set `from` \> `depths` to recover
shallower values (including the surface) from a deeper measurement.

## Usage

``` r
band_irradiance(E_lambda, ...)

# S3 method for class 'numeric'
band_irradiance(
  E_lambda,
  Kd_lambda,
  lambda,
  depths,
  from = 0,
  lambda_min = NULL,
  lambda_max = NULL,
  photonic = FALSE,
  molar_unit = "umol",
  binwidth = NULL,
  allow_above_surface = FALSE,
  ...
)

# S3 method for class 'lux_spectrum'
band_irradiance(E_lambda, Kd_lambda, depths, lambda = NULL, ...)
```

## Arguments

- E_lambda:

  Spectral irradiance (W/m^2/nm) at depth `from`. Length-N vector, or a
  `lux_spectrum` object.

- ...:

  Ignored.

- Kd_lambda:

  Diffuse attenuation coefficients (1/m) at the same wavelengths.
  Length-N vector.

- lambda:

  Wavelengths in nm. Length-N vector (not needed when `E_lambda` is a
  `lux_spectrum`).

- depths:

  Target depth(s) in metres. Scalar or vector.

- from:

  Depth of the known spectrum in metres. Default `0` (surface). Set to a
  positive value to propagate from a subsurface measurement.

- lambda_min:

  Lower wavelength bound in nm (inclusive). Defaults to `min(lambda)`.

- lambda_max:

  Upper wavelength bound in nm (inclusive). Defaults to `max(lambda)`.

- photonic:

  Logical; if `TRUE` the result is returned in \\\mu\\mol photons
  m\\^{-2}\\ s\\^{-1}\\ rather than W/m^2. Default `FALSE`.

- molar_unit:

  Molar unit for photonic output. Default `"umol"`.

- binwidth:

  Wavelength bin width in nm. Inferred from `lambda` if not supplied.

- allow_above_surface:

  Logical; permits target depths above the surface (negative values).
  Default `FALSE`.

## Value

A `data.frame` with columns:

- depth:

  Target depth in metres.

- E:

  Band-integrated irradiance in W/m^2 (or \\\mu\\mol/m^2/s when
  `photonic = TRUE`).

## Details

Two operations are applied in sequence. First, Beer-Lambert propagation
at each wavelength: \$\$E(z,\\\lambda) = E_0(\lambda)\\
\exp\\\bigl\[-K_d(\lambda)\\(z - z_0)\bigr\]\$\$ where \\z_0\\ is the
depth of the known spectrum (`from`) and \\K_d(\lambda)\\ is the diffuse
attenuation coefficient. Second, the propagated spectrum is integrated
over the specified wavelength window \[\\\lambda\_{\min}\\,
\\\lambda\_{\max}\\\]: \$\$E\_{\mathrm{band}}(z) =
\int\_{\lambda\_{\min}}^{\lambda\_{\max}} E(z,\\\lambda)\\d\lambda\$\$
approximated as \\\sum_i E(z,\lambda_i)\\\Delta\lambda\\ over bins
within the window. See
[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md)
for the full Beer-Lambert documentation.

## See also

[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md),
[`par_irradiance`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)

## Examples

``` r
sp  <- solar_irradiance("clear_noon")
keep <- sp$wavelength >= 350 & sp$wavelength <= 700
lam <- sp$wavelength[keep]
E0  <- sp$irradiance[keep]
Kd  <- jerlov_Kd("II", lam)

# surface to depth profile, 500-600 nm band
band_irradiance(E0, Kd, lam, depths = c(0, 5, 10, 20, 50),
                lambda_min = 500, lambda_max = 600)
#>   depth          E
#> 1     0 198.300000
#> 2     5 134.985969
#> 3    10  93.620606
#> 4    20  47.073651
#> 5    50   7.323195

# recover surface from a 10 m measurement
E_10m <- E0 * exp(-Kd * 10)
band_irradiance(E_10m, Kd, lam, depths = 0, from = 10)
#>   depth   E
#> 1     0 535
```
