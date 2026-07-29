# ASTM G173-03 reference solar spectral irradiance.

A named list of reference spectral irradiance data frames representing
five standard illumination conditions, derived from the ASTM G173-03
global-tilt spectrum. Used by
[`solar_irradiance`](https://johnkirwan.github.io/luxR/reference/solar_irradiance.md).

## Usage

``` r
solar_spectra
```

## Format

A named list of five data frames, each with columns:

- wavelength:

  Wavelength in nm (300 to 800, step 10).

- irradiance:

  Spectral irradiance in \\W\\m^{-2}\\nm^{-1}\\.

Names: `clear_noon`, `clear_dawn`, `overcast`, `underwater_1m`,
`underwater_10m`. Each data frame has attributes `condition`,
`reference_depth_m`, and `reference_medium`. Reference depth is measured
in metres from the water surface; the three atmospheric spectra use
depth 0 in `"air"`, and the underwater spectra use depths 1 and 10 in
`"water"`, respectively.

## Source

ASTM G173-03(2012) Standard Tables for Reference Solar Spectral
Irradiances. American Society for Testing and Materials, West
Conshohocken, PA.

## Examples

``` r
solar_irradiance("clear_noon")
#>    wavelength irradiance
#> 1         300       0.00
#> 2         310       0.01
#> 3         320       0.14
#> 4         330       0.36
#> 5         340       0.65
#> 6         350       0.89
#> 7         360       1.12
#> 8         370       1.22
#> 9         380       1.12
#> 10        390       1.02
#> 11        400       1.00
#> 12        410       1.22
#> 13        420       1.43
#> 14        430       1.47
#> 15        440       1.51
#> 16        450       1.56
#> 17        460       1.60
#> 18        470       1.66
#> 19        480       1.72
#> 20        490       1.78
#> 21        500       1.84
#> 22        510       1.88
#> 23        520       1.90
#> 24        530       1.90
#> 25        540       1.88
#> 26        550       1.85
#> 27        560       1.81
#> 28        570       1.76
#> 29        580       1.72
#> 30        590       1.67
#> 31        600       1.62
#> 32        610       1.57
#> 33        620       1.52
#> 34        630       1.47
#> 35        640       1.42
#> 36        650       1.37
#> 37        660       1.32
#> 38        670       1.26
#> 39        680       1.20
#> 40        690       1.14
#> 41        700       1.08
#> 42        710       1.02
#> 43        720       0.96
#> 44        730       0.90
#> 45        740       0.84
#> 46        750       0.78
#> 47        760       0.72
#> 48        770       0.66
#> 49        780       0.60
#> 50        790       0.54
#> 51        800       0.48
```
