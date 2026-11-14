# Read a TriOS RAMSES spectroradiometer data file

Parses one or more spectra from a TriOS RAMSES \`.dat\` text file. Each
spectrum is preceded by a \`Comment\` header line and terminated by a
\`\[END\]\` marker. Data rows contain three whitespace-separated fields:
index, wavelength (nm), and spectral radiance (mW m\\^{-2}\\ nm\\^{-1}\\
sr\\^{-1}\\). Radiance values are converted to W m\\^{-2}\\ nm\\^{-1}\\
sr\\^{-1}\\. Negative instrument values are preserved; no clipping or
other preprocessing is performed by this low-level reader.

## Usage

``` r
read_trios(path)
```

## Arguments

- path:

  Character. Path to the \`.dat\` file.

## Value

A `data.frame` with columns:

- spectrum:

  Character. Spectrum label from the Comment header.

- lambda:

  Numeric. Wavelength in nm.

- radiance:

  Numeric. Spectral radiance in W m\\^{-2}\\ nm\\^{-1}\\ sr\\^{-1}\\.

## Examples

``` r
# A synthetic one-scan TriOS file (radiance in mW/m2/sr/nm):
f <- tempfile(fileext = ".dat")
writeLines(c("Comment\tscan_1", rep("header_line", 29),
             paste(1:31, seq(400, 700, by = 10), seq(1, 4, length.out = 31),
                   sep = "\t"),
             "[END]"), f)
head(read_trios(f))
#>   spectrum lambda radiance
#> 1   scan_1    400   0.0010
#> 2   scan_1    410   0.0011
#> 3   scan_1    420   0.0012
#> 4   scan_1    430   0.0013
#> 5   scan_1    440   0.0014
#> 6   scan_1    450   0.0015
unlink(f)
```
