# Read a calibrated Ocean Optics spectrum as a lux_spectrum

Ocean Optics text files do not contain a standardized machine-readable
unit or calibration state. All physical declarations are therefore
required. Use
[`read_ocean_optics`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md)
to inspect raw or relative values.

## Usage

``` r
from_ocean_optics(
  path,
  quantity = NULL,
  unit = NULL,
  calibration = NULL,
  check_pixels = TRUE
)
```

## Arguments

- path:

  Path to the Ocean Optics text file.

- quantity:

  Explicit physical quantity represented by the values.

- unit:

  Explicit unit compatible with `quantity`.

- calibration:

  Non-empty calibration identifier or description.

- check_pixels:

  If `TRUE` (default), error when the header's declared pixel count
  differs from the number of spectral rows. Set `FALSE` only for spliced
  or multi-spectrometer exports, whose header gives one detector's pixel
  count; the choice is recorded in the import provenance.

## Value

A validated `lux_spectrum` with import provenance in metadata.

## See also

[`read_ocean_optics`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md),
[`from_trios`](https://johnkirwan.github.io/luxR/reference/from_trios.md),
[`read_spectrum`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)

## Examples

``` r
# A synthetic three-pixel Ocean Optics text export:
f <- tempfile(fileext = ".txt")
writeLines(c("Spectrometer: USB2E0034", "Integration Time (usec): 10000",
             "Number of Pixels in Spectrum: 3", ">>>>>Begin Spectral Data<<<<<",
             "400.0\t0.0012", "450.0\t0.0024", "500.0\t0.0036"), f)
x <- from_ocean_optics(f, quantity = "irradiance", unit = "W/m2/nm",
                       calibration = "example")
x$E
#> [1] 0.0012 0.0024 0.0036
unlink(f)
```
