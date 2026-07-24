# Snell's window half-angle.

Underwater, the entire above-water hemisphere is refracted into a cone —
the "Snell's window" or "optical manhole" — of half-angle \\\theta_c =
\arcsin(1/n)\\ (Johnsen 2012, ch. 5). For seawater (\\n \approx 1.333\\)
this is about 48.6 degrees, so the whole sky is compressed into a ~97
degree cone overhead.

## Usage

``` r
snells_window(n = 1.333)
```

## Arguments

- n:

  Refractive index of the water relative to air. Default 1.333.
  Vectorised.

## Value

Half-angle of Snell's window, in degrees.

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`fresnel_reflectance`](https://johnkirwan.github.io/luxR/reference/fresnel_reflectance.md),
[`wavelength_in_medium`](https://johnkirwan.github.io/luxR/reference/wavelength_in_medium.md)

## Examples

``` r
snells_window()        # ~48.6 degrees
#> [1] 48.60663
```
