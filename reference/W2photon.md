# Convert watts to photon counts at a given wavelength.

Inverse of
[`photon2W`](https://johnkirwan.github.io/luxR/reference/photon2W.md).

## Usage

``` r
W2photon(W, lambda)
```

## Arguments

- W:

  Spectral irradiance in \\W\\m^{-2}\\nm^{-1}\\.

- lambda:

  Wavelength(s) in nm.

## Value

Numeric vector of photon counts in \\photons\\m^{-2}\\s^{-1}\\nm^{-1}\\.

## Examples

``` r
W2photon(1, 555)
#> [1] 2.793935e+18
```
