# Depth at which a given fraction of surface light remains.

Solves exp(-Kd \* z) = fraction for z, giving -log(fraction) / Kd. The
default 1

## Usage

``` r
photic_depth(Kd, fraction = 0.01)
```

## Arguments

- Kd:

  Diffuse attenuation coefficient(s) in 1/m.

- fraction:

  Fraction of surface irradiance. Must be in (0, 1). Default 0.01 (1%).

## Value

Depth(s) in metres at which `fraction` of surface light remains.

## Examples

``` r
photic_depth(0.06)
#> [1] 76.75284
photic_depth(0.06, fraction = 0.1)
#> [1] 38.37642
```
