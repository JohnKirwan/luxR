# Diffuse attenuation coefficient for Jerlov optical water types.

Returns Kd(lambda) for the specified Jerlov water type from the bundled
`jerlov_types` dataset (Jerlov 1976; Solonenko & Mobley 2015).
Optionally interpolates onto a user-supplied wavelength grid.

## Usage

``` r
jerlov_Kd(
  type = "IA",
  lambda = NULL,
  interp = c("linear", "spline", "nearest"),
  extrapolation = c("error", "constant")
)
```

## Arguments

- type:

  Jerlov water type. One of `"I"`, `"IA"`, `"IB"`, `"II"`, `"III"`,
  `"C1"`, `"C2"`, `"C3"`. Case-insensitive.

- lambda:

  Wavelengths in nm to interpolate Kd onto. If `NULL` (default), returns
  the full tabulated rows as a data frame.

- interp:

  Interpolation method when `lambda` is supplied. One of `"linear"`
  (default), `"spline"`, or `"nearest"`. Interpolation is applied only
  within the supported wavelength range.

- extrapolation:

  Out-of-range policy. The default `"error"` raises a
  `luxR_jerlov_range_error`. Set to `"constant"` to explicitly extend
  the nearest endpoint value; the choice is recorded in the returned
  vector's `"luxR.jerlov"` attribute.

## Value

If `lambda` is `NULL`: a data frame with columns `type`, `lambda`, `Kd`
and dataset metadata attributes. If `lambda` is supplied: a numeric
vector of Kd values (1/m) with a `"luxR.jerlov"` provenance attribute
recording the water type, interpolation and extrapolation policies,
supported and requested ranges, source checksum, build commit, and model
version.

## Details

The bundled Jerlov table supports 350–700 nm. Values outside that domain
are not measured by this dataset and therefore fail by default. Constant
endpoint extension is available only as an explicit modelling
assumption; linear or spline extrapolation is not supported.

## References

Jerlov NG (1976) Marine Optics. Elsevier, Amsterdam.

Solonenko MG, Mobley CD (2015) Inherent and apparent optical properties
of Jerlov water types. Applied Optics 54(17):5392-5401.

## Examples

``` r
jerlov_Kd("IA")
#>    type lambda    Kd
#> 16   IA    350 0.076
#> 17   IA    375 0.044
#> 18   IA    400 0.033
#> 19   IA    425 0.023
#> 20   IA    450 0.016
#> 21   IA    475 0.018
#> 22   IA    500 0.024
#> 23   IA    525 0.032
#> 24   IA    550 0.041
#> 25   IA    575 0.068
#> 26   IA    600 0.125
#> 27   IA    625 0.185
#> 28   IA    650 0.257
#> 29   IA    675 0.391
#> 30   IA    700 0.558
Kd_IA <- jerlov_Kd("IA", lambda = c(400, 450, 500, 550, 600))
as.numeric(Kd_IA)
#> [1] 0.033 0.016 0.024 0.041 0.125
attr(Kd_IA, "luxR.jerlov")[c("type", "interp", "extrapolation",
                              "supported_wavelength_range_nm")]
#> $type
#> [1] "IA"
#> 
#> $interp
#> [1] "linear"
#> 
#> $extrapolation
#> [1] "error"
#> 
#> $supported_wavelength_range_nm
#> [1] 350 700
#> 

lam <- seq(400, 700, by = 10)
Kd  <- jerlov_Kd("II", lambda = lam)
attenuate_spectrum(rep(1, length(lam)), Kd, depths = c(10, 25, 50),
                  lambda = lam)
#>    depth lambda            E
#> 1     10    400 3.828929e-01
#> 2     10    410 4.147829e-01
#> 3     10    420 4.493290e-01
#> 4     10    430 4.809461e-01
#> 5     10    440 5.086475e-01
#> 6     10    450 5.379444e-01
#> 7     10    460 5.510113e-01
#> 8     10    470 5.643955e-01
#> 9     10    480 5.769498e-01
#> 10    10    490 5.886050e-01
#> 11    10    500 6.004956e-01
#> 12    10    510 5.862553e-01
#> 13    10    520 5.723526e-01
#> 14    10    530 5.587797e-01
#> 15    10    540 5.455286e-01
#> 16    10    550 5.325918e-01
#> 17    10    560 4.611647e-01
#> 18    10    570 3.993169e-01
#> 19    10    580 3.409566e-01
#> 20    10    590 2.870784e-01
#> 21    10    600 2.417140e-01
#> 22    10    610 1.863740e-01
#> 23    10    620 1.437039e-01
#> 24    10    630 1.110250e-01
#> 25    10    640 8.594910e-02
#> 26    10    650 6.653681e-02
#> 27    10    660 3.815876e-02
#> 28    10    670 2.188399e-02
#> 29    10    680 1.198619e-02
#> 30    10    690 6.269868e-03
#> 31    10    700 3.279711e-03
#> 32    25    400 9.071795e-02
#> 33    25    410 1.108032e-01
#> 34    25    420 1.353353e-01
#> 35    25    430 1.604136e-01
#> 36    25    440 1.845195e-01
#> 37    25    450 2.122480e-01
#> 38    25    460 2.253727e-01
#> 39    25    470 2.393089e-01
#> 40    25    480 2.528396e-01
#> 41    25    490 2.658030e-01
#> 42    25    500 2.794310e-01
#> 43    25    510 2.631582e-01
#> 44    25    520 2.478330e-01
#> 45    25    530 2.334004e-01
#> 46    25    540 2.198082e-01
#> 47    25    550 2.070076e-01
#> 48    25    560 1.444243e-01
#> 49    25    570 1.007614e-01
#> 50    25    580 6.788094e-02
#> 51    25    590 4.415717e-02
#> 52    25    600 2.872464e-02
#> 53    25    610 1.499558e-02
#> 54    25    620 7.828378e-03
#> 55    25    630 4.107256e-03
#> 56    25    640 2.165725e-03
#> 57    25    650 1.141970e-03
#> 58    25    660 2.844367e-04
#> 59    25    670 7.084615e-05
#> 60    25    680 1.572907e-05
#> 61    25    690 3.112762e-06
#> 62    25    700 6.160116e-07
#> 63    50    400 8.229747e-03
#> 64    50    410 1.227734e-02
#> 65    50    420 1.831564e-02
#> 66    50    430 2.573251e-02
#> 67    50    440 3.404745e-02
#> 68    50    450 4.504920e-02
#> 69    50    460 5.079283e-02
#> 70    50    470 5.726876e-02
#> 71    50    480 6.392786e-02
#> 72    50    490 7.065121e-02
#> 73    50    500 7.808167e-02
#> 74    50    510 6.925223e-02
#> 75    50    520 6.142121e-02
#> 76    50    530 5.447573e-02
#> 77    50    540 4.831564e-02
#> 78    50    550 4.285213e-02
#> 79    50    560 2.085837e-02
#> 80    50    570 1.015286e-02
#> 81    50    580 4.607822e-03
#> 82    50    590 1.949856e-03
#> 83    50    600 8.251049e-04
#> 84    50    610 2.248673e-04
#> 85    50    620 6.128350e-05
#> 86    50    630 1.686956e-05
#> 87    50    640 4.690366e-06
#> 88    50    650 1.304097e-06
#> 89    50    660 8.090421e-08
#> 90    50    670 5.019176e-09
#> 91    50    680 2.474036e-10
#> 92    50    690 9.689290e-12
#> 93    50    700 3.794703e-13
```
