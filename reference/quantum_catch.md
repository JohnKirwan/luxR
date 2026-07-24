# Sensitivity-weighted photon irradiance.

Computes \\Q_w = \sum E_p(\lambda) S(\lambda) \Delta\lambda\\, where
\\E_p\\ is spectral photon irradiance and \\S\\ is a dimensionless
sensitivity or absorptance curve. The result is a photon irradiance
weighted by the supplied curve, not an absolute photon rate for one
receptor.

## Usage

``` r
quantum_catch(
  irradiance,
  lambda,
  S,
  input_unit = NULL,
  total = TRUE,
  binwidth = NULL
)
```

## Arguments

- irradiance:

  Non-negative spectral irradiance vector, one value per wavelength bin,
  in the exact unit declared by `input_unit`.

- lambda:

  Wavelength bin centres in nm.

- S:

  Spectral sensitivity: a data frame with columns `lambda` and `S`
  (normalised 0–1). Accepts output of
  [`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
  or
  [`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  directly.

- input_unit:

  Exact unit of `irradiance`. One of `"W/m2/nm"`, `"photon/m2/s/nm"`,
  `"mol/m2/s/nm"`, `"mmol/m2/s/nm"`, or `"umol/m2/s/nm"`. Molar inputs
  are converted using the Avogadro constant.

- total:

  Logical; sum across wavelengths (default `TRUE`) or return per-bin
  contributions.

- binwidth:

  Wavelength bin width in nm. Inferred from `lambda` spacing if `NULL`
  (default).

## Value

A scalar (when `total = TRUE`) or numeric vector of integrated per-bin
contributions, in photons m^-2 s^-1.

## Details

All inputs are converted to raw photon counts before integration, so the
returned unit is photons m^-2 s^-1. With a normalised pigment template,
\\Q_w\\ is a relative sensitivity-weighted photon irradiance. With a
calibrated absorptance curve, it is absorbed photon irradiance per unit
collection area at the plane where `irradiance` was measured.

Calculating photons s^-1 receptor^-1 additionally requires receptor
collection area, the solid angle subtended by the source, ocular
transmission, and quantum efficiency. This function does not accept or
assume those quantities and therefore does not return an absolute
receptor rate. Sensitivity is assigned zero outside the wavelength range
supplied in `S`; endpoint values are not extrapolated.

## References

Kelber A, Vorobyev M, Osorio D (2003) Animal colour vision — behavioural
tests and physiological concepts. Biological Reviews 78:81–118.

## See also

[`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md),
[`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md),
[`species_brightness`](https://johnkirwan.github.io/luxR/reference/species_brightness.md),
[`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)

## Examples

``` r
lam <- Naples$wv
S   <- species_LEF("Danio rerio", receptor = "L-cone", lambda = lam)
quantum_catch(Naples$depth_0m, lam, S,
              input_unit = "umol/m2/s/nm")
#> [1] 1.178429e+20
```
