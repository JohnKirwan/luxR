# Read a TriOS RAMSES file as calibrated radiance spectra

Wraps
[`read_trios`](https://johnkirwan.github.io/luxR/reference/read_trios.md).
The low-level reader preserves negative instrument values. Construction
of non-negative physical radiance spectra therefore either fails (the
default) or requires an explicit, recorded zero-floor preprocessing
policy.

## Usage

``` r
from_trios(path, negative_policy = c("error", "zero"))
```

## Arguments

- path:

  Path to a TriOS RAMSES `.dat` file.

- negative_policy:

  Either `"error"` (default) or `"zero"`.

## Value

A named list of radiance `lux_spectrum` objects.

## See also

[`read_trios`](https://johnkirwan.github.io/luxR/reference/read_trios.md),
[`read_spectrum`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)

## Examples

``` r
# A synthetic one-scan TriOS file (radiance in mW/m2/sr/nm):
f <- tempfile(fileext = ".dat")
writeLines(c("Comment\tscan_1", rep("header_line", 29),
             paste(1:31, seq(400, 700, by = 10), seq(1, 4, length.out = 31),
                   sep = "\t"),
             "[END]"), f)
s <- from_trios(f)
names(s)
#> [1] "scan_1"
s$scan_1$unit
#> [1] "W/m2/sr/nm"
unlink(f)
```
