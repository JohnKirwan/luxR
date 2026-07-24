# Convert luxR spectra to a pavo `rspec` object

Bridges luxR data into the pavo ecosystem so pavo's colour-space and
visual-modelling tools (`vismodel()`, `coldist()`, `colspace()`,
plotting) can be applied to luxR-derived spectra. The division of
labour: luxR handles the water (depth propagation, inherent optical
properties, the in-water light field); pavo handles the colour space.

## Usage

``` r
as_rspec(x, ...)

# S3 method for class 'lux_spectrum'
as_rspec(x, name = NULL, ...)

# S3 method for class 'list'
as_rspec(x, ...)
```

## Arguments

- x:

  A
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md),
  or a (named) list of them — for example the output of
  [`from_trios`](https://johnkirwan.github.io/luxR/reference/from_trios.md).
  List elements are interpolated onto the first spectrum's wavelength
  grid before merging.

- ...:

  Passed to
  [`pavo::as.rspec()`](https://pavo.colrverse.com/reference/as.rspec.html)
  (e.g. `lim`, `interp`).

- name:

  Single-spectrum method only: the column name to give the spectrum in
  the `rspec`. Defaults to the spectrum's `meta$label`, then
  `meta$source`, then `"spec"`.

## Value

A pavo `rspec` data frame: a `wl` column plus one column per spectrum.

## Details

Delegates to
[`pavo::as.rspec()`](https://pavo.colrverse.com/reference/as.rspec.html),
which validates the input and, by default, interpolates onto a 1 nm
grid, so the result is a genuine `rspec` object. pavo is an optional
(`Suggests`) dependency.

## See also

[`as_lux_spectrum`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
for the reverse conversion;
[`pavo::as.rspec`](https://pavo.colrverse.com/reference/as.rspec.html),
[`pavo::vismodel`](https://pavo.colrverse.com/reference/vismodel.html)

## Examples

``` r
if (FALSE) { # \dontrun{
  # A bundled solar spectrum as an rspec, ready for the pavo toolkit:
  r <- as_rspec(from_solar("clear_noon"))

  # Several spectra at once (e.g. TriOS radiance scans):
  r2 <- as_rspec(from_trios(system.file("extdata/trios.dat", package = "luxR")))
} # }
```
