# Fraction of downwelling irradiance transmitted across the water surface.

The fraction of above-surface downwelling irradiance that enters the
water after Fresnel reflection at a flat air-water interface — the
surface term of an above-vs-below-water light budget:
\\E\_{\text{below}} \approx \tau\\E\_{\text{above}}\\ (Johnsen 2012, ch.
5).

## Usage

``` r
surface_transmittance(angle = NULL, n = 1.333, source = c("direct", "diffuse"))
```

## Arguments

- angle:

  Solar/incidence angle from the surface normal, in degrees (0-90).
  Required for `source = "direct"`; ignored for `"diffuse"`.

- n:

  Refractive index of water relative to air. Default 1.333.

- source:

  `"direct"` (collimated beam at `angle`) or `"diffuse"` (isotropic
  sky).

## Value

Transmitted fraction of downwelling irradiance (0-1).

## Details

For a `"direct"` (collimated, e.g. solar-beam) source at a given
incidence angle, \\\tau = 1 - R(\theta)\\. For a `"diffuse"` (isotropic
sky) source it is the cosine-weighted hemispherical average of \\1 -
R(\theta)\\, about 0.93 for seawater (i.e. ~7% is reflected). This is
the planar-irradiance transmittance; in-water *radiance* is additionally
boosted by \\n^2\\ because the refracted beam is compressed into
[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md).

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`fresnel_reflectance`](https://johnkirwan.github.io/luxR/reference/fresnel_reflectance.md),
[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md)

## Examples

``` r
surface_transmittance(angle = 0)              # overhead sun: ~0.98
#> [1] 0.9796268
surface_transmittance(source = "diffuse")     # isotropic sky: ~0.93
#> [1] 0.9335942
```
