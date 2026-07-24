# Chromatic distance between two illuminants (Vorobyev-Osorio model).

Computes the just-noticeable difference (JND) between two spectral
stimuli as seen by a named species, using the receptor-noise-limited
colour discrimination model of Vorobyev & Osorio (1998). A \\\Delta S \<
1\\ indicates the pair is not reliably discriminable; \\\Delta S \geq
1\\ indicates discrimination is possible.

## Usage

``` r
colour_jnd(
  stim1,
  stim2,
  lambda,
  species,
  receptor = NULL,
  noise = 0.05,
  binwidth = NULL
)
```

## Arguments

- stim1, stim2:

  Numeric vectors of spectral irradiance (W m\\^{-2}\\ nm\\^{-1}\\) on
  the same `lambda` grid.

- lambda:

  Wavelength vector in nm.

- species:

  Species name matching `species_sensitivities$species`.

- receptor:

  Character vector of receptor class(es) to include (e.g.
  `c("L-cone","M-cone","S-cone")`). Default `NULL` uses the species'
  validated default chromatic channel from
  [`species_channels`](https://johnkirwan.github.io/luxR/reference/species_channels.md).
  Explicit receptors must belong to that channel.

- noise:

  Weber fraction(s). Either a single value applied to all receptors, or
  a named numeric vector with one entry per receptor class. Default 0.05
  (5% noise), typical for cones in well-lit conditions.

- binwidth:

  Wavelength bin width in nm. Inferred from `lambda` spacing if `NULL`
  (default).

## Value

Scalar: chromatic distance \\\Delta S\\ in just-noticeable differences
(JNDs).

## Details

For each receptor type \\i\\, the log-ratio of quantum catches \\\Delta
f_i = \ln(Q\_{2i} / Q\_{1i})\\ is computed, then the chromatic distance
is: \$\$\Delta S^2 = \Delta\mathbf{f}^\top \Sigma^{-1}
\Delta\mathbf{f} - \frac{(\mathbf{1}^\top \Sigma^{-1}
\Delta\mathbf{f})^2} {\mathbf{1}^\top \Sigma^{-1} \mathbf{1}}\$\$ where
\\\Sigma = \mathrm{diag}(e_i^2)\\ and \\e_i\\ is the noise (Weber
fraction) of receptor \\i\\. The formula is general for any number of
receptor types \\\geq 2\\.

## References

Vorobyev M, Osorio D (1998) Receptor noise as a determinant of colour
thresholds. Proc. R. Soc. B 265:351–358.

Vorobyev M et al. (2001) Colour thresholds and receptor noise: behaviour
and physiology compared. Vision Res. 41:639–653.

## See also

[`quantum_catch`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md),
[`species_brightness`](https://johnkirwan.github.io/luxR/reference/species_brightness.md),
[`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)

## Examples

``` r
sp1 <- solar_irradiance("clear_noon")
sp2 <- solar_irradiance("underwater_10m")

# Human trichromat
colour_jnd(sp1$irradiance, sp2$irradiance,
           lambda = sp1$wavelength, species = "Homo sapiens",
           receptor = c("L-cone", "M-cone", "S-cone"))
#> [1] 1.860537

# Zebrafish tetrachromat (all cones)
colour_jnd(sp1$irradiance, sp2$irradiance,
           lambda = sp1$wavelength, species = "Danio rerio")
#> [1] 1.758151
```
