# Heuristic horizontal visual-range estimate in water.

Applies the Koschmieder–Berek law to estimate the maximum horizontal
sighting distance in water: \\V = -\ln(C_t) / c\\ where \\C_t\\ is the
inherent contrast threshold and \\c\\ is the beam attenuation
coefficient. Because \\c\\ is rarely measured directly, a conversion
factor `kd_to_c` maps diffuse attenuation Kd to \\c\\.

## Usage

``` r
visual_range(Kd, contrast_threshold = 0.02, kd_to_c = 1.5, beam_c = NULL)
```

## Arguments

- Kd:

  Diffuse attenuation coefficient in 1/m (scalar or vector).

- contrast_threshold:

  Inherent contrast threshold of the visual system or camera
  (dimensionless, typically 0.01–0.05). Default 0.02.

- kd_to_c:

  Ratio \\c / K_d\\. Typical values: 1.2–1.5 for clear oceanic water,
  2–4 for coastal/turbid water. Default 1.5. Ignored when `beam_c` is
  supplied.

- beam_c:

  Optional measured beam attenuation coefficient \\c\\ (1/m), e.g. from
  [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md).
  When supplied it is used directly instead of the `Kd * kd_to_c`
  approximation.

## Value

Heuristic visual-range estimate in metres. Same length as `Kd`.

## Details

This is a contrast-threshold scenario estimate, not an empirically
validated prediction of detection by a particular observer or camera.

The coefficient that governs horizontal sighting distance is the beam
attenuation coefficient \\c\\, not the diffuse attenuation \\K_d\\
(Johnsen 2012, ch. 5: as you move away from an object, veiling light
replaces it at a rate equal to \\c\\). If `beam_c` is not given, this
function approximates \\c = K_d \times\\ `kd_to_c`. Note that \\c \>
K_d\\ always, so treating \\K_d\\ as \\c\\ (`kd_to_c = 1`) is an upper
bound that overestimates range. The model assumes **horizontal**
viewing; for an upward-looking observer the effective coefficient is
\\c - K_L\\ (smaller, so ranges are longer), which is not modelled here.

## References

Duntley SQ (1963) Light in the sea. J. Opt. Soc. Am. 53:214–233.

Zaneveld JRV, Pegau WS (2003) Robust underwater visibility parameter.
Opt. Express 11:2997–3009.

Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
Nature. Princeton University Press. (Ch. 5: sighting distance and
\\c\\.)

## Examples

``` r
# Visual range for Jerlov IA water at 490 nm
visual_range(jerlov_Kd("IA", lambda = 490))
#> [1] 120.7415

# Compare water types
types <- c("I", "IA", "II", "C2")
sapply(types, function(t) visual_range(jerlov_Kd(t, lambda = 490)))
#>          I         IA         II         C2 
#> 140.215878 120.741451  49.207837   6.136507 
```
