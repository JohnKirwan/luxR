# Secchi depth from diffuse attenuation coefficient(s).

Estimates the Secchi disk visibility depth using the Tyler (1968)
approximation \\z_S \approx 1.7 / K_d\\. When a spectral irradiance is
supplied the function first computes an irradiance-weighted mean Kd
across 400–700 nm before applying the approximation.

## Usage

``` r
secchi_depth(
  Kd,
  lambda = NULL,
  irradiance = NULL,
  spectrum = NULL,
  photonic = FALSE,
  basis = c("photon", "energy")
)
```

## Arguments

- Kd:

  Diffuse attenuation coefficient(s) in 1/m, all positive.

- lambda:

  Optional wavelength vector (nm) matching `Kd`.

- irradiance:

  Optional non-negative spectral irradiance matching `lambda`; supply
  with `lambda`.

- spectrum:

  Optional `lux_spectrum`; when supplied its `E` and `lambda` slots
  replace the `irradiance` and `lambda` arguments. Its unit is read from
  the object; setting `photonic` as well is an error.

- photonic:

  Logical. `FALSE` (default): numeric `irradiance` is in energy units
  (e.g. W m\\^{-2}\\ nm\\^{-1}\\). `TRUE`: it is a photon or molar flux
  per nm.

- basis:

  `"photon"` (default) or `"energy"`: what weights Kd.

## Value

Secchi depth in metres.

## Details

By default Kd is weighted by photon flux, because vision responds to
photons absorbed. Use `basis = "energy"` to weight by radiant energy;
this gives more weight to short wavelengths.

Each sample is a bin centred on its wavelength on a regular grid; a bin
straddling 400 or 700 nm is weighted by its part inside the window.

## References

Tyler JE (1968) Limnol. Oceanogr. 13:1-6. Preisendorfer RW (1986)
Limnol. Oceanogr. 31:909-926.

## See also

[`visual_range`](https://johnkirwan.github.io/luxR/reference/visual_range.md),
[`jerlov_Kd`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md),
[`photic_depth`](https://johnkirwan.github.io/luxR/reference/photic_depth.md)

## Examples

``` r
secchi_depth(jerlov_Kd("IA", lambda = 490))
#> [1] 78.7037
```
