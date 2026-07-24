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
