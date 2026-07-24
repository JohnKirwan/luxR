# Photoreceptor absorptance from a normalised absorbance template (self-screening).

Converts a normalised visual-pigment absorbance spectrum (e.g. from
[`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md))
into the receptor's *absorptance* — the fraction of incident photons
actually captured at each wavelength — given the axial optical density
of the photoreceptor. At low optical density the absorptance is nearly
proportional to the template; at high optical density the peak saturates
toward 1 and the curve broadens ("self-screening"), so the realised
spectral sensitivity is wider than the bare pigment absorbance. This is
the sensitivity that should be fed to
[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)
for long or dense photoreceptors (e.g. deep-sea rods).

## Usage

``` r
receptor_absorptance(
  S,
  optical_density = NULL,
  alpha = NULL,
  path_length = NULL
)
```

## Arguments

- S:

  A data frame with columns `lambda` and `S` (a normalised absorbance
  template, e.g. from
  [`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)),
  or a bare numeric vector of normalised absorbance values.
  Re-normalised to a peak of 1 internally, so the optical density refers
  to the peak.

- optical_density:

  Peak axial optical density (base-10 absorbance), dimensionless.
  Typically ~0.3–0.5 for vertebrate cones, up to ~1 or more for long
  deep-sea rods. Supply this *or* (`alpha` and `path_length`), not both.

- alpha:

  Peak absorption coefficient per unit length (e.g. per µm).

- path_length:

  Outer-segment (path) length, in the same length unit as `alpha`.

## Value

If `S` is a data frame, a data frame with columns `lambda` and `S`
holding the absorptance (so it drops straight into
[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md));
if `S` is numeric, a numeric vector of absorptance values in \\\[0,
1\]\\.

## Details

For a peak-normalised absorbance \\S(\lambda)\\ and axial optical
density \\D\\ (base-10 absorbance along the outer segment at the peak),
the absorptance is \$\$A(\lambda) = 1 - 10^{-D\\S(\lambda)} = 1 -
e^{-\kappa\\S(\lambda)},\$\$ with \\\kappa = D\ln 10\\. Equivalently,
supply the peak absorption coefficient \\a\_{\max}\\ (`alpha`, per unit
length) and the outer-segment `path_length` \\\ell\\, giving \\\kappa =
a\_{\max}\ell\\ (Johnsen 2012, ch. 4, eq. 4.8).

## References

Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
Nature. Princeton University Press. (Ch. 4: absorptance and
self-screening.)

## See also

[`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md),
[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)

## Examples

``` r
lam  <- seq(300, 750, by = 1)
tmpl <- govardovskii_template(lam, lambda_max = 500)

# Realised sensitivity of a moderately dense cone (axial OD 0.4):
A <- receptor_absorptance(tmpl, optical_density = 0.4)

# A long deep-sea rod via Johnsen's absorption coefficient (0.064 / um):
A75 <- receptor_absorptance(tmpl, alpha = 0.064, path_length = 75)
```
