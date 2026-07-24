# Read a calibrated Ocean Optics spectrum as a lux_spectrum

Ocean Optics text files do not contain a standardized machine-readable
unit or calibration state. All physical declarations are therefore
required. Use
[`read_ocean_optics`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md)
to inspect raw or relative values.

## Usage

``` r
from_ocean_optics(path, quantity = NULL, unit = NULL, calibration = NULL)
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

## Value

A validated `lux_spectrum` with import provenance in metadata.

## See also

[`read_ocean_optics`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md),
[`from_trios`](https://johnkirwan.github.io/luxR/reference/from_trios.md),
[`read_spectrum`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)
