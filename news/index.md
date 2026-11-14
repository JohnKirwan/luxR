# Changelog

## luxR 0.1.1

### Breaking changes

- [`as_rspec()`](https://johnkirwan.github.io/luxR/reference/as_rspec.md)
  on a list of spectra now requires one shared wavelength grid and
  raises a `luxR_value_error` otherwise; use
  [`resample_spectrum()`](https://johnkirwan.github.io/luxR/reference/resample_spectrum.md)
  first. It previously extended shorter spectra by repeating their end
  values.
- Achromatic contrast and receptor catches no longer depend on how far
  the wavelength grid extends. Previously they summed over whatever grid
  was supplied, so the same object gave a species-free Weber contrast of
  -0.19 on a 300-800 nm grid, -0.15 on 400-700 nm and -0.28 on 300-600
  nm; it is now -0.146 on any grid that covers 400-700 nm.
  - `species = NULL` achromatic brightness in
    [`inherent_contrast()`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
    [`detection_range()`](https://johnkirwan.github.io/luxR/reference/detection_range.md)
    and
    [`detectability()`](https://johnkirwan.github.io/luxR/reference/detectability.md)
    is now photon radiance over 400-700 nm (PAR). The grid must cover
    400-700 nm.
  - Receptor catches in
    [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
    and in the species achromatic and chromatic channels of the
    detection functions integrate over a new `band` argument, default
    `c(300, 700)` nm (previously the grid’s overlap with 300-750 nm).
    The grid must cover the band, or a `luxR_grid_error` is raised; edge
    bins count only their in-band width. Values change slightly
    (e.g. -0.1596 to -0.1595 for a Danio rerio achromatic contrast).
  - Jerlov-propagated light fields start at 350 nm, so pass
    `band = c(350, 700)` to model them; the UV catch below 350 nm, which
    was previously dropped without notice, is then excluded by choice.
    The Shiny app does this and states the band it used beside each
    result.
  - A `binwidth` that does not match the grid spacing is now rejected by
    these functions.
- Every luxR error now inherits `luxR_error` and carries exactly one
  kind class: `luxR_type_error`, `luxR_value_error`,
  `luxR_dimension_error`, `luxR_grid_error`, `luxR_unit_error`,
  `luxR_numerical_error`, `luxR_format_error`, `luxR_data_error`,
  `luxR_dependency_error` or `luxR_internal_error`. Errors raised while
  importing a file also carry `luxR_import_error`. See
  `?luxR-conditions`. The previous ~47 classes are gone:
  - `lux_spectrum_<kind>_error` becomes `luxR_<kind>_error`, except
    `lux_spectrum_quantity_error` (now `luxR_unit_error`) and
    `lux_spectrum_depth_error` (now `luxR_value_error`). Quantity and
    unit mismatches that raised `lux_spectrum_dimension_error` are now
    `luxR_unit_error`.
  - `luxR_spectrum_schema_error` becomes `luxR_format_error` for file
    contents, `luxR_grid_error` for an unordered imported grid, and
    `luxR_type_error`/`luxR_value_error` for reader arguments.
    `luxR_spectrum_dimension_error` becomes `luxR_unit_error`.
  - `luxR_jerlov_type_error` (unknown water type) and
    `luxR_jerlov_range_error` become `luxR_value_error`.
  - Failures of a computation on valid input (`*_calculation_error`,
    `*_numerical_error`, `*_interpolation_error`, `*_invariant_error`)
    become `luxR_numerical_error`.
  - `lux_species_data_error` and `luxR_source_metadata_error` become
    `luxR_data_error`. Species, sensitivity, detection and polarization
    input errors become `luxR_type_error`, `luxR_value_error`,
    `luxR_dimension_error`, `luxR_grid_error` or `luxR_unit_error`.
  - The parent classes `lux_spectrum_validation_error`,
    `luxR_spectrum_import_error`, `luxR_jerlov_error`,
    `luxR_polarization_error`, `lux_detection_error` and
    `lux_species_model_error` are replaced by `luxR_error` and
    `luxR_import_error`.
- Detection and polarization errors no longer carry `random_seed`;
  neither model uses random numbers.
- Errors from spectrum arithmetic and subsetting, unit conversion, the
  optical-property helpers, species lookups and the pavo, photobiology
  and colourvision bridges, previously untyped, now carry kind classes.
  A missing suggested package (shiny, pavo, photobiology) raises
  `luxR_dependency_error`.
- The A2
  [`govardovskii_template()`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  now follows Govardovskii et al. (2000):
  - The α-band uses eqns 6a/6b with B = 20.85, b = 0.9101, C = -10.37, c
    = 1.1123 and D = 0.5343.
  - The β-band uses A_β = 0.37 with eqns 8a/8b.

  Previously A2 used wrong α constants and the A1 β-band, which made A2
  narrower than A1; at λmax 620 nm the FWHM is now 147 nm, against 125
  nm for A1. A2 `lambda_max` is limited to the template’s fitted range,
  440–620 nm, and
  [`fit_sensitivity()`](https://johnkirwan.github.io/luxR/reference/fit_sensitivity.md)
  searches that range by default (`lambda_max_range = NULL`). A1 output
  is unchanged.
- `species_sensitivities` corrections, now checked against their sources
  (dataset version `species-v2`):
  - *Homo sapiens* uses Bowmaker & Dartnall (1980): rod 497.6, S 420.3,
    M 533.8 and L 562.8 nm (previously 498, 437, 533 and 564).
  - *Danio rerio* cones are now **A1** (previously A2), with peaks from
    Govardovskii et al. (2000) Table 1: 361, 414, 483 and 567 nm
    (previously 362, 415, 480 and 561, attributed to Robinson et
    al. 1993, which reports only the UV cone).
  - *Xenopus laevis* has a single A2 rod at 523 nm (Govardovskii et al.
    2000). The previous A1 rod and the cones, attributed to an
    unverified source, were removed.
- [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md)
  now returns the photon fraction by default, since PAR is defined as a
  photon flux. `basis = "energy"` gives the energy fraction (the
  previous result for energy input). Numeric input states its unit with
  `photonic`, as in
  [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md);
  a `lux_spectrum` is converted from its own unit, so µmol and W spectra
  now give the same answer. Non-irradiance spectra and negative values
  are rejected, and a zero total raises a `luxR_value_error` instead of
  returning `NA`.
- [`secchi_depth()`](https://johnkirwan.github.io/luxR/reference/secchi_depth.md)
  weights the bins straddling 400 and 700 nm by their overlap with the
  window instead of counting them whole, converts a `lux_spectrum` to W
  m^-2 nm^-1 before weighting (µmol spectra previously weighted by
  photon flux), and validates its input: `Kd` must be positive and
  finite, `lambda` and `irradiance` come together and match `Kd` in
  length, irradiance is non-negative with some in the window, and only
  irradiance spectra are accepted.
- [`secchi_depth()`](https://johnkirwan.github.io/luxR/reference/secchi_depth.md)
  now weights Kd by photon flux by default, because vision is
  photon-based. `basis = "energy"` gives the previous energy weighting.
  Numeric irradiance states its unit with `photonic`, as in
  [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md).
  Setting `photonic` together with `spectrum` is an error.
- [`photic_depth()`](https://johnkirwan.github.io/luxR/reference/photic_depth.md),
  [`weber_contrast()`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md),
  [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)
  and the numeric
  [`fit_Kd()`](https://johnkirwan.github.io/luxR/reference/fit_Kd.md)
  validate their input and raise typed luxR errors: non-finite
  (including `NA`) or out-of-range values, `fraction >= 1`, `z2 <= z1`,
  and vectors whose lengths neither match nor are 1.
  [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)
  no longer lets `NA` through, and
  [`weber_contrast()`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md)
  rejects a negative target or background.
- A wavelength grid’s bin width is no longer guessed.
  [`lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
  with a single wavelength now needs an explicit `binwidth` (it was 1
  nm). File readers and
  [`as_lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
  conversions, which take no `binwidth`, therefore reject
  single-wavelength input.
  [`resample_spectrum()`](https://johnkirwan.github.io/luxR/reference/resample_spectrum.md)
  needs at least two regularly spaced target wavelengths.
  [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md),
  the Shiny app and every
  [`broadband2spectrum()`](https://johnkirwan.github.io/luxR/reference/broadband2spectrum.md)
  unit raise a `luxR_grid_error` for an irregular grid instead of
  averaging its spacing.
  [`broadband2spectrum()`](https://johnkirwan.github.io/luxR/reference/broadband2spectrum.md)
  also rejects a negative or non-finite `value` or `depth`, and a
  reference spectrum that integrates to zero.
- [`receptor_absorptance()`](https://johnkirwan.github.io/luxR/reference/receptor_absorptance.md)
  no longer rescales `S` to its on-grid maximum, which undid the
  true-peak normalisation of
  [`govardovskii_template()`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  on a grid that misses the peak. `S` must be a peak-normalised template
  (finite, in \[0, 1\]); a value above 1 is a `luxR_value_error`.
  Argument errors are now typed (`luxR_type_error`, `luxR_value_error`).
- [`fit_sensitivity()`](https://johnkirwan.github.io/luxR/reference/fit_sensitivity.md)
  rejects a spectrum whose largest value is not positive (e.g. an
  inverted one, which was fitted upside down) and infinite values, and
  replaces its [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html)
  checks with typed luxR errors. `NA` values are still dropped as
  unmeasured wavelengths.
- [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  on a `lux_spectrum` gives a clear error when `lambda` or `binwidth` is
  supplied (both come from the object); `binwidth` used to fail with
  “matched by multiple actual arguments”.

### Unit handling

- [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)
  now rejects radiance and reflectance `lux_spectrum` objects with a
  `luxR_unit_error`. Photon-radiance spectra were previously integrated
  as if they were W m^-2 nm^-1.

- [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  converts a photon-unit `lux_spectrum` to W m^-2 nm^-1 before
  integrating, as documented. `photonic = TRUE` no longer applies the
  photon conversion twice, and `photonic = FALSE` now returns W m^-2
  instead of a photon-unit integral. Non-irradiance spectra are
  rejected.

- Unit conversion is driven by one internal unit table and one pair of
  physical constants.

- New irradiance unit `"uW/cm2/nm"` (1e-2 W m^-2 nm^-1), the unit Ocean
  Optics software writes for absolute irradiance.
  [`read_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md),
  [`from_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md),
  [`convert_unit()`](https://johnkirwan.github.io/luxR/reference/convert_unit.md)
  and
  [`as_source_spct()`](https://johnkirwan.github.io/luxR/reference/as_source_spct.md)
  accept it. \## Numerical correctness These fixes change returned
  numbers or turn silent results into errors.

- [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md),
  [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md),
  [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  and `broadband2spectrum(unit = "umol")` now treat each sample as a bin
  centred on its wavelength and count only the part of an edge bin that
  lies inside the band. Previously a bin centred on a band limit was
  counted whole, which overstated PAR by about 3.3% on a 10 nm grid with
  points at 400 and 700 nm.
  [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  with no limits still integrates the full extent of the bins.

- The same functions now raise a `luxR_grid_error` for an irregular or
  descending wavelength grid, for a `binwidth` that differs from the
  grid spacing, and (except
  [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md))
  for a grid whose bins do not span the band. A single wavelength needs
  an explicit `binwidth`, a spectrum whose length differs from `lambda`
  is a `luxR_dimension_error`, and non-finite spectral values are a
  `luxR_value_error`.

- [`govardovskii_template()`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  is normalised to the template’s own peak rather than to the largest
  value on the supplied grid. A pigment whose peak lies outside the grid
  (a 360 nm cone on 400-700 nm) is no longer rescaled to 1; this also
  affects
  [`species_sensitivity_matrix()`](https://johnkirwan.github.io/luxR/reference/species_sensitivity_matrix.md),
  [`species_LEF()`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
  and
  [`species_brightness()`](https://johnkirwan.github.io/luxR/reference/species_brightness.md)
  on such grids. When the grid spans the peak, values fall slightly
  because no grid point sits exactly on it: by up to about 4e-5 on a 1
  nm grid and up to about 0.5% on a 10 nm grid whose points straddle the
  peak. `lambda_max` outside 300-700 nm is now rejected.

- [`fit_sensitivity()`](https://johnkirwan.github.io/luxR/reference/fit_sensitivity.md)
  fits the template’s amplitude as well as its peak and returns it as
  `amplitude`, so a spectrum truncated before its peak is fitted
  correctly. `lambda_max_range` must lie within 300-700 nm.

- [`fit_Kd()`](https://johnkirwan.github.io/luxR/reference/fit_Kd.md) on
  `lux_spectrum` inputs converts both to W m^-2 nm^-1 and requires
  spectral irradiance on one shared wavelength grid. Mixed energy and
  photon units previously gave a wrong, even negative, Kd. A numeric
  `E2` with a `lux_spectrum` `E1` is now an error.

- `resample_spectrum(method = "cubic")` no longer extrapolates outside
  the source range: it returns `NA` under `rule = 1` and the boundary
  value under `rule = 2`, as documented. A `rule` other than 1 or 2 is
  rejected for both methods, as are non-finite values in the spectrum or
  either wavelength grid, which were previously dropped.

### Bug fixes

- [`read_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md)
  and
  [`from_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md)
  now read SpectraSuite processed exports: the `Spectrometers:` line, an
  integration time with a `(serial)` suffix (which must name that
  spectrometer) and the `Number of Pixels in Processed Spectrum:` count,
  which was previously not checked. OceanView’s
  `Integration Time (sec):` is parsed and converted to microseconds; it
  was previously dropped. A new `check_pixels` argument (default `TRUE`)
  lets spliced or multi-spectrometer exports, whose header gives one
  detector’s pixel count, be read on explicit request; the choice is
  recorded in the import provenance.
- The Shiny app’s spectral-sensitivity plot no longer extends the light
  spectrum beyond its measured range; the curve stops at the data.
- Functions that use bundled datasets
  ([`jerlov_Kd()`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md),
  [`irradiance2lux()`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md),
  [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md),
  [`solar_irradiance()`](https://johnkirwan.github.io/luxR/reference/solar_irradiance.md)
  and others) now work when called as `luxR::fn()` without attaching the
  package. Previously they failed with “object not found”.
- The `code_commit` recorded in import, propagation, polarization and
  detectability provenance no longer comes from the `GITHUB_SHA`
  environment variable, which in a user’s own CI run named the user’s
  repository commit. It is now read from the installed package
  (`RemoteSha` or `GithubSHA1`, set by r-universe, pak and remotes) and
  is `NA` for CRAN or local source installs.
- [`plot_spectra()`](https://johnkirwan.github.io/luxR/reference/plot_spectra.md)
  now rejects a single `lux_spectrum` (it needs a list), non-spectrum
  list elements, and spectra in different units. Previously a bare
  spectrum failed with “\$ operator is invalid for atomic vectors”, and
  mixed units were drawn on one axis labelled with the first spectrum’s
  unit.
- `citation("luxR")` now takes its version and year from DESCRIPTION. It
  previously failed when the package was not installed and gave the
  current year rather than the release year.

### Package identity

- Added the hexagonal luxR logo with a transparent background. The logo
  is displayed in the GitHub and r-universe README and in the bundled
  Shiny app.
- Package metadata and the recommended citation identify the maintainer
  as John D Kirwan.

### Validation

- [`read_instrument_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_instrument_spectrum.md)
  now delegates single-file parsing to `lightr` while preserving
  irregular native grids, signed processed values, instrument metadata,
  parser notices, checksums, exact parser configuration, and the
  `lightr` version in a strict intermediate record.
  [`read_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)
  converts that record only after explicit measurement, input scale,
  calibration, resampling, and negative-value policies are supplied.
  Known format/quantity contradictions fail, percent reflectance is
  explicitly converted to a fraction, and transmittance, absorbance, or
  raw records cannot be mislabeled as a `lux_spectrum`.
- Beer–Lambert attenuation with wavelength-specific diffuse attenuation
  is now explicitly the principal lightweight propagation tier.
  Function, vignette, scope, and Shiny documentation state its
  homogeneous-column, independent-wavelength assumptions and distinguish
  it from radiative transfer. Propagation rejects non-irradiance
  spectral objects and non-finite numerical results; outputs and app
  downloads record the propagation model version and Jerlov provenance.
- The Shiny explorer now has one tested, ordered tab registry: Depth
  Propagation, Species Perception, Colour discrimination, Visibility,
  and Detection. Documentation and navigation are checked against that
  registry, and every result identifies its scientific quantity, units,
  source context, and model assumptions.
- Every bundled dataset now has a checksum-pinned manifest entry, a
  deterministic generator, standardized source/unit/domain/processing
  provenance, and an offline CI rebuild check. Bundled reader and Shiny
  export metadata carry source checksums and processing versions; legacy
  snapshots and unresolved source attributions are labelled explicitly.
- Polarization helpers now fail fast on non-finite, physically
  impossible, or length-incompatible inputs.
  [`degree_of_polarization()`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md)
  rejects Stokes states with polarized intensity greater than total
  intensity.
- [`underwater_polarization()`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)
  is explicitly identified in documentation and result metadata as an
  uncalibrated, tunable Rayleigh-like approximation. Its illustrative
  defaults now record their evidence limits, and literature-based
  angular benchmark tests prevent qualitative agreement from being
  presented as quantitative calibration.
- [`jerlov_Kd()`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)
  now fails outside the bundled table’s supported 350–700 nm domain by
  default. Constant endpoint extension requires explicit opt-in and
  carries the interpolation policy, table checksum, build commit, and
  model version as provenance. Full-spectrum propagation APIs and Shiny
  controls now require an explicit error, trim, or constant-extension
  policy, and Shiny downloads record the selected and calculated
  wavelength ranges. Historical underwater solar sources explicitly
  identify their original constant endpoint-extension assumption.
- Photopic and scotopic illuminance are now calculated from the official
  CIE 018:2019 1 nm luminous-efficiency tables. The previous coarse
  bundled tables contained incorrect values, so corrected illuminance
  results can differ materially, especially for narrow-band and scotopic
  spectra. Both tables and their CIE metadata are checksum-pinned,
  reproducibly generated, and independently integrated against
  `photobiology` in guarded tests.
- Detection-distance outputs now identify themselves as unvalidated
  scenario estimates. Detection spectra, thresholds, attenuation,
  geometry, and search bounds fail on non-finite or non-physical inputs;
  criteria that remain detectable at the finite search limit are
  explicitly censored rather than returned as infinite ranges.
- `detection_range(model = "spectral_path")` now propagates object,
  background, and veiling radiances wavelength by wavelength and
  recomputes achromatic and chromatic receptor signals at every
  evaluated distance. A deterministic benchmark checks the propagated
  zebrafish chromatic signal against `pavo`.
- [`quantum_catch()`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)
  now requires an explicit energy, raw-photon, or molar input unit and
  returns sensitivity-weighted photon irradiance in photons m^-2 s^-1.
  It no longer implies an absolute per-receptor rate; the Shiny result
  and CSV download record the source, sensitivity, integration settings,
  and omitted geometry and efficiency terms.
- Govardovskii pigment templates are now explicitly normalised to a peak
  of one, matching their documented range and the quantum-catch input
  invariant.
- Depth Propagation plots and CSV downloads now record the source
  condition, reference medium and depth, applied surface-transmission
  model and parameters, Jerlov type, and absolute target depth for
  reproducible interpretation.
- Bundled and uploaded in-water spectra now propagate from their
  declared reference depth to an absolute target depth below the
  surface. Targets above the known source depth fail explicitly instead
  of silently treating an underwater spectrum as a depth-zero source;
  Shiny uploads now require a visible reference-depth declaration.
- Species detection now uses only cited default channels: adult
  zebrafish L-cone motion, honeybee green-receptor contrast, and
  fruit-fly R1-6 motion are the initial achromatic models. A complete
  `species_channel_support` audit records supported and unavailable
  chromatic/achromatic combinations, and species without a validated
  default fail instead of pooling all known receptors.
- [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  now selects only a species’ validated default chromatic channel. Human
  defaults contain S-, M-, and L-cones only; rods and ipRGCs are
  rejected as chromatic inputs. Receptor noise and quantum catches now
  fail explicitly when non-finite or non-positive instead of silently
  substituting machine epsilon.
- `species_sensitivities` now records a controlled `channel_role`, and
  the new `species_channels` dataset records cited, model-eligible
  receptor combinations. Both datasets rebuild from checked-in CSV
  sources. The unsupported GFP and unidentified mantis-shrimp records
  were removed.
- [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  is now cross-validated against
  [pavo](https://CRAN.R-project.org/package=pavo)’s
  [`vismodel()`](https://pavo.colrverse.com/reference/vismodel.html) +
  [`coldist()`](https://pavo.colrverse.com/reference/coldist.html):
  given matched sensitivities, stimuli, and noise the two agree to
  machine precision. See the *Visual ecology* vignette and a guarded
  test (`pavo` is a `Suggests` dependency).
- [`W2photon()`](https://johnkirwan.github.io/luxR/reference/W2photon.md)
  /
  [`photon2W()`](https://johnkirwan.github.io/luxR/reference/photon2W.md)
  are cross-validated against
  [photobiology](https://CRAN.R-project.org/package=photobiology)’s
  `e2quantum_multipliers()`: the energy ↔︎ photon conversion agrees to
  machine precision. See the *Light in water* vignette and a guarded
  test (`photobiology` is a `Suggests` dependency).

### New features

- Units now render with SI superscripts (`m⁻²`) in plot axis labels, the
  Shiny app, and the documentation. New exported helpers
  [`unit_label()`](https://johnkirwan.github.io/luxR/reference/unit_label.md)
  and
  [`unit_expression()`](https://johnkirwan.github.io/luxR/reference/unit_expression.md)
  format a canonical unit string for display. The canonical unit strings
  themselves (`"W/m2/nm"` and siblings) and the
  [`print()`](https://rdrr.io/r/base/print.html) output for
  `lux_spectrum` are unchanged.
- Polarization of the underwater light field (a lightweight analytic
  single-scattering model):
  [`underwater_polarization()`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)
  returns the degree and angle of polarization as a function of viewing
  direction, solar elevation, and depth, with helpers
  [`degree_of_polarization()`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md)
  /
  [`angle_of_polarization()`](https://johnkirwan.github.io/luxR/reference/angle_of_polarization.md)
  (Stokes descriptors),
  [`scattering_angle()`](https://johnkirwan.github.io/luxR/reference/scattering_angle.md),
  and
  [`refracted_solar_angle()`](https://johnkirwan.github.io/luxR/reference/refracted_solar_angle.md).
  See the new *Polarization of the underwater light field* vignette. A
  new `SCOPE.md` documents luxR’s focus and what is deferred to pavo /
  photobiology / HydroLight.
  [`polarization_contrast()`](https://johnkirwan.github.io/luxR/reference/polarization_contrast.md)
  gives the polarization distance between a target and its background
  for a polarization-sensitive viewer (How & Marshall 2014).
- [`fresnel_reflectance()`](https://johnkirwan.github.io/luxR/reference/fresnel_reflectance.md)
  gains a `component` argument to return the s- or p-polarized
  reflectance (not just the unpolarized mean) — why reflection off water
  partially polarizes light.
- [`read_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)
  delegates additional instrument formats to optional
  [lightr](https://docs.ropensci.org/lightr/). Native
  [`from_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md)
  and
  [`from_trios()`](https://johnkirwan.github.io/luxR/reference/from_trios.md)
  readers continue to work without it.
- Spectrum readers now reject malformed rows and nonnumeric values with
  structured source-line and checksum context. Ocean Optics imports no
  longer assume absolute irradiance, TriOS raw negatives are preserved,
  and any zero-floor preprocessing must be explicitly requested and is
  recorded.

### Interoperability

- New
  [`as_source_spct()`](https://johnkirwan.github.io/luxR/reference/as_source_spct.md)
  and
  [`as_reflector_spct()`](https://johnkirwan.github.io/luxR/reference/as_reflector_spct.md)
  convert `lux_spectrum` objects into the `photobiology` package’s
  generic spectral classes, and
  [`as_lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
  gained `source_spct` and `reflector_spct` methods for the reverse
  direction. Radiance is refused, since `source_spct` carries no
  per-steradian term, and the import methods refuse dose-based time
  units, biologically weighted spectra, an ambiguous energy/photon
  basis, negative values, and irregular grids unless an explicit policy
  opts in.
- [`as_rspec()`](https://johnkirwan.github.io/luxR/reference/as_rspec.md)
  and an
  [`as_lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
  method for pavo `rspec` objects bridge luxR into the
  [pavo](https://CRAN.R-project.org/package=pavo) ecosystem: luxR
  propagates the in-water light field, pavo analyses the colour space.
  See the *Visual ecology* vignette (`pavo` is a `Suggests` dependency).
- New
  [`as_colourvision()`](https://johnkirwan.github.io/luxR/reference/as_colourvision.md)
  reshapes `lux_spectrum` objects into the data frames the
  [colourvision](https://CRAN.R-project.org/package=colourvision)
  package consumes (illuminant `I`, reflectances `R1`/`R2`/`Rb`), and
  [`species_sensitivity_matrix()`](https://johnkirwan.github.io/luxR/reference/species_sensitivity_matrix.md)
  builds colourvision’s receptor matrix `C` from luxR’s own Govardovskii
  templates. luxR propagates the in-water light field; colourvision runs
  the RNL / colour-space model.
  [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  is cross-validated against `colourvision::RNLmodel(model = "log")` to
  numerical precision (guarded test; `colourvision` is a `Suggests`
  dependency). See the *Visual ecology* vignette.

## luxR 0.1.0

Initial release.

### New features

#### Spectral abstraction layer

- `lux_spectrum` S3 class carrying `E`, `lambda`, `quantity`, `unit`,
  `binwidth`, and `meta` slots
- Seven controlled unit strings with validation at construction time
- Arithmetic operators (`+`, `-`, `*`, `/`) with unit-mismatch warnings
- [`convert_unit()`](https://johnkirwan.github.io/luxR/reference/convert_unit.md)
  for energy ↔︎ photon-flux conversions and mW ↔︎ W radiance scaling
- [`as_lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
  coercer for numeric vectors and data frames
- [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) methods

#### Format readers

- [`from_naples()`](https://johnkirwan.github.io/luxR/reference/from_naples.md)
  — bundled Naples coastal irradiance profiles (0, 5, 10 m)
- [`from_solar()`](https://johnkirwan.github.io/luxR/reference/from_solar.md)
  — bundled ASTM G173-03 reference solar spectra
- [`from_trios()`](https://johnkirwan.github.io/luxR/reference/from_trios.md)
  — TriOS RAMSES `.dat` file reader
- [`from_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md)
  — Ocean Optics / Ocean Insight `.txt` file reader

#### Unit conversions

- [`photon2W()`](https://johnkirwan.github.io/luxR/reference/photon2W.md),
  [`W2photon()`](https://johnkirwan.github.io/luxR/reference/W2photon.md)
  — single-bin photon ↔︎ energy conversion
- [`n2W_spec_irradiance()`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md),
  [`W2mol_spec_irradiance()`](https://johnkirwan.github.io/luxR/reference/W2mol_spec_irradiance.md)
  — spectral photon-flux conversions
- [`wavelength_in_medium()`](https://johnkirwan.github.io/luxR/reference/wavelength_in_medium.md)
  — in-medium wavelength from refractive index
- [`ft2m()`](https://johnkirwan.github.io/luxR/reference/ft2m.md),
  [`m2ft()`](https://johnkirwan.github.io/luxR/reference/m2ft.md) —
  depth unit convenience functions

#### Photometric quantities

- [`irradiance2lux()`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md)
  — CIE 1931 photopic illuminance (lux)
- [`scotopic_lux()`](https://johnkirwan.github.io/luxR/reference/scotopic_lux.md)
  — CIE 1951 scotopic illuminance
- [`lux2irradiance()`](https://johnkirwan.github.io/luxR/reference/lux2irradiance.md)
  — rescale spectral shape to a target lux value
- [`broadband2spectrum()`](https://johnkirwan.github.io/luxR/reference/broadband2spectrum.md)
  — distribute a scalar reading across a spectral shape
- [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)
  — PAR in µmol photons m⁻² s⁻¹
- [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md)
  — fraction of irradiance in the PAR window

#### Depth propagation

- [`attenuate_depth()`](https://johnkirwan.github.io/luxR/reference/attenuate_depth.md),
  [`propagate_depth()`](https://johnkirwan.github.io/luxR/reference/propagate_depth.md)
  — scalar Beer-Lambert propagation
- [`attenuate_spectrum()`](https://johnkirwan.github.io/luxR/reference/attenuate_spectrum.md),
  [`propagate_spectrum()`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md)
  — full-spectrum bidirectional propagation
- [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  — band-integrated irradiance after depth propagation
- [`photic_depth()`](https://johnkirwan.github.io/luxR/reference/photic_depth.md)
  — euphotic depth at a given light fraction
- [`fit_Kd()`](https://johnkirwan.github.io/luxR/reference/fit_Kd.md) —
  Beer-Lambert inversion from two depth measurements
- [`jerlov_Kd()`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)
  — diffuse attenuation for Jerlov I–III and C1–C3 water types

#### Optical visibility

- [`secchi_depth()`](https://johnkirwan.github.io/luxR/reference/secchi_depth.md)
  — Secchi depth from Kd or irradiance-weighted Kd
- [`visual_range()`](https://johnkirwan.github.io/luxR/reference/visual_range.md)
  — heuristic Koschmieder–Berek horizontal visual-range estimate
- [`michelson_contrast()`](https://johnkirwan.github.io/luxR/reference/michelson_contrast.md),
  [`weber_contrast()`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md)
  — contrast metrics
- [`inherent_contrast()`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md),
  [`contrast_at_distance()`](https://johnkirwan.github.io/luxR/reference/contrast_at_distance.md),
  [`detection_range()`](https://johnkirwan.github.io/luxR/reference/detection_range.md)
  — object-vs-background detection: achromatic (Weber) and chromatic
  (ΔS) contrast, scalar heuristic decay or wavelength-resolved
  spectral-path propagation, and a finite threshold-distance scenario
  estimate
- [`detectability()`](https://johnkirwan.github.io/luxR/reference/detectability.md)
  — one-stop wrapper returning a `lux_detection` object (inherent
  contrast, threshold-distance estimate, status metadata, and a
  contrast-vs-distance curve) with `print` and `plot` methods

#### Inherent optical properties & the air-water interface

- [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)
  — beam attenuation `c = a + b`
- [`single_scattering_albedo()`](https://johnkirwan.github.io/luxR/reference/single_scattering_albedo.md)
  — `ω0 = b / (a + b)`
- [`transmittance()`](https://johnkirwan.github.io/luxR/reference/transmittance.md),
  [`absorbance()`](https://johnkirwan.github.io/luxR/reference/absorbance.md)
  — Beer-Lambert transmittance and natural-log absorbance / base-10
  optical density
- [`snells_window()`](https://johnkirwan.github.io/luxR/reference/snells_window.md)
  — half-angle of the underwater “optical manhole”
- [`fresnel_reflectance()`](https://johnkirwan.github.io/luxR/reference/fresnel_reflectance.md)
  — air-water Fresnel reflectance, with total internal
- [`surface_transmittance()`](https://johnkirwan.github.io/luxR/reference/surface_transmittance.md)
  — fraction of downwelling irradiance entering the water across the
  surface (direct or diffuse) reflection beyond the critical angle

#### Species perception

- [`govardovskii_template()`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  — Govardovskii (2000) visual-pigment absorbance template
- [`fit_sensitivity()`](https://johnkirwan.github.io/luxR/reference/fit_sensitivity.md)
  — fit template to measured sensitivity data
- [`species_LEF()`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
  — sensitivity curve for a named species and receptor class
- [`quantum_catch()`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)
  — photoreceptor quantum catch
- [`species_brightness()`](https://johnkirwan.github.io/luxR/reference/species_brightness.md)
  — multi-receptor quantum catch by species
- [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  — Vorobyev-Osorio receptor-noise-limited colour discrimination (ΔS in
  JNDs)
- [`receptor_absorptance()`](https://johnkirwan.github.io/luxR/reference/receptor_absorptance.md)
  — convert a normalised pigment absorbance template to photoreceptor
  absorptance given axial optical density (or absorption coefficient and
  outer-segment length), modelling self-screening

#### Geometry

- [`irradiance2radiance()`](https://johnkirwan.github.io/luxR/reference/irradiance2radiance.md),
  [`radiance2irradiance()`](https://johnkirwan.github.io/luxR/reference/radiance2irradiance.md)
  — solid-angle geometry conversions
- [`reflectance_to_radiance()`](https://johnkirwan.github.io/luxR/reference/reflectance_to_radiance.md)
  — multiply reflectance by an illuminant spectrum

#### Bundled datasets

- `Naples` — coastal irradiance profiles at 0, 5, 10 m (µmol m⁻² s⁻¹
  nm⁻¹)
- `solar_spectra` — ASTM G173-03 reference spectra (5 conditions)
- `jerlov_types` — Kd(λ) for 8 Jerlov water types
- `CIE1931` — CIE 1931 photopic luminous efficiency function V(λ)
- `CIE_scotopic` — CIE 1951 scotopic luminous efficiency function V′(λ)
- `species_sensitivities` — peak wavelengths for 10 species

#### Interactive explorer

- [`run_app()`](https://johnkirwan.github.io/luxR/reference/run_app.md)
  — launches a bundled Shiny application (requires `shiny`) with five
  guided tabs: depth propagation with spectrum upload and per-depth CSV
  export, species quantum catch, Vorobyev-Osorio colour discrimination,
  visibility metrics, and object-vs-background detection

### Bug fixes

- [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)
  on a µmol `lux_spectrum` now returns correct µmol m⁻² s⁻¹ values
  (previously divided by Avogadro’s constant twice)
- `broadband2spectrum(..., unit = "umol")` now multiplies by bin width
  before dividing by Avogadro’s constant (previously output was scaled
  up by the bin-width factor)
- [`mol2photon_FUN()`](https://johnkirwan.github.io/luxR/reference/mol2photon_FUN.md)
  now stops with a clear message for unrecognised `molar_unit`
  (previously crashed with “object ‘n’ not found”)
