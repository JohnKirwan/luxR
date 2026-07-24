# Inherent (zero-distance) contrast of an object against its background.

Computes the contrast a viewer perceives between an object and its
background at zero viewing distance, from their reflectance spectra and
the in-water illuminant. Two channels are available: an **achromatic**
(brightness) Weber contrast and a **chromatic** distance (\\\Delta S\\,
in JNDs) from the Vorobyev-Osorio model. Object and background radiances
are formed as reflectance times illuminant.

## Usage

``` r
inherent_contrast(
  object,
  background,
  illuminant,
  lambda,
  species = NULL,
  receptor = NULL,
  noise = 0.05,
  channel = c("both", "achromatic", "chromatic"),
  binwidth = NULL
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

- noise:

  Receptor Weber fraction(s) for the chromatic channel; passed to
  [`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md).
  Default 0.05.

- channel:

  `"both"` (default), `"achromatic"`, or `"chromatic"`.

- binwidth:

  Bin width in nm; inferred from `lambda` if `NULL`.

## Value

A list with elements `achromatic` (Weber contrast) and `chromatic`
(\\\Delta S\\ in JNDs); unrequested channels are `NA`.

## References

Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
Nature. Princeton University Press. (Ch. 5: contrast and sighting
distance.)

## See also

[`contrast_at_distance`](https://johnkirwan.github.io/luxR/reference/contrast_at_distance.md),
[`detection_range`](https://johnkirwan.github.io/luxR/reference/detection_range.md),
[`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md),
[`weber_contrast`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md)

## Examples

``` r
sp  <- solar_irradiance("clear_noon")
lam <- sp$wavelength
grey <- rep(0.3, length(lam))
red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
inherent_contrast(red, grey, sp$irradiance, lam, species = "Danio rerio")
#> $achromatic
#> [1] -0.1934718
#> 
#> $chromatic
#> [1] 3.280236
#> 
```
