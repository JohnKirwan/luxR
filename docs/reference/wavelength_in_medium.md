# Wavelength of light inside an optical medium.

Returns the in-medium wavelength after accounting for the refractive
index. Frequency (and photon energy) are unchanged; only the spatial
period shortens.

## Usage

``` r
wavelength_in_medium(lambda, n)
```

## Arguments

- lambda:

  Wavelength in vacuum or air (nm, or any consistent unit). Vectorised.

- n:

  Refractive index of the medium (dimensionless). Must be \>= 1.

## Value

Wavelength in the medium, in the same unit as `lambda`.

## Examples

``` r
wavelength_in_medium(500, n = 1.336)  # seawater: ~374 nm in medium
#> [1] 374.2515
wavelength_in_medium(c(400, 500, 600), n = 1.5)
#> [1] 266.6667 333.3333 400.0000
```
