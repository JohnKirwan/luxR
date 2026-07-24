# Convert photon counts to watts at a given wavelength.

Uses E_photon = hc / lambda, with hc = 1.98644585714893e-16 J·nm.
Vectorised over both `n` and `lambda`.

## Usage

``` r
photon2W(n, lambda)
```

## Arguments

- n:

  Photon count(s) per second per m^2 per nm.

- lambda:

  Wavelength(s) in nm.

## Value

Numeric vector of spectral irradiance in W/m^2/nm.

## See also

[`W2photon`](https://johnkirwan.github.io/luxR/reference/W2photon.md)

## Examples

``` r
photon2W(1e15, 555)
#> [1] 0.0003579182
```
