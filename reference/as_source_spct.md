# Convert luxR spectra to photobiology spectral classes

Bridges luxR data into the photobiology ecosystem so its generic
spectral classes, integration, and photometry can be applied to
luxR-derived spectra. The division of labour: luxR handles the water
(depth propagation, inherent optical properties, the in-water light
field); photobiology handles generic spectral computation.

## Usage

``` r
as_source_spct(x, ...)

# S3 method for class 'lux_spectrum'
as_source_spct(x, strict.range = TRUE, ...)

# S3 method for class 'list'
as_source_spct(x, ...)
```

## Arguments

- x:

  A
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
  or a (named) list of them.

- ...:

  Passed to the photobiology constructor.

- strict.range:

  Passed to the photobiology constructor. Defaults to `TRUE` so
  photobiology validates the values independently of luxR.

## Value

A photobiology `source_spct`.

## Details

`as_source_spct()` requires spectral irradiance and delegates to
[`photobiology::source_spct()`](https://docs.r4photobiology.info/photobiology/reference/source_spct.html).
Energy units become `s.e.irrad` and photon units become `s.q.irrad`,
rescaled to photobiology's `mol/m2/s/nm`. The spectrum is **not**
converted between energy and photon bases: it arrives in the basis it
already had, and
[`photobiology::e2q()`](https://docs.r4photobiology.info/photobiology/reference/e2q.html)
or `q2e()` does any conversion, so only one implementation of that
conversion is ever in play.

Radiance is refused, because `source_spct` has no per-steradian term.
photobiology is an optional (`Suggests`) dependency.

## See also

[`as_reflector_spct`](https://johnkirwan.github.io/luxR/reference/as_reflector_spct.md)
for reflectance,
[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
for the reverse conversion,
[`as_rspec`](https://johnkirwan.github.io/luxR/reference/as_rspec.md)
for the pavo bridge

## Examples

``` r
if (FALSE) { # \dontrun{
  # The downwelling light field at 15 m, as a photobiology source_spct:
  # Jerlov Kd data cover 350-700 nm, so trim before propagating.
  surface <- from_solar("clear_noon")[350, 700]
  at_depth <- propagate_spectrum(surface, jerlov_Kd("II", surface$lambda),
                                 from = 0, to = 15)
  s <- as_source_spct(at_depth[["15"]])
  photobiology::e_irrad(s)
} # }
```
