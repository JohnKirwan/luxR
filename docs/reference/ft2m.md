# Convert feet to metres.

Vectorised; passes through `NA`.

## Usage

``` r
ft2m(z)
```

## Arguments

- z:

  Depth or distance in feet.

## Value

Numeric vector in metres.

## See also

[`m2ft`](https://johnkirwan.github.io/luxR/reference/m2ft.md)

## Examples

``` r
propagate_depth(8260, Kd = 0.062, from = ft2m(72), to = 0)
#> [1] 32202.75
```
