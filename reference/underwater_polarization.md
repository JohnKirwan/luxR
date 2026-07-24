# Tunable Rayleigh-like approximation to underwater polarization

A lightweight, analytic single-scattering model of linear polarization
in the water column. The degree of polarization follows the
Rayleigh-like form \$\$DoP(\Theta) = DoP\_{max}\\\frac{\sin^2\Theta}{1 +
\cos^2\Theta},\$\$ where \\\Theta\\ is the scattering angle between the
line of sight and the refracted solar beam
([`scattering_angle`](https://johnkirwan.github.io/luxR/reference/scattering_angle.md));
polarization is maximal at \\\Theta = 90^\circ\\ and vanishes toward the
sun and anti-sun. With depth, multiple scattering randomizes the field,
so the model relaxes toward an asymptotic floor: \$\$DoP(z) =
DoP\_{asym} + (DoP(\Theta) - DoP\_{asym})\\e^{-z/z_p}.\$\$ The e-vector
(angle of polarization) is perpendicular to the scattering plane.

## Usage

``` r
underwater_polarization(
  view_zenith,
  view_azimuth = 0,
  sun_zenith,
  sun_azimuth = 0,
  depth = 0,
  dop_max = 0.4,
  dop_asym = 0.03,
  z_p = 20,
  n = 1.333
)
```

## Arguments

- view_zenith, view_azimuth:

  Viewing direction in degrees (zenith: 0 = up, 90 = horizontal, 180 =
  down). Vectorised. Scalars are broadcast; implicit partial recycling
  is rejected.

- sun_zenith:

  In-air solar zenith angle in degrees. Refracted internally via
  [`refracted_solar_angle`](https://johnkirwan.github.io/luxR/reference/refracted_solar_angle.md).

- sun_azimuth:

  Solar azimuth in degrees. Default 0.

- depth:

  Depth in metres (\\\geq 0\\). Default 0.

- dop_max:

  Maximum (surface, 90-degree-scattering) degree of polarization.
  Default 0.4 is an illustrative value at the upper end of the
  approximately 0.25–0.40 maxima reported at 15 m in clear tropical
  marine water by Cronin and Shashar (2001). Because this model defines
  `dop_max` at depth zero, that observation does not constitute a
  calibration of the default. The value is not transferable to other
  water types.

- dop_asym:

  Asymptotic deep-field degree of polarization. Default 0.03 is a
  heuristic illustrative floor, not an empirically calibrated constant.

- z_p:

  Depth scale (m) over which DoP relaxes toward `dop_asym`. Default 20
  is a heuristic illustrative scale, not an empirical attenuation
  length. Site-specific use requires calibration.

- n:

  Refractive index of water. Default 1.333 is a conventional visible-
  light approximation. Refractive index varies with wavelength,
  temperature, and salinity.

## Value

A data frame with one row per viewing direction and columns
`scattering_angle` (deg), `dop` (0–1), and `aop` (deg, `(-90, 90]`; `NA`
when looking along the solar beam). The data frame has a
`"luxR.polarization"` attribute recording model status, model version,
parameters, and the validity statement.

## Details

This is an explicitly uncalibrated, first-order approximation for
teaching, geometry exploration, and field intuition. It is not a vector
radiative-transfer solution and must not be interpreted as a
quantitative prediction without calibration to measurements from the
relevant site, wavelength, water type, surface state, and viewing
geometry. It omits the wavelength dependence of scattering and
refraction, particulate and dissolved constituents, surface waves and
polarized skylight, bottom reflection, and a physical
multiple-scattering calculation.

## References

Cronin TW, Shashar N (2001) The linearly polarized light field in clear,
tropical marine waters. Journal of Experimental Biology 204:2461-2467.

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 8.

## See also

[`degree_of_polarization`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md),
[`scattering_angle`](https://johnkirwan.github.io/luxR/reference/scattering_angle.md),
[`refracted_solar_angle`](https://johnkirwan.github.io/luxR/reference/refracted_solar_angle.md),
[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md)

## Examples

``` r
# DoP across viewing zenith with the sun overhead, near the surface:
underwater_polarization(view_zenith = seq(0, 90, 15), view_azimuth = 0,
                        sun_zenith = 0, depth = 1)
#>   scattering_angle         dop aop
#> 1                0 0.001463117  NA
#> 2               15 0.014648812  90
#> 3               30 0.055819084  90
#> 4               45 0.128293707  90
#> 5               60 0.229758179  90
#> 6               75 0.334179031  90
#> 7               90 0.381954887  90
```
