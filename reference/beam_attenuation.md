# Beam attenuation coefficient from absorption and scattering.

The beam (total) attenuation coefficient is the sum of the absorption
and scattering coefficients, \\c = a + b\\ (Johnsen 2012, ch. 5). It
governs how a collimated beam — and the contrast of a sighted object —
fades with distance, and is always larger than the diffuse attenuation
\\K_d\\.

## Usage

``` r
beam_attenuation(absorption, scattering)
```

## Arguments

- absorption:

  Absorption coefficient \\a\\ (1/m). Vectorised.

- scattering:

  Scattering coefficient \\b\\ (1/m). Vectorised.

## Value

Beam attenuation coefficient \\c\\ (1/m).

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`single_scattering_albedo`](https://johnkirwan.github.io/luxR/reference/single_scattering_albedo.md),
[`transmittance`](https://johnkirwan.github.io/luxR/reference/transmittance.md),
[`visual_range`](https://johnkirwan.github.io/luxR/reference/visual_range.md)

## Examples

``` r
beam_attenuation(absorption = 0.1, scattering = 0.05)   # 0.15
#> [1] 0.15
```
