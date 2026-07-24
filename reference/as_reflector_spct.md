# Convert luxR reflectance to a photobiology reflector_spct

Bridges a reflectance
[`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
into photobiology as a `reflector_spct`. luxR already constrains
reflectance to `[0, 1]`, so values map onto `Rfr` directly.

## Usage

``` r
as_reflector_spct(x, ...)

# S3 method for class 'lux_spectrum'
as_reflector_spct(x, Rfr.type = NULL, strict.range = TRUE, ...)

# S3 method for class 'list'
as_reflector_spct(x, ...)
```

## Arguments

- x:

  A reflectance
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
  or a (named) list of them.

- ...:

  Passed to
  [`photobiology::reflector_spct()`](https://docs.r4photobiology.info/photobiology/reference/source_spct.html).

- Rfr.type:

  Either `"total"` or `"specular"`. Defaults to `x$meta$Rfr_type`; an
  error is raised if neither is supplied.

- strict.range:

  Passed to
  [`photobiology::reflector_spct()`](https://docs.r4photobiology.info/photobiology/reference/source_spct.html).
  Defaults to `TRUE`.

## Value

A photobiology `reflector_spct`.

## Details

`Rfr.type` is required. Whether a reflectance is total or specular is a
fact about how it was measured, which luxR does not otherwise carry;
defaulting it would silently mislabel the measurement inside another
package's ecosystem. Record it once in the spectrum's `meta$Rfr_type` to
have it picked up automatically.

## See also

[`as_source_spct`](https://johnkirwan.github.io/luxR/reference/as_source_spct.md),
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  r <- as_reflector_spct(my_reflectance, Rfr.type = "total")
} # }
```
