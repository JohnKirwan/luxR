# Refracted zenith angle of the sun beneath the surface

Snell's-law refraction of the solar beam entering water: \\\theta_w =
\arcsin(\sin\theta\_{air} / n)\\. As the in-air zenith approaches 90
degrees the refracted angle approaches the edge of Snell's window (about
48.6 degrees for `n = 1.333`); see
[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md).

## Usage

``` r
refracted_solar_angle(sun_zenith, n = 1.333)
```

## Arguments

- sun_zenith:

  In-air solar zenith angle in degrees, `[0, 90]`.

- n:

  Refractive index of water. Default 1.333.

## Value

Refracted (in-water) solar zenith angle in degrees. Vectorised.

## See also

[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md),
[`underwater_polarization`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)

## Examples

``` r
refracted_solar_angle(0)    # 0
#> [1] 0
refracted_solar_angle(90)   # ~48.6 (edge of Snell's window)
#> [1] 48.60663
```
