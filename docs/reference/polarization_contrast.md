# Polarization contrast between a target and its background

How distinct a target's polarization is from its background, for a
polarization-sensitive viewer. Each polarization state is mapped to its
normalised linear-polarization (Stokes) coordinates \$\$q = DoP\cos
2\psi, \qquad u = DoP\sin 2\psi,\$\$ where \\\psi\\ is the angle of
polarization; the **polarization distance** is the Euclidean separation
in this plane, \$\$\Delta P = \sqrt{(q_t - q_b)^2 + (u_t - u_b)^2}.\$\$
The factor of two in the angle correctly handles the 180-degree
periodicity of polarization orientation, so orthogonal e-vectors (90
degrees apart) at equal degree of polarization give the maximal angular
contrast. This is the geometric core of How & Marshall's (2014)
polarization-distance model.

## Usage

``` r
polarization_contrast(target_dop, target_aop, background_dop, background_aop)
```

## Arguments

- target_dop, target_aop:

  Degree of polarization (0-1) and angle of polarization (degrees) of
  the target. Vectorised.

- background_dop, background_aop:

  Degree and angle of polarization of the background. Vectorised.
  Scalars are broadcast; implicit partial recycling is rejected.

## Value

A data frame with columns `delta_dop` (absolute difference in degree of
polarization), `delta_aop` (axial angular difference in degrees,
`[0, 90]`), and `distance` (the polarization distance \\\Delta P\\).

## References

How MJ, Marshall NJ (2014) Polarization distance: a framework for
modelling object detection by polarization vision systems. Proceedings
of the Royal Society B 281:20131632.

## See also

[`underwater_polarization`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md),
[`degree_of_polarization`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md),
[`weber_contrast`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md)

## Examples

``` r
# A horizontally polarized target against a weakly polarized background:
polarization_contrast(target_dop = 0.5, target_aop = 0,
                      background_dop = 0.1, background_aop = 45)
#>   delta_dop delta_aop distance
#> 1       0.4        45 0.509902
```
