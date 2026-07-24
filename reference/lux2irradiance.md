# Distribute integrated lux across a reference spectral shape.

lux is a single scalar; a spectrum has many degrees of freedom. This
function takes a reference *shape* and rescales it so its photopic
integral equals `lx`. The shape assumption must be supplied by the
caller.

## Usage

``` r
lux2irradiance(
  lx,
  spectrum,
  lambda = NULL,
  LEF = CIE1931,
  binwidth = NULL,
  integration = c("rectangle", "trapezoid")
)
```

## Arguments

- lx:

  Target illuminance in lux.

- spectrum:

  Reference spectral shape. Either a data frame with columns `lambda`
  and `irradiance`, or a bare numeric vector (in which case `lambda`
  must be supplied separately).

- lambda:

  Wavelength grid in nm. Required when `spectrum` is a bare vector;
  ignored when `spectrum` is a data frame.

- LEF:

  Luminous efficiency function. Defaults to `CIE1931`.

- binwidth:

  Wavelength bin width in nm. Inferred from a regular multi-bin
  wavelength grid when `NULL`; required for a single bin under
  rectangular integration. Must be `NULL` for trapezoidal integration.

- integration:

  Integration method passed to
  [`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md):
  `"rectangle"` (default) or `"trapezoid"`.

## Value

Numeric vector of rescaled spectral irradiance (same length as the
wavelength grid).

## Examples

``` r
spec <- data.frame(lambda = CIE1931$lambda, irradiance = CIE1931$W)
irr  <- lux2irradiance(5000, spec)
```
