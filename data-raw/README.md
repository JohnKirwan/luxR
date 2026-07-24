# Bundled data sources

## Reproducibility contract

`dataset_manifest.csv` inventories every bundled `.rda`, pins its reviewable
source artifact by MD5, and records source identifiers, citation keys, retrieval
date, license/status, units, wavelength domain, processing steps, and processing
model version. Generated objects carry these stable fields in the
`luxR.provenance` attribute.

Run the offline verifier from the package root with:

```sh
Rscript --vanilla data-raw/verify_bundled_data.R
```

It checks manifest coverage, source checksums, bibliography keys, and bundled
metadata, then rebuilds every local-source dataset into a temporary directory
and requires exact equality. Pass `--network` to additionally download and
rebuild the checksum-pinned CIE tables. Builders stage and validate all outputs
before atomically replacing existing files.

### Five reproducibility elements

Each element is recorded by a mechanism that regenerates or computes its value,
so it survives a repository restart without manual re-entry:

- **Dataset checksums** — generated from `dataset_manifest.csv` by
  `provenance_helpers.R` and verified by `verify_bundled_data.R`; user imports
  are checksummed at read time via `tools::md5sum()` in
  `R/import_validation.R`. Never hand-pinned in `R/` source (enforced by
  `tests/testthat/test-reproducibility-guard.R`).
- **Code commit** — `.luxr_code_commit()` (`R/data_provenance.R`) reads
  `GithubSHA1` from the installed DESCRIPTION, falls back to the `GITHUB_SHA`
  environment variable, then to `NA_character_`. Repopulates automatically on
  the next GitHub install.
- **Model version** — `.luxr_package_version()` (`R/data_provenance.R`) plus the
  per-reader/model version constants (`.SPECTRUM_IMPORT_MODEL_VERSION`,
  `.POLARIZATION_MODEL_VERSION`, `processing_version` in the manifest).
- **Configuration** — the `configuration` field on bundled provenance and the
  read/scaling/resampling policy captured in `read_spectrum` provenance.
- **Seeds** — *partially captured today; forward contract deferred.* luxR runs
  no stochastic sampling yet (no stochastic sampling in package logic; the only `rnorm` in `R/` is in a roxygen `@examples` block), but
  the detection and polarization runtime contexts (`R/detectability.R`,
  `R/polarization.R`) already snapshot the global `.Random.seed` into a
  `random_seed` field when one exists. This records *ambient* RNG state, not a seed
  a computation consumed, and is present on only those two of the provenance
  surfaces — so it is a partial, informational record, not a reproducibility
  guarantee. When actual stochastic modules (detection, polarization, or
  receptor-noise sampling) are added, each stochastic entry point MUST:
  - accept an explicit `seed` argument (no implicit `set.seed()` on the global
    default RNG, no silently invented seed — consistent with the fail-fast
    policy); and
  - record, into its runtime provenance record, a fragment with exactly these
    field names: `seed` (the integer seed used), `rng_kind`
    (`paste(RNGkind(), collapse = "/")`), and `r_version` (`R.version.string`),
    superseding the ambient `random_seed` snapshot for that computation.

  This field naming is fixed now so the provenance record shape stays stable
  when the first stochastic caller lands.

## Legacy canonical optical datasets

`Naples`, `jerlov_types`, and `solar_spectra` are regenerated from explicitly
labelled canonical legacy snapshots. These snapshots make the historical
package payload deterministic and reviewable; they are not represented as
primary raw measurements. Rebuild them with:

```sh
Rscript --vanilla data-raw/build_legacy_optical_data.R
```

`jerlov_types` is supported only from 350 to 700 nm in 25 nm steps. The
historical underwater entries in `solar_spectra` use constant endpoint
extension outside this supported domain. The unified legacy builder records
that policy, both wavelength ranges, and the Jerlov source checksum on each
underwater source so the assumption is explicit.

## CIE luminous-efficiency functions

`CIE1931` and `CIE_scotopic` are generated from the official CIE open datasets
accompanying CIE 018:2019. Rebuild both `.rda` files from the package root with:

```sh
Rscript --vanilla data-raw/build_cie_efficiency_data.R
```

The build script downloads each 1 nm table and its companion CIE metadata,
verifies their pinned MD5 checksums, validates the wavelength grids and values,
and stores the source URL, DOI, checksums, retrieval date, standard, and
CC BY-SA 4.0 license as data-frame attributes. Both generated files are staged
and round-trip validated before the existing datasets are replaced; a failed
replacement is rolled back.

## Species data sources

`species_sensitivities.csv` is the reviewable source for the bundled receptor
records. `species_channels.csv` separately records receptor combinations that
are supported as model channels. `species_source_map.csv` maps every source
label to a bibliography key and an explicit citation-verification status.
Rebuild all three `.rda` files from the package root with:

```sh
Rscript data-raw/build_species_data.R
```

The `channel_role` vocabulary is `chromatic`, `achromatic`, `irradiance`,
`polarization`, and `fluorescence`. A receptor's role does not by itself make a
species eligible for a model. Eligibility requires a complete, cited membership
in `species_channels`, including exactly one default channel for a species and
role.

The initial chromatic-channel set is deliberately conservative:

- human S-, M-, and L-cones;
- zebrafish UV-, S-, M-, and L-cones;
- honeybee UV, blue, and green receptors.

The validated achromatic set is likewise behavioural and context-specific:

- adult, light-adapted zebrafish L-cone motion (Krauss & Neumeyer 2003);
- honeybee green-receptor target contrast (Niggebrugge & Hempel de Ibarra 2003);
- fruit-fly R1-6 optomotor responses (Yamaguchi et al. 2008).

`species_channel_support.csv` contains an explicit supported or unavailable
decision for both model roles and every bundled species. In particular, a rod
record is not promoted to a default without an adaptation-specific model and a
behavioural source.

Other pigment records remain available to `species_LEF()`, but incomplete or
ambiguous receptor sets are not silently promoted to colour models.

The former *Aequorea victoria* GFP record is excluded because GFP is a
fluorescent protein, not an A1 visual pigment to which the Govardovskii template
applies. The former generic “Mantis shrimp” record is excluded because it did
not identify a taxon or a literature-supported receptor set.
