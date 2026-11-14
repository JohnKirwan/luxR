# luxR error conditions

Every error raised by luxR inherits from `luxR_error` and carries
exactly one *kind* class saying what went wrong, so callers can catch
errors by kind with
[`tryCatch()`](https://rdrr.io/r/base/conditions.html).

## Details

|  |  |
|----|----|
| `luxR_type_error` | Wrong R type or class: not numeric, not a `lux_spectrum`, not a list, not `TRUE`/`FALSE`, or an unsupported operand. |
| `luxR_value_error` | Right type, invalid value: out of range, non-finite, a required argument missing, a name not in a lookup (species, receptor, condition, water type, column), or a channel the species lacks. |
| `luxR_dimension_error` | Lengths or shapes disagree. |
| `luxR_grid_error` | A wavelength grid is invalid or incompatible: unordered, irregular, mismatched, or an empty window. |
| `luxR_unit_error` | A unit or physical quantity is unknown or incompatible. |
| `luxR_numerical_error` | A computation produced a non-finite or invalid result from valid input. |
| `luxR_format_error` | A file's contents do not match the expected format. |
| `luxR_data_error` | A bundled dataset or its metadata is inconsistent. |
| `luxR_dependency_error` | A suggested package needed for the call is not installed. |
| `luxR_internal_error` | A package invariant broke; please report it as a luxR bug. |

Errors raised while importing a file also carry `luxR_import_error`,
between the kind and `luxR_error`, whatever their kind.

Conditions carry fields describing the failure where they apply: `field`
(the argument or column at fault), `value` (the offending value) and
`index` (its position). Import errors add `line`, `row` and the source
file's context (path, checksum, reader configuration).

## Examples

``` r
tryCatch(
  lux_spectrum(1:3, c(400, 410, 405), "irradiance", "W/m2/nm"),
  luxR_error = function(e) class(e)[1]
)
#> [1] "luxR_grid_error"
```
