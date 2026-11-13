# Estimate the diffuse attenuation coefficient from two irradiance readings.

Closed-form Beer-Lambert inversion: Kd = log(E1/E2) / (z2 - z1). Works
for scalar or spectral (vector) inputs, or `lux_spectrum` objects.

## Usage

``` r
fit_Kd(E1, ...)

# S3 method for class 'numeric'
fit_Kd(E1, z1, E2, z2, ...)

# S3 method for class 'lux_spectrum'
fit_Kd(E1, z1, E2, z2, ...)
```

## Arguments

- E1:

  Irradiance at the shallower depth `z1`. Numeric vector or
  `lux_spectrum`. When `E1` is a `lux_spectrum`, S3 dispatch handles
  both arguments; passing a numeric `E1` with a `lux_spectrum` `E2` is
  not supported. Two `lux_spectrum` inputs must both be spectral
  irradiance on the same wavelength grid; they are converted to a common
  unit before the ratio is taken. Numeric values must be finite and
  positive.

- ...:

  Ignored.

- z1:

  Depth of E1 in metres. Must be \< z2.

- E2:

  Irradiance at the deeper depth `z2`. Numeric vector or `lux_spectrum`.
  It must be a `lux_spectrum` exactly when `E1` is one; mixing the two
  is an error.

- z2:

  Depth of E2 in metres. Must be \> z1.

## Value

Kd in 1/m. Same length as E1/E2. Vector arguments must have equal
lengths or length 1.

## References

Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems, 2nd edn.
Cambridge University Press.

## See also

[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md),
[`attenuate_spectrum`](https://johnkirwan.github.io/luxR/reference/attenuate_spectrum.md),
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)

## Examples

``` r
data(Naples)
fit_Kd(sum(Naples$depth_0m), 0, sum(Naples$depth_10m), 10)
#> [1] 0.1147068
```
