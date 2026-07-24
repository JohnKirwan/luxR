# Absorbance (optical density) from transmittance.

The negative logarithm of transmittance. Natural-log absorbance
(`base = "e"`) is used by vision scientists and oceanographers; base-10
absorbance (`base = "10"`) is "optical density" (OD), used by chemists
and filter makers. They differ by a constant: \\OD = A\log\_{10}e
\approx 0.4343\\A\\ (Johnsen 2012, ch. 4).

## Usage

``` r
absorbance(transmittance, base = c("e", "10"))
```

## Arguments

- transmittance:

  Transmittance (0-1\]. Vectorised.

- base:

  `"e"` (natural-log absorbance, default) or `"10"` (optical density).

## Value

Absorbance / optical density (dimensionless, \\\geq 0\\).

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 4.

## See also

[`transmittance`](https://johnkirwan.github.io/luxR/reference/transmittance.md)

## Examples

``` r
absorbance(0.01, base = "10")   # OD = 2 (1% transmitted)
#> [1] 2
absorbance(exp(-1.5))           # natural-log absorbance = 1.5
#> [1] 1.5
```
