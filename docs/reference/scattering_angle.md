# Angle between a line of sight and the solar beam

The angle \\\Theta\\ between two directions given as (zenith, azimuth):
\$\$\cos\Theta = \cos\theta_1\cos\theta_2 +
\sin\theta_1\sin\theta_2\cos(\phi_1 - \phi_2).\$\$ For the
single-scattering polarization model this is the relevant scattering
angle (the degree of polarization peaks near \\\Theta = 90^\circ\\).

## Usage

``` r
scattering_angle(view_zenith, view_azimuth, sun_zenith, sun_azimuth)
```

## Arguments

- view_zenith, view_azimuth:

  Viewing direction in degrees.

- sun_zenith, sun_azimuth:

  Solar-beam direction in degrees (use
  [`refracted_solar_angle`](https://johnkirwan.github.io/luxR/reference/refracted_solar_angle.md)
  for the in-water zenith).

## Value

Angle in degrees, `[0, 180]`. Vectorised over its arguments.

## See also

[`underwater_polarization`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)

## Examples

``` r
scattering_angle(view_zenith = 90, view_azimuth = 0,
                 sun_zenith = 0,  sun_azimuth = 0)   # 90
#> [1] 90
```
