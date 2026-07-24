# Fit a Govardovskii visual-pigment template to measured spectral sensitivity.

Finds the peak wavelength (\\\lambda\_{\max}\\) that minimises the sum
of squared residuals between the Govardovskii (2000) template and the
supplied sensitivity measurements. Uses
[`optimize`](https://rdrr.io/r/stats/optimize.html) for an exact
single-parameter search, so the result is a continuous estimate rather
than a grid point.

## Usage

``` r
fit_sensitivity(
  lambda,
  sensitivity,
  chromophore = c("A1", "A2"),
  lambda_max_range = c(300, 700)
)
```

## Arguments

- lambda:

  Wavelengths at which sensitivity was measured (nm).

- sensitivity:

  Measured spectral sensitivity. Normalised to \\\[0, 1\]\\ internally;
  need not be pre-normalised. `NA` values are silently dropped.

- chromophore:

  `"A1"` (11-cis retinal, default) or `"A2"` (11-cis
  3,4-didehydroretinal).

- lambda_max_range:

  Length-2 numeric vector giving the search interval for
  \\\lambda\_{\max}\\ in nm. Default `c(300, 700)`.

## Value

A list with components:

- `lambda_max`:

  Best-fit peak wavelength (nm).

- `chromophore`:

  Chromophore used.

- `SS`:

  Residual sum of squares at the optimum.

- `fitted`:

  Data frame with columns `lambda` and `S` giving the template evaluated
  on the input wavelength grid.

## References

Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000) In
search of the visual pigment template. Visual Neuroscience 17:509–528.

## See also

[`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)

## Examples

``` r
lam   <- seq(400, 700, by = 10)
true  <- govardovskii_template(lam, lambda_max = 530)$S
noisy <- pmax(0, true + rnorm(length(true), 0, 0.02))
fit   <- fit_sensitivity(lam, noisy)
fit$lambda_max  # should be close to 530
#> [1] 529.7793
```
