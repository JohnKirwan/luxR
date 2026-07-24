# Example downwelling irradiance from Mare Chiaro, Gulf of Naples

A small set of downwelling spectral irradiance measurements made at
three depths at Mare Chiaro in the Gulf of Naples, Italy. This is
**example field data** — a single site on particular days — provided to
illustrate working with measured spectra; it is not a general reference
spectrum (cf. the ASTM
[`solar_spectra`](https://johnkirwan.github.io/luxR/reference/solar_spectra.md)).
Values are in micromol photons per square metre per second per nm
(umol/m^2/s/nm); wavelength bins are approximately 5 nm wide.

## Usage

``` r
Naples
```

## Format

A data frame with 103 rows and 4 columns:

- wv:

  Bin-centre wavelength in nm.

- depth_0m:

  Irradiance at the surface (0 m depth).

- depth_5m:

  Irradiance at 5 m depth.

- depth_10m:

  Irradiance at 10 m depth.

## Source

Field measurements of downwelling spectral irradiance at Mare Chiaro,
Gulf of Naples, Italy, attributed to M. J. Bok and J. D. Kirwan (2021,
unpublished data). The bundled object is regenerated from an explicitly
labelled legacy canonical snapshot; original acquisition metadata and
redistribution terms are not documented.

## Examples

``` r
data(Naples)
irradiance2lux(Naples$depth_0m, Naples$wv, photonic = TRUE, molar_unit = "umol")
#> [1] 24725.63
```
