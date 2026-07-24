# Propagate a known spectrum to any other depth(s) (bidirectional).

Applies Beer-Lambert attenuation at each wavelength independently,
propagating a known spectral irradiance from depth `from` to one or more
target depths `to`. Works in both directions: set `to < from` to recover
a shallower (or surface) spectrum from a deeper measurement, assuming a
homogeneous water column.

## Usage

``` r
propagate_spectrum(E_lambda, ...)

# S3 method for class 'numeric'
propagate_spectrum(
  E_lambda,
  Kd_lambda,
  from = 0,
  to,
  format = c("long", "matrix"),
  lambda = NULL,
  allow_above_surface = FALSE,
  ...
)

# S3 method for class 'lux_spectrum'
propagate_spectrum(
  E_lambda,
  Kd_lambda,
  from = 0,
  to,
  allow_above_surface = FALSE,
  ...
)
```

## Arguments

- E_lambda:

  Spectral irradiance at depth `from`. Length-N vector or a
  `lux_spectrum` object.

- ...:

  Ignored.

- Kd_lambda:

  Finite, non-negative diffuse attenuation coefficients (1/m). Length-N
  vector.

- from:

  Finite scalar depth of the known spectrum in metres. Default 0.

- to:

  Finite target depth(s) in metres. Scalar or vector.

- format:

  `"long"` (default) or `"matrix"`. Ignored for `lux_spectrum` input.

- lambda:

  Optional wavelength values (nm) for long-format output.

- allow_above_surface:

  Logical; permits negative absolute depths. Default FALSE.

## Value

A data frame, matrix, or named list of `lux_spectrum`.

## Details

This is the package's principal lightweight propagation tier. It applies
\\E(z,\lambda) = E(z_0,\lambda) \exp\[-K_d(\lambda)(z-z_0)\]\\, assuming
\\K_d\\ is constant along the path and wavelengths propagate
independently. It does not model an angular radiance field, multiple
scattering, or spectral redistribution. There is no universal supported
depth range: validity depends on whether the supplied \\K_d\\ represents
the entire path. Bundled Jerlov data are limited to 350–700 nm. Inverse
propagation is an assumption-heavy reconstruction that amplifies noise.

## References

Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems, 2nd edn.
Cambridge University Press.

## Examples

``` r
E_10m <- c(8, 15, 20)
Kd    <- c(0.02, 0.06, 0.25)
propagate_spectrum(E_10m, Kd, from = 10, to = c(0, 25, 50))
#>   depth lambda            E
#> 1     0      1 9.771222e+00
#> 2     0      2 2.733178e+01
#> 3     0      3 2.436499e+02
#> 4    25      1 5.926546e+00
#> 5    25      2 6.098545e+00
#> 6    25      3 4.703549e-01
#> 7    50      1 3.594632e+00
#> 8    50      2 1.360769e+00
#> 9    50      3 9.079986e-04
```
