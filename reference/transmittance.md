# Beer-Lambert transmittance over a path.

Fraction of collimated light transmitted through a path of length
`path_length` in a medium with attenuation `coefficient`: \\T =
e^{-c\\\ell}\\ (Johnsen 2012, ch. 4). The fraction *absorbed* (or
attenuated) is \\1 - T\\; note that absorbances add over stacked paths
while transmittances multiply.

## Usage

``` r
transmittance(coefficient, path_length)
```

## Arguments

- coefficient:

  Attenuation (or absorption) coefficient (1/length). Vectorised.

- path_length:

  Path length in the same length unit. Vectorised.

## Value

Transmittance (0-1).

## References

Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 4.

## See also

[`absorbance`](https://johnkirwan.github.io/luxR/reference/absorbance.md),
[`beam_attenuation`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)

## Examples

``` r
transmittance(coefficient = 0.15, path_length = 10)
#> [1] 0.2231302
1 - transmittance(0.064, 10)   # hatchetfish rod: ~47% absorbed
#> [1] 0.4727076
```
