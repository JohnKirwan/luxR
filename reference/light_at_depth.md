# In-water downwelling spectral irradiance at a single depth.

Convenience wrapper that takes one of the bundled reference solar
spectra, converts it to \\W\\m^{-2}\\nm^{-1}\\, and propagates it from
its recorded reference depth to a single absolute depth in a Jerlov
water type via
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)
and
[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md).
This is the "solar condition + water type + depth -\> spectrum at depth"
operation the Shiny app's colour-discrimination and detection tabs
share.

## Usage

``` r
light_at_depth(
  condition = "clear_noon",
  water_type = "IA",
  depth = 0,
  surface_source = c("direct", "diffuse"),
  surface_angle = 30,
  refractive_index = 1.333,
  wavelength_policy = c("error", "trim", "constant")
)
```

## Arguments

- condition:

  Solar condition passed to
  [`from_solar`](https://johnkirwan.github.io/luxR/reference/from_solar.md)
  (e.g. `"clear_noon"`). Default `"clear_noon"`.

- water_type:

  Jerlov water type passed to
  [`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)
  (e.g. `"IA"`). Default `"IA"`.

- depth:

  Absolute target depth in metres below the water surface. Must be
  length-1, non-negative, and not shallower than an in-water source's
  recorded reference depth. Default 0 (surface).

- surface_source:

  Surface illumination model used when `condition` is referenced in air:
  `"direct"` (default) or `"diffuse"`.

- surface_angle:

  Incidence angle in degrees from the surface normal for
  `surface_source = "direct"`. Default 30, matching the worked vignette.

- refractive_index:

  Refractive index of water relative to air used by the Fresnel surface
  model. Default 1.333.

- wavelength_policy:

  Policy for source wavelengths outside the bundled Jerlov domain
  (350–700 nm): `"error"` (default) fails, `"trim"` explicitly restricts
  the calculation to the supported intersection, and `"constant"`
  explicitly extends endpoint Kd values.

## Value

A data frame with columns `lambda` (nm) and `irradiance` (downwelling
spectral irradiance at `depth`, in \\W\\m^{-2}\\nm^{-1}\\). The
`"luxR.jerlov"` attribute records the wavelength policy and data
provenance.

## Details

An above-surface source is multiplied by
[`surface_transmittance`](https://johnkirwan.github.io/luxR/reference/surface_transmittance.md)
before water-column attenuation. The default is a flat interface and
direct illumination incident 30 degrees from vertical. An in-water
source is unchanged when `depth` equals its reference depth. For deeper
targets, only the additional water-column distance is applied. Shallower
targets are rejected because reconstructing them would require an
explicit inverse-propagation model. Water-column propagation is the
lightweight spectral Beer-Lambert model: it assumes a depth-invariant
Jerlov \\K_d(\lambda)\\, propagates wavelength bins independently, and
is not a multiple-scattering or angular radiative-transfer calculation.
No universal maximum depth is implied; the selected water type must
remain representative of the whole path.

## See also

[`from_solar`](https://johnkirwan.github.io/luxR/reference/from_solar.md),
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md),
[`propagate_spectrum`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md)

## Examples

``` r
head(light_at_depth("clear_noon", "IA", depth = 5,
                    wavelength_policy = "trim"))
#>   lambda irradiance
#> 1    350  0.5955896
#> 2    360  0.7990427
#> 3    370  0.9279117
#> 4    380  0.8892820
#> 5    390  0.8278967
#> 6    400  0.8297179
```
