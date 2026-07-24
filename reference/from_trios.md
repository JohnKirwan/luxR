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
