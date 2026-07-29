# Render a unit string as a plotmath expression

Formats a unit from the controlled vocabulary as a plotmath language
object with SI negative exponents, suitable for passing directly as the
`xlab` or `ylab` of a base graphics plot.

## Usage

``` r
unit_expression(unit)
```

## Arguments

- unit:

  A single unit string from the controlled vocabulary. See
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
  for the valid values.

## Value

A language object suitable for use as a plot label.

## See also

[`unit_label`](https://johnkirwan.github.io/luxR/reference/unit_label.md)
for the plain-text equivalent.

## Examples

``` r
plot(400:700, rep(1, 301), type = "l",
     xlab = "Wavelength (nm)", ylab = unit_expression("W/m2/nm"))
```
