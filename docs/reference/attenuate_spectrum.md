# Propagate a surface spectrum through the water column.

Applies per-wavelength Kd across a depth grid using the Beer-Lambert
law. Returns a tidy data frame, a numeric matrix, or (for lux_spectrum
input) a named list of lux_spectrum objects.

## Usage

``` r
attenuate_spectrum(E0_lambda, ...)

# S3 method for class 'numeric'
attenuate_spectrum(
  E0_lambda,
  Kd_lambda,
  depths,
  format = c("long", "matrix"),
  lambda = NULL,
  ...
)

# S3 method for class 'lux_spectrum'
attenuate_spectrum(E0_lambda, Kd_lambda, depths, ...)
```

## Arguments

- E0_lambda:

  Surface spectral irradiance. Length-N numeric vector or a
  `lux_spectrum` object.

- ...:

  Ignored.

- Kd_lambda:

  Finite, non-negative diffuse attenuation coefficients (1/m) at the
  same wavelength bins as `E0_lambda`. Length-N numeric vector.

- depths:

  Finite, non-negative depths to evaluate in metres. Length-M numeric
  vector.

- format:

  `"long"` (default): tidy data frame with columns `depth`, `lambda`,
  `E`. `"matrix"`: N x M numeric matrix. Ignored for `lux_spectrum`
  input.

- lambda:

  Optional wavelength values (nm) for the `lambda` column of the
  long-format output. Defaults to bin indices 1:N.

## Value

A data frame, matrix, or named list of `lux_spectrum`.

## Details

This is a wavelength-resolved Beer-Lambert calculation, not a
radiative-transfer solution. It assumes a homogeneous \\K_d(\lambda)\\
over the modeled path, treats wavelengths independently, and accepts
only irradiance when a `lux_spectrum` is supplied. The generic numeric
API cannot verify physical quantity or wavelength alignment; callers
must supply aligned irradiance and \\K_d\\ vectors. Bundled Jerlov
coefficients are supported only from 350–700 nm; see
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md).

## References

Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems, 2nd edn.
Cambridge University Press.

## See also

[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md),
[`band_irradiance`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md),
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)

## Examples

``` r
E0  <- c(10, 20, 30)
Kd  <- c(0.01, 0.05, 0.20)
lam <- c(450, 550, 650)
attenuate_spectrum(E0, Kd, depths = c(0, 10, 25), lambda = lam)
#>   depth lambda          E
#> 1     0    450 10.0000000
#> 2     0    550 20.0000000
#> 3     0    650 30.0000000
#> 4    10    450  9.0483742
#> 5    10    550 12.1306132
#> 6    10    650  4.0600585
#> 7    25    450  7.7880078
#> 8    25    550  5.7300959
#> 9    25    650  0.2021384
```
