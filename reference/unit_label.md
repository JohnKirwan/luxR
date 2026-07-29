# Render a unit string for display

Formats a unit from the controlled vocabulary as a human-readable label
using SI negative exponents, for use in table headers, user interfaces,
and prose. The canonical unit strings stored in `lux_spectrum$unit` are
deliberately ASCII (`"umol/m2/s/nm"`) so they remain stable identifiers;
this function is the display counterpart.

## Usage

``` r
unit_label(unit)
```

## Arguments

- unit:

  A single unit string from the controlled vocabulary. See
  [`lux_spectrum`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
  for the valid values.

## Value

A length-1 character vector holding the rendered label, e.g. \\\mu
mol\\m^{-2}\\s^{-1}\\nm^{-1}\\ for `"umol/m2/s/nm"`.

## See also

[`unit_expression`](https://johnkirwan.github.io/luxR/reference/unit_expression.md)
for the plotmath equivalent used in plot axis labels.

## Examples

``` r
unit_label("umol/m2/s/nm")
#> [1] "µmol m⁻² s⁻¹ nm⁻¹"
unit_label("W/m2/sr/nm")
#> [1] "W m⁻² sr⁻¹ nm⁻¹"
```
