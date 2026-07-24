# Scenario estimate of object-background threshold-crossing distance.

Generalises
[`visual_range`](https://johnkirwan.github.io/luxR/reference/visual_range.md)
by using the estimated inherent contrast of an object against its
background (from
[`inherent_contrast`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md))
rather than assuming a contrast of 1. The default scalar heuristic uses
\\r = \ln(\|C_0\| / \text{threshold}) / c\_{\mathrm{eff}}\\. The
spectral-path model instead propagates object, background, and veiling
radiances at every wavelength and recomputes receptor catches at each
evaluated distance.

## Usage

``` r
detection_range(
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

A list with elements `achromatic` and `chromatic` giving scenario
estimates in metres. A value is 0 when no evaluated distance is
detectable, `NA` when the channel was not requested or remained
detectable through `max_distance`. Attributes record per-channel status,
model, validation state, and maximum distance.

## Details

Neither model is an empirically validated prediction of actual
organismal detection distance. They omit target angular size, acuity,
photon limitation, adaptation changes, behaviour, and observation
probability.

The spectral-path scenario treats object and background as coplanar
stimuli sharing one water path and one asymptotic veiling radiance. For
each stimulus it evaluates \$\$L(r, \lambda) = L_v(\lambda) +
\[L_0(\lambda) - L_v(\lambda)\] e^{-c\_{\mathrm{eff}}(\lambda) r}.\$\$
Both stimuli therefore converge toward the supplied veiling spectrum.
This is a lightweight single-path model, not a multiple-scattering
radiative-transfer solution. Because wavelength-dependent signals can be
non-monotonic, the reported spectral distance is the furthest downward
threshold crossing bracketed by `search_points`; callers should check
resolution sensitivity.

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.

## See also

[`inherent_contrast`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
[`contrast_at_distance`](https://johnkirwan.github.io/luxR/reference/contrast_at_distance.md),
[`visual_range`](https://johnkirwan.github.io/luxR/reference/visual_range.md)

## Examples

``` r
sp   <- solar_irradiance("clear_noon")
lam  <- sp$wavelength
grey <- rep(0.3, length(lam))
red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
Kd   <- jerlov_Kd("IA", lambda = 490)
detection_range(red, grey, sp$irradiance, lam, Kd = Kd, species = "Danio rerio")
#> $achromatic
#> [1] 70.0432
#> 
#> $chromatic
#> [1] 36.66406
#> 
#> attr(,"status")
#> achromatic  chromatic 
#>  "crossed"  "crossed" 
#> attr(,"model")
#> [1] "scalar_heuristic"
#> attr(,"validation")
#> [1] "scenario estimate; not empirically validated"
#> attr(,"max_distance")
#> [1] 1000
```
