# Fresnel reflectance at the air-water interface.

Unpolarised Fresnel reflectance for light crossing a flat air-water
boundary, as a function of incidence angle (Johnsen 2012, ch. 5). At
normal incidence about 2% of downwelling light is reflected (\\R =
((n-1)/(n+1))^2\\). Going from water to air, total internal reflection
(\\R = 1\\) occurs beyond the critical angle (the edge of
[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md)).

## Usage

``` r
fresnel_reflectance(
  angle = 0,
  n = 1.333,
  from = c("air", "water"),
  component = c("unpolarized", "s", "p")
)
```

## Arguments

- angle:

  Angle of incidence from the surface normal, in degrees (0-90).
  Vectorised.

- n:

  Refractive index of water relative to air. Default 1.333.

- from:

  Incident medium: `"air"` (default) or `"water"`.

- component:

  Which polarization component to return: `"unpolarized"` (default; the
  mean of the two), `"s"` (perpendicular / TE), or `"p"` (parallel /
  TM). The difference between the s- and p-components is why reflection
  off water partially polarizes light (vanishing for the p-component at
  Brewster's angle).

## Value

Reflectance (0-1); the transmitted fraction is \\1 - R\\.

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`snells_window`](https://johnkirwan.github.io/luxR/reference/snells_window.md),
[`underwater_polarization`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)

## Examples

``` r
fresnel_reflectance(0)                       # ~0.02 at normal incidence
#> [1] 0.02037319
fresnel_reflectance(60, from = "water")      # total internal reflection -> 1
#> [1] 1
fresnel_reflectance(53.1, component = "p")   # ~0 near Brewster's angle
#> [1] 3.403873e-08
```
