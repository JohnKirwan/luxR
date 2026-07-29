# Changelog

## luxR 0.1.1

### Package identity

- Added the hexagonal luxR logo with a transparent background. The logo
  is displayed in the GitHub and r-universe README and in the bundled
  Shiny app.

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
