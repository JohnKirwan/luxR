# Resample a spectrum to a new wavelength grid

Interpolates spectral values onto a target wavelength grid using
[`approx`](https://rdrr.io/r/stats/approxfun.html) (linear, default) or
[`spline`](https://rdrr.io/r/stats/splinefun.html) (cubic). The most
common use case is harmonising spectra from two instruments before
arithmetic or comparison (e.g. aligning a TriOS RAMSES spectrum at 3.3
nm resolution with a Jerlov-based Kd vector at 25 nm steps).

## Usage

``` r
resample_spectrum(
  x,
  lambda,
  from = NULL,
  method = c("linear", "cubic"),
  rule = 1
)

# S3 method for class 'lux_spectrum'
resample_spectrum(
  x,
  lambda,
  from = NULL,
  method = c("linear", "cubic"),
  rule = 1
)

# S3 method for class 'numeric'
resample_spectrum(
  x,
  lambda,
  from = NULL,
  method = c("linear", "cubic"),
  rule = 1
)
```

## Arguments

- x:

  A `lux_spectrum` object or numeric spectral-value vector.

- lambda:

  Target wavelength grid in nm (numeric vector). When `x` is a
  `lux_spectrum` this argument is required.

- from:

  Source wavelength grid in nm. Required when `x` is a numeric vector;
  ignored when `x` is a `lux_spectrum` (wavelengths are taken from
  `x$lambda`).

- method:

  Interpolation method: `"linear"` (default) or `"cubic"`.

- rule:

  Integer passed to [`approx`](https://rdrr.io/r/stats/approxfun.html)
  controlling out-of-range behaviour. Default `1` (return `NA`); use `2`
  to extend with boundary values.

## Value

A `lux_spectrum` (when `x` is a `lux_spectrum`) or a named numeric
vector, resampled onto `lambda`.

## Details

Values are not extrapolated beyond the source wavelength range. By
default (`rule = 1`) wavelengths outside that range receive `NA`; set
`rule = 2` to extend using the nearest boundary value instead. Because a
`lux_spectrum` cannot contain non-finite values, its method raises a
validation error when `rule = 1` produces `NA`. The target grid for a
`lux_spectrum` must also be strictly increasing and regular. The numeric
method can be used to resample raw values from an irregular source grid
before constructing a `lux_spectrum`.

## See also

[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)

## Examples

``` r
# Resample a solar spectrum from 10 nm to 5 nm bins
sp  <- solar_irradiance("clear_noon")
x   <- as_lux_spectrum(sp)
x5  <- resample_spectrum(x, lambda = seq(300, 800, by = 5))
x5
#> <lux_spectrum> irradiance [W/m2/nm] | 300-800 nm, 5 nm bins (101 pts)

# Align a Jerlov Kd vector to the Naples wavelength grid
lam_naples <- from_naples("0m")$lambda
lam_naples <- lam_naples[lam_naples >= 350 & lam_naples <= 700]
lam_jerlov <- seq(350, 700, by = 25)
Kd_coarse  <- jerlov_Kd("II", lam_jerlov)
Kd_fine    <- resample_spectrum(Kd_coarse, lambda = lam_naples,
                                 from = lam_jerlov, rule = 1)
```
