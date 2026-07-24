# Propagate a known irradiance to any other depth (bidirectional).

Computes E(to) = E_known \* exp(-Kd \* (to - from)). Works forward (to
\> from), inverse (to \< from, recovering a shallower value), and
between any two depths.

## Usage

``` r
propagate_depth(E_known, Kd, from = 0, to, allow_above_surface = FALSE)
```

## Arguments

- E_known:

  Irradiance at depth `from`. Scalar or vector.

- Kd:

  Diffuse attenuation coefficient in 1/m. Scalar.

- from:

  Depth of the known measurement in metres. Default 0 (surface).

- to:

  Target depth(s) in metres. Scalar or vector.

- allow_above_surface:

  Logical; permits negative absolute depths (above the surface). Default
  FALSE.

## Value

Irradiance at `to`, in the same units as `E_known`.

## Note

Un-attenuating with a negative depth delta assumes the water column is
homogeneous above the measurement point. For stratified water bodies
(thermocline, chlorophyll layer) the result will be approximate. Inverse
propagation also amplifies measurement noise and can overflow for long
or strongly attenuating paths. This model does not cross the air-water
interface; use
[`surface_transmittance`](https://johnkirwan.github.io/luxR/reference/surface_transmittance.md)
explicitly or a high-level workflow such as
[`light_at_depth`](https://johnkirwan.github.io/luxR/reference/light_at_depth.md).

## Examples

``` r
propagate_depth(112400, Kd = 0.062, from = 0, to = 30)
#> [1] 17497.6
propagate_depth(8260,   Kd = 0.062, from = 22, to = 0)
#> [1] 32311.54
```
