# PAR irradiance from a spectral irradiance measurement.

Integrates spectral irradiance over the photosynthetically active range
400–700 nm and returns the result in µmol photons m\\^{-2}\\ s\\^{-1}\\.
Accepts energy units (W m\\^{-2}\\ nm\\^{-1}\\), raw photon counts, or a
`lux_spectrum` object in any supported unit.

## Usage

``` r
par_irradiance(irradiance, ...)

# S3 method for class 'numeric'
par_irradiance(irradiance, lambda, photonic = FALSE, binwidth = NULL, ...)

# S3 method for class 'lux_spectrum'
par_irradiance(irradiance, ...)
```

## Arguments

- irradiance:

  Spectral irradiance (W m\\^{-2}\\ nm\\^{-1}\\ or photons s\\^{-1}\\
  m\\^{-2}\\ nm\\^{-1}\\) at each bin, or a `lux_spectrum` object.

- ...:

  Ignored.

- lambda:

  Wavelength vector in nm (not needed for `lux_spectrum`).

- photonic:

  Logical. If `FALSE` (default), input is in W m\\^{-2}\\ nm\\^{-1}\\.
  If `TRUE`, input is in *raw* photon counts (photons m\\^{-2}\\
  s\\^{-1}\\ nm\\^{-1}\\), not molar units. For molar-unit
  (µmol/m²/s/nm) input, either wrap in a
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
  or convert to W/m²/nm first with
  [`n2W_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md).
  Note: `photonic = TRUE` means molar units in
  [`n2W_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md)
  and photon-or-molar units in
  [`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md).

- binwidth:

  Bin width in nm. Inferred from `lambda` if `NULL`.

## Value

Scalar PAR irradiance in µmol photons m\\^{-2}\\ s\\^{-1}\\.

## Details

PAR is the photon flux integrated over the photosynthetically active
range 400–700 nm, expressed in µmol photons m\\^{-2}\\ s\\^{-1}\\. When
input is in energy units (W m\\^{-2}\\ nm\\^{-1}\\), each bin is first
converted to photon flux via \\N = E\lambda/(hc)\\, then the total is
divided by Avogadro's constant scaled to µmol: \$\$Q\_{\mathrm{PAR}} =
\frac{1}{N_A \times 10^{-6}} \int\_{400}^{700}
\frac{E(\lambda)\\\lambda}{hc}\\d\lambda\$\$ where \\N_A = 6.022 \times
10^{23}\\ mol\\^{-1}\\ and \\hc = 1.98645 \times 10^{-16}\\ J nm. The
result is in µmol photons m\\^{-2}\\ s\\^{-1}\\.

## References

Thimijan RW, Heins RD (1983) HortScience 18:818-822.

## See also

[`par_fraction`](https://johnkirwan.github.io/luxR/reference/par_fraction.md),
[`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md),
[`band_irradiance`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)

## Examples

``` r
sp  <- solar_irradiance("clear_noon")
par_irradiance(sp$irradiance, sp$wavelength)
#> [1] 2197.756
```
