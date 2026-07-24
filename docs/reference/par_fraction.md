# Fraction of spectral irradiance in the PAR window.

Returns the ratio of band-integrated irradiance over 400–700 nm to the
total integrated irradiance across the full wavelength range supplied.
Useful for characterising how spectrally narrowed a light field has
become (e.g. at depth, where red wavelengths are preferentially
removed).

## Usage

``` r
par_fraction(irradiance, ...)

# S3 method for class 'numeric'
par_fraction(irradiance, lambda, binwidth = NULL, ...)

# S3 method for class 'lux_spectrum'
par_fraction(irradiance, ...)
```

## Arguments

- irradiance:

  Spectral irradiance (any consistent energy unit per nm), or a
  `lux_spectrum` object.

- ...:

  Ignored.

- lambda:

  Wavelength vector in nm.

- binwidth:

  Bin width in nm. Inferred from `lambda` if `NULL`.

## Value

Numeric scalar in (0, 1\].

## Examples

``` r
sp <- solar_irradiance("clear_noon")
par_fraction(sp$irradiance, sp$wavelength)
#> [1] 0.7742921
```
