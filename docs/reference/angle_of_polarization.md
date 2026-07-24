# Angle of polarization (e-vector orientation) from Stokes parameters

\$\$AoP = \tfrac{1}{2}\\\mathrm{atan2}(U, Q)\$\$. Polarization
orientation is axial (period 180 degrees); the value is returned in
degrees in the half-open range `(-90, 90]`.

## Usage

``` r
angle_of_polarization(Q, U)
```

## Arguments

- Q, U:

  Linear polarization Stokes parameters.

## Value

Angle of polarization in degrees, in `(-90, 90]`. The result is `NA`
where both `Q` and `U` are zero because orientation is undefined. Scalar
inputs are broadcast; incompatible lengths are rejected.

## See also

[`degree_of_polarization`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md)

## Examples

``` r
angle_of_polarization(Q = 1, U = 0)   #  0
#> [1] 0
angle_of_polarization(Q = 0, U = 1)   # 45
#> [1] 45
```
