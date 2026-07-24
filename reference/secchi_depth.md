# Secchi depth from diffuse attenuation coefficient(s).

Estimates the Secchi disk visibility depth using the Tyler (1968)
approximation \\z_S \approx 1.7 / K_d\\. When a spectral irradiance is
supplied the function first computes an irradiance-weighted mean Kd
across the visible range before applying the approximation.

## Usage

``` r
secchi_depth(Kd, lambda = NULL, irradiance = NULL, spectrum = NULL)
```

## Arguments

- Kd:

  Diffuse attenuation coefficient(s) in 1/m.

- lambda:

  Optional wavelength vector (nm) matching `Kd`.

- irradiance:

  Optional spectral irradiance for PAR-weighted mean Kd.

- spectrum:

  Optional `lux_spectrum`; when supplied its `E` and `lambda` slots
  replace the `irradiance` and `lambda` arguments.

## Value

Secchi depth in metres.

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
