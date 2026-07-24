# Convert spectral reflectance to spectral radiance

Multiplies a reflectance spectrum by an illuminant spectrum bin-by-bin.
For a `lux_spectrum` irradiance illuminant, a Lambertian reflector is
assumed: radiance is \\L = \rho E / \pi\\, and the output unit gains the
steradian term. For a radiance illuminant, the values are multiplied
directly and its radiance unit is retained.

## Usage

``` r
reflectance_to_radiance(reflectance, ...)

# S3 method for class 'numeric'
reflectance_to_radiance(reflectance, illuminant, lambda, ...)

# S3 method for class 'lux_spectrum'
reflectance_to_radiance(reflectance, illuminant, ...)
```

## Arguments

- reflectance:

  Numeric vector of reflectance values in \[0, 1\], or a `lux_spectrum`
  with `quantity = "reflectance"`.

- ...:

  Ignored.

- illuminant:

  Numeric vector of spectral irradiance/radiance, or a `lux_spectrum`
  with quantity `"irradiance"` or `"radiance"`.

- lambda:

  Numeric vector of wavelengths in nm (not needed when both inputs are
  `lux_spectrum`).

## Value

Named numeric vector, or a `lux_spectrum` with `quantity = "radiance"`
and a dimensionally compatible radiance unit. The numeric method
performs only element-wise multiplication because numeric vectors do not
carry irradiance/radiance dimensional metadata.

## Examples

``` r
sp   <- solar_irradiance("clear_noon")
lam  <- sp$wavelength
refl <- rep(0.5, length(lam))
reflectance_to_radiance(refl, sp$irradiance, lam)
#>   300   310   320   330   340   350   360   370   380   390   400   410   420 
#> 0.000 0.005 0.070 0.180 0.325 0.445 0.560 0.610 0.560 0.510 0.500 0.610 0.715 
#>   430   440   450   460   470   480   490   500   510   520   530   540   550 
#> 0.735 0.755 0.780 0.800 0.830 0.860 0.890 0.920 0.940 0.950 0.950 0.940 0.925 
#>   560   570   580   590   600   610   620   630   640   650   660   670   680 
#> 0.905 0.880 0.860 0.835 0.810 0.785 0.760 0.735 0.710 0.685 0.660 0.630 0.600 
#>   690   700   710   720   730   740   750   760   770   780   790   800 
#> 0.570 0.540 0.510 0.480 0.450 0.420 0.390 0.360 0.330 0.300 0.270 0.240 
```
