# Photoreceptor sensitivity matrix for colourvision

Assembles a species' validated chromatic receptors into the sensitivity
matrix `C` that colourvision models consume (a data frame whose first
column is wavelength and whose remaining columns are one photoreceptor
each). The receptors and their Govardovskii templates are exactly those
[`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
uses, so a colourvision model built on this matrix reproduces luxR's own
quantum catches.

## Usage

``` r
species_sensitivity_matrix(
  species,
  lambda = seq(300, 700, 1),
  receptor = NULL,
  weight = c("photon", "energy")
)
```

## Arguments

- species:

  Character scalar naming a species in `species_sensitivities` with at
  least one validated chromatic receptor.

- lambda:

  Numeric wavelength grid (nm); must be finite, strictly increasing, and
  unique. Defaults to `seq(300, 700, 1)`, colourvision's default `nm`.

- receptor:

  Optional character vector selecting a subset of the species' validated
  chromatic receptors; passed through to the same channel resolution
  [`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  uses.

- weight:

  One of `"photon"` (default, columns \\S\lambda\\) or `"energy"`
  (columns \\S\\).

## Value

A `data.frame` with a `wl` column plus one column per receptor, named
and ordered as luxR's channel definitions.

## Details

luxR integrates **photon** catch (proportional to \\E\lambda\\) while
colourvision integrates energy (\\\int I R C\\). With
`weight = "photon"` (the default) the columns are the sensitivities
multiplied by wavelength (\\S\lambda\\), so colourvision's energy
integral reproduces luxR's photon catch; the proportionality constant
cancels in the log RNL model. Use `weight = "energy"` for the raw
sensitivities.

## See also

[`as_colourvision`](https://johnkirwan.github.io/luxR/reference/as_colourvision.md),
[`colour_jnd`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md),
[`colourvision::RNLmodel`](https://rdrr.io/pkg/colourvision/man/RNLmodel.html)

## Examples

``` r
if (FALSE) { # \dontrun{
  C <- species_sensitivity_matrix("Apis mellifera")
} # }
```
