# Photoreceptor spectral sensitivities for selected species.

Peak wavelengths and chromophore types for visual photoreceptors of
representative species from vertebrate and invertebrate taxa. Used by
[`species_LEF`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
and
[`species_brightness`](https://johnkirwan.github.io/luxR/reference/species_brightness.md).

## Usage

``` r
species_sensitivities
```

## Format

A data frame with 27 rows and 6 columns:

- species:

  Scientific name.

- receptor:

  Receptor class (e.g. `"L-cone"`, `"rod"`).

- lambda_max:

  Peak absorbance wavelength in nm.

- chromophore:

  `"A1"` (11-cis retinal) or `"A2"` (11-cis 3,4-didehydroretinal).

- channel_role:

  Primary biological role from the controlled vocabulary `"chromatic"`,
  `"achromatic"`, `"irradiance"`, `"polarization"`, or `"fluorescence"`.

- source:

  Literature citation for the lambda_max value.

## Details

Each row's `lambda_max` is taken from the primary-literature citation
recorded in its `source` column; luxR reconstructs full sensitivity
curves from these peaks using the Govardovskii et al. (2000)
visual-pigment template (see
[`govardovskii_template`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)).

Per-receptor lambda_max sources: Bowmaker & Dartnall (1980) and Bailes &
Lucas (2013) (*Homo sapiens*); Robinson et al. (1993) (*Danio rerio*);
Peitsch et al. (1992) (*Apis mellifera*); Salcedo et al. (1999)
(*Drosophila melanogaster*); Hart et al. (2004) (*Callorhinchus milii*);
Yokoyama et al. (1999) (*Latimeria chalumnae*); Yoshiura et al. (2011)
(*Xenopus laevis*); Hawryshyn et al. (2003) (*Oncorhynchus mykiss*).

A role label does not by itself validate a receptor for a model.
Complete, cited channel memberships are recorded separately in
[`species_channels`](https://johnkirwan.github.io/luxR/reference/species_channels.md).
The generic mantis-shrimp record and *Aequorea victoria* GFP previously
included in this table were removed because they are not supported
visual-pigment channel records.

## References

Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000) In
search of the visual pigment template. Visual Neuroscience 17:509-528.

Full citation keys and their verification status are recorded in
`data-raw/species_source_map.csv`. The legacy Hart et al. (2004) and
Yoshiura et al. (2011) attributions remain explicitly unverified pending
primary-source confirmation; the values are not silently relabelled.

Robinson J, Schmitt EA, Hárosi FI, Reece RJ, Dowling JE (1993).
“Zebrafish Ultraviolet Visual Pigment: Absorption Spectrum, Sequence,
and Localization.” *Proceedings of the National Academy of Sciences*,
**90**(13), 6009–6012.
[doi:10.1073/pnas.90.13.6009](https://doi.org/10.1073/pnas.90.13.6009) .
[2026-06-04](https://johnkirwan.github.io/luxR/reference/2026-06-04).

Hawryshyn CW, Martens G, Allison WT, Anholt BR (2003). “Regeneration of
Ultraviolet-Sensitive Cones in the Retinal Cone Mosaic of
Thyroxin-Challenged Post-Juvenile Rainbow Trout (Oncorhynchus Mykiss).”
*Journal of Experimental Biology*, **206**(15), 2665–2673. ISSN
0022-0949. [doi:10.1242/jeb.00470](https://doi.org/10.1242/jeb.00470) .
[2026-06-04](https://johnkirwan.github.io/luxR/reference/2026-06-04).

## Examples

``` r
data(species_sensitivities)
subset(species_sensitivities, species == "Danio rerio")
#>       species receptor lambda_max chromophore channel_role               source
#> 6 Danio rerio  UV-cone        362          A2    chromatic Robinson et al. 1993
#> 7 Danio rerio   S-cone        415          A2    chromatic Robinson et al. 1993
#> 8 Danio rerio   M-cone        480          A2    chromatic Robinson et al. 1993
#> 9 Danio rerio   L-cone        561          A2    chromatic Robinson et al. 1993
```
