# Object-vs-background detection summary.

One-stop wrapper that bundles
[`inherent_contrast`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
[`detection_range`](https://johnkirwan.github.io/luxR/reference/detection_range.md),
and a contrast-vs-distance curve into a single `lux_detection` object
with `print` and `plot` methods.

## Usage

``` r
detectability(
  object,
  background,
  illuminant,
  lambda,
  Kd,
  kd_to_c = 1.5,
  species = NULL,
  receptor = NULL,
  channel = c("both", "achromatic", "chromatic"),
  contrast_threshold = 0.02,
  jnd_threshold = 1,
  direction = c("horizontal", "up", "down"),
  noise = 0.05,
  distances = NULL,
  binwidth = NULL,
  beam_c = NULL,
  model = c("scalar_heuristic", "spectral_path"),
  veiling = NULL,
  max_distance = 1000,
  search_points = 1001L,
  geometry = c("lambertian", "scalar", "collimated", "custom"),
  solid_angle = NULL
)
```

## Arguments

- object, background:

  Reflectance spectra (numeric vectors on the `lambda` grid, or
  dimensionless reflectance `lux_spectrum` objects). Values must be
  finite and in \[0, 1\].

- illuminant:

  The in-water light field illuminating both (numeric vector or
  irradiance `lux_spectrum` in W/m2/nm); e.g. a depth-propagated solar
  spectrum. Values must be finite and non-negative.

- lambda:

  Finite, positive, strictly increasing, regularly spaced wavelength
  grid in nm.

- Kd:

  Positive diffuse attenuation coefficient (1/m). The scalar heuristic
  requires one value at the sighting wavelength, e.g.
  `jerlov_Kd("IA", lambda = 490)`. The spectral-path model accepts one
  value or one value per wavelength.

- kd_to_c:

  Ratio \\c / K_d\\. Default 1.5. Ignored when `beam_c` is supplied.

- species:

  Species name in `species_sensitivities`. Required for the chromatic
  channel. For the achromatic channel, a species must have a cited
  default in
  [`species_channels`](https://johnkirwan.github.io/luxR/reference/species_channels.md).
  If `NULL`, achromatic brightness is explicitly treated as total photon
  radiance without a species visual model.

- receptor:

  Receptor class(es) to include. Default `NULL` uses the complete
  validated default for each requested species channel. An explicit
  selection must be valid for every requested channel.

- channel:

  `"both"` (default), `"achromatic"`, or `"chromatic"`.

- contrast_threshold:

  Achromatic Weber-contrast threshold. Default 0.02.

- jnd_threshold:

  Chromatic threshold in JNDs. Default 1.

- direction:

  Viewing direction: `"horizontal"` (default), `"up"`, or `"down"`.

- noise:

  Receptor Weber fraction(s) for the chromatic channel; passed to
  [`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md).
  Default 0.05.

- distances:

  Optional distance grid (m) for the contrast-vs-distance curve. Default
  spans 0 to 1.2x the largest detection range.

- binwidth:

  Bin width in nm; inferred from `lambda` if `NULL`.

- beam_c:

  Optional measured beam attenuation \\c\\ (1/m), e.g. from
  [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md),
  used instead of `Kd * kd_to_c`. For the spectral-path model this is
  required and must have one value per wavelength.

- model:

  `"scalar_heuristic"` (default) or `"spectral_path"`. The former
  exponentially attenuates a scalar contrast/JND. The latter propagates
  wavelength-resolved radiances and recomputes receptor catches.

- veiling:

  Veiling/path radiance spectrum on the `lambda` grid. Required for the
  spectral-path model, in the radiance scale produced from `illuminant`
  by `geometry` (normally W m-2 sr-1 nm-1).

- max_distance:

  Finite positive maximum search distance in metres. A criterion still
  detectable there is reported as censored, not infinite.

- search_points:

  Integer number of distances used to bracket the furthest downward
  threshold crossing in the spectral-path model. Default 1001.

- geometry:

  Irradiance-to-radiance geometry used by the spectral-path model:
  `"lambertian"` (default), `"scalar"`, `"collimated"`, or `"custom"`.
  See
  [`irradiance2radiance`](https://johnkirwan.github.io/luxR/reference/irradiance2radiance.md).

- solid_angle:

  Solid angle in steradians when `geometry = "custom"`.

## Value

An object of class `lux_detection`: a list with `inherent`
(zero-distance contrast), `range` (scenario estimate per channel),
`curve` (data frame of contrast vs distance), status metadata, and the
call settings.

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`inherent_contrast`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
[`detection_range`](https://johnkirwan.github.io/luxR/reference/detection_range.md),
[`contrast_at_distance`](https://johnkirwan.github.io/luxR/reference/contrast_at_distance.md)

## Examples

``` r
sp   <- solar_irradiance("clear_noon")
lam  <- sp$wavelength
grey <- rep(0.3, length(lam))
red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
d <- detectability(red, grey, sp$irradiance, lam,
                   Kd = jerlov_Kd("IA", lambda = 490), species = "Danio rerio")
d
#> <lux_detection> horizontal viewing, Danio rerio 
#>   model: scalar contrast/JND heuristic scenario estimate 
#>   validation: not empirically validated as an actual detection range
#>   achromatic: C0 = -0.193 (Weber)   -> estimate 70.04 m  (thr 0.020; crossed)
#>   chromatic : dS = 3.280 JND        -> estimate 36.66 m  (thr 1.00 JND; crossed)
if (FALSE) plot(d) # \dontrun{}
```
