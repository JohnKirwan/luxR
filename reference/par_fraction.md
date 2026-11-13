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
par_fraction(
  irradiance,
  lambda,
  binwidth = NULL,
  photonic = FALSE,
  basis = c("photon", "energy"),
  ...
)

# S3 method for class 'lux_spectrum'
par_fraction(irradiance, basis = c("photon", "energy"), ...)
```

## Arguments

- irradiance:

  Spectral irradiance, or a `lux_spectrum` irradiance object (radiance
  and reflectance are rejected).

- ...:

  Ignored.

- lambda:

  Wavelength vector in nm.

- binwidth:

  Bin width in nm. Inferred from `lambda` if `NULL`.

- photonic:

  Logical. `FALSE` (default): numeric input is in energy units (e.g. W
  m\\^{-2}\\ nm\\^{-1}\\). `TRUE`: input is a photon or molar flux per
  nm. A `lux_spectrum` records its own unit.

- basis:

  `"photon"` (default) or `"energy"`: what the fraction counts.

## Value

Numeric scalar in \[0, 1\]. An error is raised if the total irradiance
is zero.

## Details

By default the fraction counts photons, because PAR is defined as a
photon flux (photosynthesis responds to photons absorbed, not energy).
Use `basis = "energy"` for the fraction of radiant energy. The two
differ because a long-wavelength photon carries less energy: an energy
spectrum is converted to photons by weighting each bin by its
wavelength.

Samples are bins of width `binwidth` centred on their wavelengths, on a
regularly spaced grid. A bin straddling 400 or 700 nm contributes only
its part inside the PAR window. The grid need not span the whole window.

## Examples

``` r
sp <- solar_irradiance("clear_noon")
par_fraction(sp$irradiance, sp$wavelength)
#> [1] 0.7500613
```
