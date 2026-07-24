# Beer-Lambert attenuation at a single wavelength.

Computes E(z) = E0 \* exp(-Kd \* z). Vectorised over `depth`.

## Usage

``` r
attenuate_depth(E0, Kd, depth)
```

## Arguments

- E0:

  Surface irradiance. Any unit; result is in the same unit.

- Kd:

  Diffuse attenuation coefficient in 1/m. Must be \>= 0.

- depth:

  Depth(s) in metres. Must be \>= 0. Scalar or vector.

## Value

Numeric vector the same length as `depth`.

## Details

This is the package's principal lightweight water-column model. It
assumes that \\K_d\\ is constant over the modeled path and propagates
each wavelength independently. It does not solve the angular radiance
field, multiple scattering, or wavelength redistribution. The scalar API
has no inherent wavelength or depth range; the caller is responsible for
supplying a \\K_d\\ that is valid for the medium and path.

## Examples

``` r
attenuate_depth(100, Kd = 0.06, depth = c(0, 10, 25, 50))
#> [1] 100.000000  54.881164  22.313016   4.978707
```
