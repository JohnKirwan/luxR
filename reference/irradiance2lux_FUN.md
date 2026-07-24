# Per-bin lux computation (internal).

Per-bin lux computation (internal).

## Usage

``` r
irradiance2lux_FUN(
  W_spec_irradiance,
  lambda_measured,
  integration_weights,
  LEF_W = NULL,
  LEF_lambda = NULL,
  verbose = FALSE
)
```

## Arguments

- W_spec_irradiance:

  Spectral irradiance (W/m^2/nm) at each wavelength bin.

- lambda_measured:

  Bin-centre wavelengths in nm.

- integration_weights:

  Validated finite, positive quadrature weights in nm, one per measured
  wavelength.

- LEF_W:

  V(lambda) values from the full luminous efficiency function vector.

- LEF_lambda:

  Wavelength grid matching `LEF_W`.

- verbose:

  Logical; emit per-bin diagnostic message if TRUE.

## Value

Numeric vector of lux contributions, one per wavelength bin.
