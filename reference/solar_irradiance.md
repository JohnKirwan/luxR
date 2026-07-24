# Reference solar spectral irradiance under standard conditions.

Returns a reference spectrum from the bundled `solar_spectra` dataset,
based on ASTM G173-03 global-tilt values scaled to several
representative illumination conditions. Intended for use as the
reference shape in
[`broadband2spectrum`](https://johnkirwan.github.io/luxR/reference/broadband2spectrum.md)
and
[`lux2irradiance`](https://johnkirwan.github.io/luxR/reference/lux2irradiance.md).

## Usage

``` r
solar_irradiance(condition = "clear_noon")
```

## Arguments

- condition:

  Character string naming the illumination condition. One of the five
  conditions listed in Details.

## Value

A data frame with columns `wavelength` (nm) and `irradiance` (W/m^2/nm).
Attributes record `condition`, `reference_depth_m` (metres relative to
the water surface), and `reference_medium` (`"air"` or `"water"`).

## Details

Available conditions:

- `"clear_noon"`:

  Full-sun midday irradiance (ASTM G173-03 GTI).

- `"clear_dawn"`:

  Clear sky near sunrise/sunset (~35% of noon).

- `"overcast"`:

  Overcast diffuse sky (~22% of noon).

- `"underwater_1m"`:

  ASTM GTI attenuated through 1 m of Jerlov IA water.

- `"underwater_10m"`:

  ASTM GTI attenuated through 10 m of Jerlov IA water.

The historical underwater sources span 300–800 nm and were generated
with constant endpoint extension beyond the bundled Jerlov dataset's
supported 350–700 nm domain. Their attributes explicitly record this
assumption and the Jerlov table checksum so it is not a silent
extrapolation path.

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
broadband2spectrum(480, unit = "W", spectrum = solar_irradiance("overcast"))
#>    wavelength  irradiance
#> 1         300 0.000000000
#> 2         310 0.007722008
#> 3         320 0.108108108
#> 4         330 0.277992278
#> 5         340 0.501930502
#> 6         350 0.687258687
#> 7         360 0.864864865
#> 8         370 0.942084942
#> 9         380 0.864864865
#> 10        390 0.787644788
#> 11        400 0.772200772
#> 12        410 0.942084942
#> 13        420 1.104247104
#> 14        430 1.135135135
#> 15        440 1.166023166
#> 16        450 1.204633205
#> 17        460 1.235521236
#> 18        470 1.281853282
#> 19        480 1.328185328
#> 20        490 1.374517375
#> 21        500 1.420849421
#> 22        510 1.451737452
#> 23        520 1.467181467
#> 24        530 1.467181467
#> 25        540 1.451737452
#> 26        550 1.428571429
#> 27        560 1.397683398
#> 28        570 1.359073359
#> 29        580 1.328185328
#> 30        590 1.289575290
#> 31        600 1.250965251
#> 32        610 1.212355212
#> 33        620 1.173745174
#> 34        630 1.135135135
#> 35        640 1.096525097
#> 36        650 1.057915058
#> 37        660 1.019305019
#> 38        670 0.972972973
#> 39        680 0.926640927
#> 40        690 0.880308880
#> 41        700 0.833976834
#> 42        710 0.787644788
#> 43        720 0.741312741
#> 44        730 0.694980695
#> 45        740 0.648648649
#> 46        750 0.602316602
#> 47        760 0.555984556
#> 48        770 0.509652510
#> 49        780 0.463320463
#> 50        790 0.416988417
#> 51        800 0.370656371
```
