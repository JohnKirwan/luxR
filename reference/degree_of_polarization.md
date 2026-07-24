# Degree of polarization from Stokes parameters

\$\$DoP = \sqrt{Q^2 + U^2 + V^2} / I\$\$. With `V = 0` (the default, and
the usual case for the underwater light field, which is essentially
linearly polarized) this is the degree of *linear* polarization.

## Usage

``` r
degree_of_polarization(I, Q, U, V = 0)
```

## Arguments

- I:

  Total radiance (Stokes I). Must be \> 0.

- Q, U:

  Linear polarization Stokes parameters.

- V:

  Circular polarization Stokes parameter. Default 0.

## Value

Degree of polarization in `[0, 1]`. Vectorised. Scalar inputs are
broadcast; incompatible non-scalar lengths are rejected.

## Details

All inputs must be finite numeric vectors. A Stokes vector is physical
only when \\I \> 0\\ and \\\sqrt{Q^2 + U^2 + V^2} \le I\\. Values
exceeding this bound by more than 64 machine epsilons are rejected with
a `luxR_polarization_physicality_error`. Values within that round-off
tolerance are returned as exactly one.

## See also

[`angle_of_polarization`](https://johnkirwan.github.io/luxR/reference/angle_of_polarization.md),
[`underwater_polarization`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)

## Examples

``` r
degree_of_polarization(I = 1, Q = 0.4, U = 0)   # 0.4
#> [1] 0.4
```
