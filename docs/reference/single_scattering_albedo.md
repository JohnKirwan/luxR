# Single-scattering albedo.

The fraction of beam attenuation due to scattering rather than
absorption, \\\omega_0 = b / (a + b) = b / c\\ (Johnsen 2012, ch. 5).
Values near 1 indicate a strongly scattering, weakly absorbing medium
(e.g. fog or milk); values near 0 a strongly absorbing one.

## Usage

``` r
single_scattering_albedo(absorption, scattering)
```

## Arguments

- absorption:

  Absorption coefficient \\a\\ (1/m). Vectorised.

- scattering:

  Scattering coefficient \\b\\ (1/m). Vectorised.

## Value

Single-scattering albedo \\\omega_0\\ (dimensionless, 0-1).

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`beam_attenuation`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)

## Examples

``` r
single_scattering_albedo(absorption = 0.1, scattering = 0.05)   # 0.333
#> [1] 0.3333333
```
