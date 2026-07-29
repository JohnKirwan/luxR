# luxR 0.1.1

## Package identity
- Added the hexagonal luxR logo with a transparent background. The logo is
  displayed in the GitHub and r-universe README and in the bundled Shiny app.

## Validation
- `read_instrument_spectrum()` now delegates single-file parsing to `lightr`
  while preserving irregular native grids, signed processed values, instrument
  metadata, parser notices, checksums, exact parser configuration, and the
  `lightr` version in a strict intermediate record. `read_spectrum()` converts
  that record only after explicit measurement, input scale, calibration,
  resampling, and negative-value policies are supplied. Known format/quantity
  contradictions fail, percent reflectance is explicitly converted to a
  fraction, and transmittance, absorbance, or raw records cannot be mislabeled
  as a `lux_spectrum`.
- Beer–Lambert attenuation with wavelength-specific diffuse attenuation is now
  explicitly the principal lightweight propagation tier. Function, vignette,
  scope, and Shiny documentation state its homogeneous-column,
  independent-wavelength assumptions and distinguish it from radiative
  transfer. Propagation rejects non-irradiance spectral objects and non-finite
  numerical results; outputs and app downloads record the propagation model
  version and Jerlov provenance.
- The Shiny explorer now has one tested, ordered tab registry: Depth
  Propagation, Species Perception, Colour discrimination, Visibility, and
  Detection. Documentation and navigation are checked against that registry,
  and every result identifies its scientific quantity, units, source context,
  and model assumptions.
- Every bundled dataset now has a checksum-pinned manifest entry, a
  deterministic generator, standardized source/unit/domain/processing
  provenance, and an offline CI rebuild check. Bundled reader and Shiny export
  metadata carry source checksums and processing versions; legacy snapshots and
  unresolved source attributions are labelled explicitly.
- Polarization helpers now fail fast on non-finite, physically impossible, or
  length-incompatible inputs. `degree_of_polarization()` rejects Stokes states
  with polarized intensity greater than total intensity.
- `underwater_polarization()` is explicitly identified in documentation and
  result metadata as an uncalibrated, tunable Rayleigh-like approximation. Its
  illustrative defaults now record their evidence limits, and literature-based
  angular benchmark tests prevent qualitative agreement from being presented
  as quantitative calibration.
- `jerlov_Kd()` now fails outside the bundled table's supported 350--700 nm
  domain by default. Constant endpoint extension requires explicit opt-in and
  carries the interpolation policy, table checksum, build commit, and model
  version as provenance. Full-spectrum propagation APIs and Shiny controls now
  require an explicit error, trim, or constant-extension policy, and Shiny
  downloads record the selected and calculated wavelength ranges. Historical
  underwater solar sources explicitly identify their original constant
  endpoint-extension assumption.
- Photopic and scotopic illuminance are now calculated from the official CIE
  018:2019 1 nm luminous-efficiency tables. The previous coarse bundled tables
  contained incorrect values, so corrected illuminance results can differ
  materially, especially for narrow-band and scotopic spectra. Both tables and
  their CIE metadata are checksum-pinned, reproducibly generated, and
  independently integrated against `photobiology` in guarded tests.
- Detection-distance outputs now identify themselves as unvalidated scenario
  estimates. Detection spectra, thresholds, attenuation, geometry, and search
  bounds fail on non-finite or non-physical inputs; criteria that remain
  detectable at the finite search limit are explicitly censored rather than
  returned as infinite ranges.
- `detection_range(model = "spectral_path")` now propagates object, background,
  and veiling radiances wavelength by wavelength and recomputes achromatic and
  chromatic receptor signals at every evaluated distance. A deterministic
  benchmark checks the propagated zebrafish chromatic signal against `pavo`.
- `quantum_catch()` now requires an explicit energy, raw-photon, or molar
  input unit and returns sensitivity-weighted photon irradiance in
  photons m^-2 s^-1. It no longer implies an absolute per-receptor rate;
  the Shiny result and CSV download record the source, sensitivity,
  integration settings, and omitted geometry and efficiency terms.
- Govardovskii pigment templates are now explicitly normalised to a peak of
  one, matching their documented range and the quantum-catch input invariant.
- Depth Propagation plots and CSV downloads now record the source condition,
  reference medium and depth, applied surface-transmission model and parameters,
  Jerlov type, and absolute target depth for reproducible interpretation.
- Bundled and uploaded in-water spectra now propagate from their declared
  reference depth to an absolute target depth below the surface. Targets above
  the known source depth fail explicitly instead of silently treating an
  underwater spectrum as a depth-zero source; Shiny uploads now require a
  visible reference-depth declaration.
- Species detection now uses only cited default channels: adult zebrafish
  L-cone motion, honeybee green-receptor contrast, and fruit-fly R1-6 motion
  are the initial achromatic models. A complete `species_channel_support`
  audit records supported and unavailable chromatic/achromatic combinations,
  and species without a validated default fail instead of pooling all known
  receptors.
- `colour_jnd()` now selects only a species' validated default chromatic
  channel. Human defaults contain S-, M-, and L-cones only; rods and ipRGCs are
  rejected as chromatic inputs. Receptor noise and quantum catches now fail
  explicitly when non-finite or non-positive instead of silently substituting
  machine epsilon.
- `species_sensitivities` now records a controlled `channel_role`, and the new
  `species_channels` dataset records cited, model-eligible receptor
  combinations. Both datasets rebuild from checked-in CSV sources. The
  unsupported GFP and unidentified mantis-shrimp records were removed.
- `colour_jnd()` is now cross-validated against
  [pavo](https://CRAN.R-project.org/package=pavo)'s `vismodel()` + `coldist()`:
  given matched sensitivities, stimuli, and noise the two agree to machine
  precision. See the *Visual ecology* vignette and a guarded test
  (`pavo` is a `Suggests` dependency).
- `W2photon()` / `photon2W()` are cross-validated against
  [photobiology](https://CRAN.R-project.org/package=photobiology)'s
  `e2quantum_multipliers()`: the energy ↔ photon conversion agrees to machine
  precision. See the *Light in water* vignette and a guarded test
  (`photobiology` is a `Suggests` dependency).

## New features
- Units now render with SI superscripts (`m⁻²`) in plot axis labels, the
  Shiny app, and the documentation. New exported helpers `unit_label()` and
  `unit_expression()` format a canonical unit string for display. The
  canonical unit strings themselves (`"W/m2/nm"` and siblings) and the
  `print()` output for `lux_spectrum` are unchanged.
- Polarization of the underwater light field (a lightweight analytic
  single-scattering model): `underwater_polarization()` returns the degree and
  angle of polarization as a function of viewing direction, solar elevation, and
  depth, with helpers `degree_of_polarization()` / `angle_of_polarization()`
  (Stokes descriptors), `scattering_angle()`, and `refracted_solar_angle()`. See
  the new *Polarization of the underwater light field* vignette. A new `SCOPE.md`
  documents luxR's focus and what is deferred to pavo / photobiology / HydroLight.
  `polarization_contrast()` gives the polarization distance between a target and
  its background for a polarization-sensitive viewer (How & Marshall 2014).
- `fresnel_reflectance()` gains a `component` argument to return the s- or
  p-polarized reflectance (not just the unpolarized mean) — why reflection off
  water partially polarizes light.
- `read_spectrum()` delegates additional instrument formats to optional
  [lightr](https://docs.ropensci.org/lightr/). Native `from_ocean_optics()` and
  `from_trios()` readers continue to work without it.
- Spectrum readers now reject malformed rows and nonnumeric values with
  structured source-line and checksum context. Ocean Optics imports no longer
  assume absolute irradiance, TriOS raw negatives are preserved, and any
  zero-floor preprocessing must be explicitly requested and is recorded.

## Interoperability
- New `as_source_spct()` and `as_reflector_spct()` convert `lux_spectrum`
  objects into the `photobiology` package's generic spectral classes, and
  `as_lux_spectrum()` gained `source_spct` and `reflector_spct` methods for the
  reverse direction. Radiance is refused, since `source_spct` carries no
  per-steradian term, and the import methods refuse dose-based time units,
  biologically weighted spectra, an ambiguous energy/photon basis, negative
  values, and irregular grids unless an explicit policy opts in.
- `as_rspec()` and an `as_lux_spectrum()` method for pavo `rspec` objects bridge
  luxR into the [pavo](https://CRAN.R-project.org/package=pavo) ecosystem: luxR
  propagates the in-water light field, pavo analyses the colour space. See the
  *Visual ecology* vignette (`pavo` is a `Suggests` dependency).
- New `as_colourvision()` reshapes `lux_spectrum` objects into the data frames
  the [colourvision](https://CRAN.R-project.org/package=colourvision) package
  consumes (illuminant `I`, reflectances `R1`/`R2`/`Rb`), and
  `species_sensitivity_matrix()` builds colourvision's receptor matrix `C` from
  luxR's own Govardovskii templates. luxR propagates the in-water light field;
  colourvision runs the RNL / colour-space model. `colour_jnd()` is
  cross-validated against `colourvision::RNLmodel(model = "log")` to numerical
  precision (guarded test; `colourvision` is a `Suggests` dependency). See the
  *Visual ecology* vignette.

# luxR 0.1.0

Initial release.

## New features

### Spectral abstraction layer
- `lux_spectrum` S3 class carrying `E`, `lambda`, `quantity`, `unit`, `binwidth`, and `meta` slots
- Seven controlled unit strings with validation at construction time
- Arithmetic operators (`+`, `-`, `*`, `/`) with unit-mismatch warnings
- `convert_unit()` for energy ↔ photon-flux conversions and mW ↔ W radiance scaling
- `as_lux_spectrum()` coercer for numeric vectors and data frames
- `print()`, `summary()`, `plot()`, and `as.data.frame()` methods

### Format readers
- `from_naples()` — bundled Naples coastal irradiance profiles (0, 5, 10 m)
- `from_solar()` — bundled ASTM G173-03 reference solar spectra
- `from_trios()` — TriOS RAMSES `.dat` file reader
- `from_ocean_optics()` — Ocean Optics / Ocean Insight `.txt` file reader

### Unit conversions
- `photon2W()`, `W2photon()` — single-bin photon ↔ energy conversion
- `n2W_spec_irradiance()`, `W2mol_spec_irradiance()` — spectral photon-flux conversions
- `wavelength_in_medium()` — in-medium wavelength from refractive index
- `ft2m()`, `m2ft()` — depth unit convenience functions

### Photometric quantities
- `irradiance2lux()` — CIE 1931 photopic illuminance (lux)
- `scotopic_lux()` — CIE 1951 scotopic illuminance
- `lux2irradiance()` — rescale spectral shape to a target lux value
- `broadband2spectrum()` — distribute a scalar reading across a spectral shape
- `par_irradiance()` — PAR in µmol photons m⁻² s⁻¹
- `par_fraction()` — fraction of irradiance in the PAR window

### Depth propagation
- `attenuate_depth()`, `propagate_depth()` — scalar Beer-Lambert propagation
- `attenuate_spectrum()`, `propagate_spectrum()` — full-spectrum bidirectional propagation
- `band_irradiance()` — band-integrated irradiance after depth propagation
- `photic_depth()` — euphotic depth at a given light fraction
- `fit_Kd()` — Beer-Lambert inversion from two depth measurements
- `jerlov_Kd()` — diffuse attenuation for Jerlov I–III and C1–C3 water types

### Optical visibility
- `secchi_depth()` — Secchi depth from Kd or irradiance-weighted Kd
- `visual_range()` — heuristic Koschmieder–Berek horizontal visual-range estimate
- `michelson_contrast()`, `weber_contrast()` — contrast metrics
- `inherent_contrast()`, `contrast_at_distance()`, `detection_range()` —
  object-vs-background detection: achromatic (Weber) and chromatic (ΔS) contrast,
  scalar heuristic decay or wavelength-resolved spectral-path propagation, and
  a finite threshold-distance scenario estimate
- `detectability()` — one-stop wrapper returning a `lux_detection` object
  (inherent contrast, threshold-distance estimate, status metadata, and a
  contrast-vs-distance curve) with `print` and `plot` methods

### Inherent optical properties & the air-water interface
- `beam_attenuation()` — beam attenuation `c = a + b`
- `single_scattering_albedo()` — `ω0 = b / (a + b)`
- `transmittance()`, `absorbance()` — Beer-Lambert transmittance and
  natural-log absorbance / base-10 optical density
- `snells_window()` — half-angle of the underwater "optical manhole"
- `fresnel_reflectance()` — air-water Fresnel reflectance, with total internal
- `surface_transmittance()` — fraction of downwelling irradiance entering the water across the surface (direct or diffuse)
  reflection beyond the critical angle

### Species perception
- `govardovskii_template()` — Govardovskii (2000) visual-pigment absorbance template
- `fit_sensitivity()` — fit template to measured sensitivity data
- `species_LEF()` — sensitivity curve for a named species and receptor class
- `quantum_catch()` — photoreceptor quantum catch
- `species_brightness()` — multi-receptor quantum catch by species
- `colour_jnd()` — Vorobyev-Osorio receptor-noise-limited colour discrimination (ΔS in JNDs)
- `receptor_absorptance()` — convert a normalised pigment absorbance template to
  photoreceptor absorptance given axial optical density (or absorption
  coefficient and outer-segment length), modelling self-screening

### Geometry
- `irradiance2radiance()`, `radiance2irradiance()` — solid-angle geometry conversions
- `reflectance_to_radiance()` — multiply reflectance by an illuminant spectrum

### Bundled datasets
- `Naples` — coastal irradiance profiles at 0, 5, 10 m (µmol m⁻² s⁻¹ nm⁻¹)
- `solar_spectra` — ASTM G173-03 reference spectra (5 conditions)
- `jerlov_types` — Kd(λ) for 8 Jerlov water types
- `CIE1931` — CIE 1931 photopic luminous efficiency function V(λ)
- `CIE_scotopic` — CIE 1951 scotopic luminous efficiency function V′(λ)
- `species_sensitivities` — peak wavelengths for 10 species

### Interactive explorer
- `run_app()` — launches a bundled Shiny application (requires `shiny`) with
  five guided tabs: depth propagation with spectrum upload and per-depth CSV
  export, species quantum catch, Vorobyev-Osorio colour discrimination,
  visibility metrics, and object-vs-background detection

## Bug fixes

- `par_irradiance()` on a µmol `lux_spectrum` now returns correct µmol m⁻² s⁻¹
  values (previously divided by Avogadro's constant twice)
- `broadband2spectrum(..., unit = "umol")` now multiplies by bin width before
  dividing by Avogadro's constant (previously output was scaled up by the bin-width
  factor)
- `mol2photon_FUN()` now stops with a clear message for unrecognised `molar_unit`
  (previously crashed with "object 'n' not found")
