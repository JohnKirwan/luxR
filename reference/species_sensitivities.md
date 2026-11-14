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

A data frame with 24 rows and 6 columns:

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
Lucas (2013) (*Homo sapiens*); Govardovskii et al. (2000), Table 1
(*Danio rerio*, as *Brachydanio rerio*, and the *Xenopus laevis* rod);
Peitsch et al. (1992) (*Apis mellifera*); Salcedo et al. (1999)
(*Drosophila melanogaster*); Hart et al. (2004) (*Callorhinchus milii*);
Yokoyama et al. (1999) (*Latimeria chalumnae*); Hawryshyn et al. (2003)
(*Oncorhynchus mykiss*).

*Danio rerio* cones are coded A1 and the *Xenopus laevis* rod A2, as in
Govardovskii et al. (2000). Those authors note that the Danio UV cone
deviates from the template (a raised long-wave tail), so its modelled
sensitivity is approximate. Only the principal (“red”) Xenopus rod is
included; its cones are omitted until a primary source for their peaks
is confirmed.

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
`data-raw/species_source_map.csv`. The legacy Hart et al. (2004)
attribution remains explicitly unverified pending primary-source
confirmation; the values are not silently relabelled.

Govardovskii VI, Fyhrquist N, Reuter T, Kuzmin DG, Donner K (2000). “In
Search of the Visual Pigment Template.” *Visual Neuroscience*,
**17**(4), 509–528.
[doi:10.1017/S0952523800174036](https://doi.org/10.1017/S0952523800174036)
.

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
#>       species receptor lambda_max chromophore channel_role
#> 6 Danio rerio  UV-cone        361          A1    chromatic
#> 7 Danio rerio   S-cone        414          A1    chromatic
#> 8 Danio rerio   M-cone        483          A1    chromatic
#> 9 Danio rerio   L-cone        567          A1    chromatic
#>                     source
#> 6 Govardovskii et al. 2000
#> 7 Govardovskii et al. 2000
#> 8 Govardovskii et al. 2000
#> 9 Govardovskii et al. 2000
```
