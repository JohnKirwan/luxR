# Heuristic scalar contrast remaining after a sighting path through water.

Attenuates an inherent contrast over a horizontal (or vertical) viewing
path as a teaching/scenario heuristic: \\C(r) = C_0 \\
e^{-c\_{\mathrm{eff}} r}\\ (Johnsen 2012, ch. 5). The beam attenuation
\\c\\ is approximated as `Kd * kd_to_c`; looking up uses \\c - K_d\\ and
looking down \\c + K_d\\.

## Usage

``` r
contrast_at_distance(
  C0,
  distance,
  Kd,
  kd_to_c = 1.5,
  direction = c("horizontal", "up", "down"),
  beam_c = NULL
)
```

## Arguments

- C0:

  Inherent (zero-distance) contrast (achromatic Weber contrast or
  chromatic \\\Delta S\\). Scalar or vector.

- distance:

  Finite, non-negative viewing distance(s) in metres. Scalar or vector.

- Kd:

  Diffuse attenuation coefficient at the sighting wavelength (1/m).

- kd_to_c:

  Ratio \\c / K_d\\. Default 1.5. See
  [`visual_range`](https://johnkirwan.github.io/luxR/reference/visual_range.md).
  Ignored when `beam_c` is supplied.

- direction:

  Viewing direction: `"horizontal"` (default), `"up"`, or `"down"`.

- beam_c:

  Optional measured beam attenuation \\c\\ (1/m), e.g. from
  [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md),
  used instead of `Kd * kd_to_c`. `Kd` is still used for the
  `"up"`/`"down"` corrections.

## Value

Heuristic contrast remaining at each distance.

## Details

This scalar calculation does not propagate spectra or recompute receptor
catches. In particular, applying it to a chromatic JND is not a
validated chromatic-vision model; use
`detection_range(model = "spectral_path")` for wavelength-resolved
propagation.

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`inherent_contrast`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
[`detection_range`](https://johnkirwan.github.io/luxR/reference/detection_range.md)

## Examples

``` r
contrast_at_distance(C0 = 1, distance = c(0, 5, 10), Kd = 0.06)
#> [1] 1.0000000 0.6376282 0.4065697
```
