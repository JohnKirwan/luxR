# Convert a broadband scalar reading into a plausible spectrum.

Given a single measured value and a reference spectral shape, returns a
rescaled spectrum whose forward operator reproduces the input. The shape
assumption must be provided by the caller (e.g. from
[`solar_irradiance()`](https://johnkirwan.github.io/luxR/reference/solar_irradiance.md)).

## Usage

``` r
broadband2spectrum(
  value,
  unit = c("lx", "W", "kW", "umol", "radiance_W", "cd"),
  spectrum,
  water_type = NULL,
  depth = 0,
  wavelength_policy = c("error", "trim", "constant")
)
```

## Arguments

- value:

  The measured scalar (e.g. 18200 lux, 480 W, 1.2 kW).

- unit:

  One of `"lx"`, `"W"`, `"kW"`, `"umol"`, `"radiance_W"`, `"cd"`.

- spectrum:

  Reference spectral shape as a data frame with columns `wavelength` and
  `irradiance`.

- water_type:

  Optional Jerlov water type string (e.g. `"IA"`). If supplied, the
  reference shape is pre-attenuated to `depth` before rescaling — use
  when the measurement was taken at depth.

- depth:

  Depth in metres at which the measurement was taken. Only used when
  `water_type` is not `NULL`. Default 0.

- wavelength_policy:

  Policy for wavelengths outside the bundled Jerlov domain when
  attenuation is requested: `"error"` (default), explicit restriction to
  the supported intersection with `"trim"`, or explicit constant
  endpoint extension with `"constant"`.

## Value

A data frame with columns `wavelength` and `irradiance`, with a
`luxR.assumption` attribute recording the provenance.

## Details

Supported units and their forward operators:

- `"lx"`:

  photopic integral via
  [`irradiance2lux()`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md)

- `"W"`:

  broadband integral \\\sum E \cdot \Delta\lambda\\

- `"kW"`:

  same as `"W"` divided by 1000

- `"umol"`:

  PAR-band photon flux (400–700 nm) in \\\mu\\mol/s/m^2

- `"radiance_W"`:

  Lambertian radiance: \\E = \pi L\\, then integrate

- `"cd"`:

  photometric radiance: \\L = \text{lux} / \pi\\

## Examples

``` r
lam  <- seq(400, 700, by = 10)
spec <- data.frame(wavelength = lam, irradiance = rep(1, length(lam)))
broadband2spectrum(480, unit = "W", spectrum = spec)
#>    wavelength irradiance
#> 1         400   1.548387
#> 2         410   1.548387
#> 3         420   1.548387
#> 4         430   1.548387
#> 5         440   1.548387
#> 6         450   1.548387
#> 7         460   1.548387
#> 8         470   1.548387
#> 9         480   1.548387
#> 10        490   1.548387
#> 11        500   1.548387
#> 12        510   1.548387
#> 13        520   1.548387
#> 14        530   1.548387
#> 15        540   1.548387
#> 16        550   1.548387
#> 17        560   1.548387
#> 18        570   1.548387
#> 19        580   1.548387
#> 20        590   1.548387
#> 21        600   1.548387
#> 22        610   1.548387
#> 23        620   1.548387
#> 24        630   1.548387
#> 25        640   1.548387
#> 26        650   1.548387
#> 27        660   1.548387
#> 28        670   1.548387
#> 29        680   1.548387
#> 30        690   1.548387
#> 31        700   1.548387
```
