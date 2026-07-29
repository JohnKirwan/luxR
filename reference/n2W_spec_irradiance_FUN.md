# Provide W values for measures of spectral irradiance. The constant is Planck's constant times the speed of light in nm/s. It is an internal function applied to a single wavelength bin.

Provide W values for measures of spectral irradiance. The constant is
Planck's constant times the speed of light in nm/s. It is an internal
function applied to a single wavelength bin.

## Usage

``` r
n2W_spec_irradiance_FUN(photons, lambda)
```

## Arguments

- photons:

  The spectral irradiance (in \\W\\m^{-2}\\nm^{-1}\\ or
  \\photons\\m^{-2}\\s^{-1}\\nm^{-1}\\; see photon) at each wavelength
  bin.

- lambda:

  The wavelength in nanometres (nm), taken from the midpoint value of
  irradiance bins.

## Value

A scalar representing the spectral irradiance values transformed from
\\photons\\m^{-2}\\s^{-1}\\nm^{-1}\\ into \\W\\m^{-2}\\nm^{-1}\\.
