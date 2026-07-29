# Convert radiance to irradiance under a geometry assumption.

Inverse of
[`irradiance2radiance`](https://johnkirwan.github.io/luxR/reference/irradiance2radiance.md).
The geometry argument must match the one used during collection.

## Usage

``` r
radiance2irradiance(
  L,
  geometry = c("lambertian", "scalar", "collimated", "custom"),
  solid_angle = NULL
)
```

## Arguments

- L:

  Radiance value(s) in \\W\\m^{-2}\\sr^{-1}\\. Vectorised.

- geometry:

  One of `"lambertian"` (default), `"scalar"`, `"collimated"`, or
  `"custom"`. See
  [`irradiance2radiance`](https://johnkirwan.github.io/luxR/reference/irradiance2radiance.md)
  for details.

- solid_angle:

  Finite solid angle in (0, 4 pi\] steradians. Required for
  `geometry = "custom"` and rejected for other geometries.

## Value

Irradiance in \\W\\m^{-2}\\.

## Examples

``` r
radiance2irradiance(1)                              # lambertian: E = pi
#> [1] 3.141593
radiance2irradiance(1, "scalar")                    # scalar: E = 2*pi
#> [1] 6.283185
radiance2irradiance(5, "custom", solid_angle = 2)  # E = 10
#> [1] 10
```
