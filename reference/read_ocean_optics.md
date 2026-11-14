# Strictly parse an Ocean Optics / Ocean Insight spectrum file

Parses the plain-text format without assigning a physical quantity or
unit. Every row must contain exactly two tab-separated numeric fields.
Instrument values, including negatives, are preserved without clipping.

## Usage

``` r
read_ocean_optics(path, check_pixels = TRUE)
```

## Arguments

- path:

  Path to the Ocean Optics `.txt` file.

- check_pixels:

  If `TRUE` (default), error when the header's declared pixel count
  differs from the number of spectral rows. Set `FALSE` only for spliced
  or multi-spectrometer exports, whose header gives one detector's pixel
  count; the choice is recorded in the import provenance.

## Value

A data frame containing `lambda` and `signal`. Parsed header and import
provenance are attached as `"luxR.header"` and `"luxR.import"`
attributes.

## Examples

``` r
# A synthetic three-pixel Ocean Optics text export:
f <- tempfile(fileext = ".txt")
writeLines(c("Spectrometer: USB2E0034", "Integration Time (usec): 10000",
             "Number of Pixels in Spectrum: 3", ">>>>>Begin Spectral Data<<<<<",
             "400.0\t0.0012", "450.0\t0.0024", "500.0\t0.0036"), f)
read_ocean_optics(f)
#>   lambda signal
#> 1    400 0.0012
#> 2    450 0.0024
#> 3    500 0.0036
unlink(f)
```
