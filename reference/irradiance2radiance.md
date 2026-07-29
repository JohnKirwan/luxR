# Convert irradiance to radiance under a geometry assumption.

The relationship between irradiance E and radiance L depends on the
angular distribution of the light field. The caller must supply the
geometry; the function refuses to silently apply the wrong identity.

## Usage

``` r
irradiance2radiance(
  E,
  geometry = c("lambertian", "scalar", "collimated", "custom"),
  solid_angle = NULL
)
```

## Arguments

- E:

  Irradiance value(s) in \\W\\m^{-2}\\ (or any energy unit). Vectorised.

- geometry:

  One of:

  `"lambertian"`

  :   Planar (vector) irradiance from a Lambertian surface, or
      equivalently from an isotropic hemisphere of radiance — the
      cosine-weighted integral \\\int L \cos\theta\\ d\Omega = \pi L\\.
      This is what a cosine collector (e.g. a downwelling-irradiance
      sensor) measures: \\L = E / \pi\\. Default.

  `"scalar"`

  :   Scalar irradiance (fluence rate) over a \\2\pi\\ sr hemisphere —
      the *un*-weighted integral \\\int L\\ d\Omega = 2\pi L\\, as
      measured by a spherical collector. Scalar and vector irradiance
      are different physical quantities, not two flavours of the same
      measurement (Johnsen 2012, ch. 2): \\L = E / (2\pi)\\.

  `"collimated"`

  :   Normal-incidence collimated beam: \\L = E\\ (solid angle \\\to
      0\\).

  `"custom"`

  :   User-specified solid angle \\\Omega\\: \\L = E / \Omega\\.
      Requires `solid_angle`.

- solid_angle:

  Finite solid angle in (0, 4 pi\] steradians. Required when
  `geometry = "custom"` and rejected for other geometries.

## Value

Radiance in \\W\\m^{-2}\\sr^{-1}\\ (same numeric unit as `E`).

## References

Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
Nature. Princeton University Press. (Ch. 2: vector vs scalar
irradiance.)

## See also

[`radiance2irradiance`](https://johnkirwan.github.io/luxR/reference/radiance2irradiance.md)

## Examples

``` r
irradiance2radiance(pi)                              # lambertian: L = 1
#> [1] 1
irradiance2radiance(2 * pi, "scalar")                # scalar: L = 1
#> [1] 1
irradiance2radiance(10, "collimated")                # L = E
#> [1] 10
irradiance2radiance(10, "custom", solid_angle = 2)  # L = 5
#> [1] 5
```
