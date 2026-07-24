# Plot a list of lux_spectrum objects as overlaid lines.

Draws all spectra in `x` on a single plot with a shared wavelength axis.
Line colours cycle through the default palette. Names of the list (or
`meta$label` if present) are used for the legend. Additional arguments
in `...` are passed to the initial
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) call.

## Usage

``` r
plot_spectra(x, ...)
```

## Arguments

- x:

  A named or unnamed list of `lux_spectrum` objects.

- ...:

  Additional arguments passed to `plot` and `lines`.

## Value

`invisible(x)` — called for its side effect (plot).
