# Package index

## Package & app

Package overview and the interactive Shiny explorer.

- [`luxR-package`](https://johnkirwan.github.io/luxR/reference/luxR-package.md)
  [`luxR`](https://johnkirwan.github.io/luxR/reference/luxR-package.md)
  : luxR: Underwater Light Analysis and Visual Ecology
- [`run_app()`](https://johnkirwan.github.io/luxR/reference/run_app.md)
  : Launch the luxR Shiny explorer.

## Unit conversions

Convert between radiometric and photometric quantities.

- [`photon2W()`](https://johnkirwan.github.io/luxR/reference/photon2W.md)
  : Convert photon counts to watts at a given wavelength.
- [`W2photon()`](https://johnkirwan.github.io/luxR/reference/W2photon.md)
  : Convert watts to photon counts at a given wavelength.
- [`n2W_spec_irradiance()`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md)
  : Convert photon-count spectral irradiance to Watts/m^2/nm.
- [`W2mol_spec_irradiance()`](https://johnkirwan.github.io/luxR/reference/W2mol_spec_irradiance.md)
  : Convert energy spectral irradiance to molar photon flux.
- [`reflectance_to_radiance()`](https://johnkirwan.github.io/luxR/reference/reflectance_to_radiance.md)
  : Convert spectral reflectance to spectral radiance
- [`wavelength_in_medium()`](https://johnkirwan.github.io/luxR/reference/wavelength_in_medium.md)
  : Wavelength of light inside an optical medium.
- [`ft2m()`](https://johnkirwan.github.io/luxR/reference/ft2m.md) :
  Convert feet to metres.
- [`m2ft()`](https://johnkirwan.github.io/luxR/reference/m2ft.md) :
  Convert metres to feet.

## Photometric quantities

Compute illuminance and PAR from spectral irradiance.

- [`irradiance2lux()`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md)
  : Provide lux values for measures of spectral irradiance.
- [`scotopic_lux()`](https://johnkirwan.github.io/luxR/reference/scotopic_lux.md)
  : Compute scotopic illuminance (V'(lambda) weighting).
- [`lux2irradiance()`](https://johnkirwan.github.io/luxR/reference/lux2irradiance.md)
  : Distribute integrated lux across a reference spectral shape.
- [`broadband2spectrum()`](https://johnkirwan.github.io/luxR/reference/broadband2spectrum.md)
  : Convert a broadband scalar reading into a plausible spectrum.
- [`par_irradiance()`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md)
  : PAR irradiance from a spectral irradiance measurement.
- [`par_fraction()`](https://johnkirwan.github.io/luxR/reference/par_fraction.md)
  : Fraction of spectral irradiance in the PAR window.

## Spectral data sources

Accessors for bundled reference spectra and field data import.
lux_spectrum-returning wrappers (from_naples, from_solar, from_trios,
from_ocean_optics) are listed under Spectral abstraction.

- [`solar_irradiance()`](https://johnkirwan.github.io/luxR/reference/solar_irradiance.md)
  : Reference solar spectral irradiance under standard conditions.
- [`read_trios()`](https://johnkirwan.github.io/luxR/reference/read_trios.md)
  : Read a TriOS RAMSES spectroradiometer data file
- [`read_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/read_ocean_optics.md)
  : Strictly parse an Ocean Optics / Ocean Insight spectrum file
- [`read_instrument_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_instrument_spectrum.md)
  : Parse one instrument spectrum with lightr
- [`read_spectrum()`](https://johnkirwan.github.io/luxR/reference/read_spectrum.md)
  : Read a declared, calibrated spectrum with lightr

## Depth propagation

Beer-Lambert attenuation through the water column.

- [`attenuate_spectrum()`](https://johnkirwan.github.io/luxR/reference/attenuate_spectrum.md)
  : Propagate a surface spectrum through the water column.
- [`attenuate_depth()`](https://johnkirwan.github.io/luxR/reference/attenuate_depth.md)
  : Beer-Lambert attenuation at a single wavelength.
- [`propagate_depth()`](https://johnkirwan.github.io/luxR/reference/propagate_depth.md)
  : Propagate a known irradiance to any other depth (bidirectional).
- [`propagate_spectrum()`](https://johnkirwan.github.io/luxR/reference/propagate_spectrum.md)
  : Propagate a known spectrum to any other depth(s) (bidirectional).
- [`band_irradiance()`](https://johnkirwan.github.io/luxR/reference/band_irradiance.md)
  : Band-integrated irradiance at one or more depths
- [`photic_depth()`](https://johnkirwan.github.io/luxR/reference/photic_depth.md)
  : Depth at which a given fraction of surface light remains.
- [`fit_Kd()`](https://johnkirwan.github.io/luxR/reference/fit_Kd.md) :
  Estimate the diffuse attenuation coefficient from two irradiance
  readings.
- [`jerlov_Kd()`](https://johnkirwan.github.io/luxR/reference/jerlov_Kd.md)
  : Diffuse attenuation coefficient for Jerlov optical water types.
- [`light_at_depth()`](https://johnkirwan.github.io/luxR/reference/light_at_depth.md)
  : In-water downwelling spectral irradiance at a single depth.

## Optical visibility

Secchi depth, diver/camera visual range, image contrast, and
object-vs-background detection.

- [`secchi_depth()`](https://johnkirwan.github.io/luxR/reference/secchi_depth.md)
  : Secchi depth from diffuse attenuation coefficient(s).
- [`visual_range()`](https://johnkirwan.github.io/luxR/reference/visual_range.md)
  : Heuristic horizontal visual-range estimate in water.
- [`michelson_contrast()`](https://johnkirwan.github.io/luxR/reference/michelson_contrast.md)
  : Michelson contrast
- [`weber_contrast()`](https://johnkirwan.github.io/luxR/reference/weber_contrast.md)
  : Weber contrast
- [`inherent_contrast()`](https://johnkirwan.github.io/luxR/reference/inherent_contrast.md)
  : Inherent (zero-distance) contrast of an object against its
  background.
- [`contrast_at_distance()`](https://johnkirwan.github.io/luxR/reference/contrast_at_distance.md)
  : Heuristic scalar contrast remaining after a sighting path through
  water.
- [`detection_range()`](https://johnkirwan.github.io/luxR/reference/detection_range.md)
  : Scenario estimate of object-background threshold-crossing distance.
- [`detectability()`](https://johnkirwan.github.io/luxR/reference/detectability.md)
  : Object-vs-background detection summary.

## Inherent optical properties & interface

Beam attenuation, Beer-Lambert transmittance/absorbance, and the
air-water boundary.

- [`beam_attenuation()`](https://johnkirwan.github.io/luxR/reference/beam_attenuation.md)
  : Beam attenuation coefficient from absorption and scattering.
- [`single_scattering_albedo()`](https://johnkirwan.github.io/luxR/reference/single_scattering_albedo.md)
  : Single-scattering albedo.
- [`transmittance()`](https://johnkirwan.github.io/luxR/reference/transmittance.md)
  : Beer-Lambert transmittance over a path.
- [`absorbance()`](https://johnkirwan.github.io/luxR/reference/absorbance.md)
  : Absorbance (optical density) from transmittance.
- [`snells_window()`](https://johnkirwan.github.io/luxR/reference/snells_window.md)
  : Snell's window half-angle.
- [`fresnel_reflectance()`](https://johnkirwan.github.io/luxR/reference/fresnel_reflectance.md)
  : Fresnel reflectance at the air-water interface.
- [`surface_transmittance()`](https://johnkirwan.github.io/luxR/reference/surface_transmittance.md)
  : Fraction of downwelling irradiance transmitted across the water
  surface.

## Polarization

Linear polarization of the underwater light field (single-scattering
model) and Stokes-parameter descriptors.

- [`underwater_polarization()`](https://johnkirwan.github.io/luxR/reference/underwater_polarization.md)
  : Tunable Rayleigh-like approximation to underwater polarization
- [`polarization_contrast()`](https://johnkirwan.github.io/luxR/reference/polarization_contrast.md)
  : Polarization contrast between a target and its background
- [`degree_of_polarization()`](https://johnkirwan.github.io/luxR/reference/degree_of_polarization.md)
  : Degree of polarization from Stokes parameters
- [`angle_of_polarization()`](https://johnkirwan.github.io/luxR/reference/angle_of_polarization.md)
  : Angle of polarization (e-vector orientation) from Stokes parameters
- [`scattering_angle()`](https://johnkirwan.github.io/luxR/reference/scattering_angle.md)
  : Angle between a line of sight and the solar beam
- [`refracted_solar_angle()`](https://johnkirwan.github.io/luxR/reference/refracted_solar_angle.md)
  : Refracted zenith angle of the sun beneath the surface

## Species perception

Visual pigment templates, quantum catch, and colour discrimination.

- [`govardovskii_template()`](https://johnkirwan.github.io/luxR/reference/govardovskii_template.md)
  : Govardovskii et al. (2000) visual-pigment template.
- [`receptor_absorptance()`](https://johnkirwan.github.io/luxR/reference/receptor_absorptance.md)
  : Photoreceptor absorptance from a normalised absorbance template
  (self-screening).
- [`fit_sensitivity()`](https://johnkirwan.github.io/luxR/reference/fit_sensitivity.md)
  : Fit a Govardovskii visual-pigment template to measured spectral
  sensitivity.
- [`species_LEF()`](https://johnkirwan.github.io/luxR/reference/species_LEF.md)
  : Spectral sensitivity for a named species and photoreceptor class.
- [`quantum_catch()`](https://johnkirwan.github.io/luxR/reference/quantum_catch.md)
  : Sensitivity-weighted photon irradiance.
- [`species_brightness()`](https://johnkirwan.github.io/luxR/reference/species_brightness.md)
  : Per-species sensitivity-weighted photon irradiance.
- [`colour_jnd()`](https://johnkirwan.github.io/luxR/reference/colour_jnd.md)
  : Chromatic distance between two illuminants (Vorobyev-Osorio model).

## Geometry

Radiance/irradiance conversion with solid-angle geometry.

- [`irradiance2radiance()`](https://johnkirwan.github.io/luxR/reference/irradiance2radiance.md)
  : Convert irradiance to radiance under a geometry assumption.
- [`radiance2irradiance()`](https://johnkirwan.github.io/luxR/reference/radiance2irradiance.md)
  : Convert radiance to irradiance under a geometry assumption.

## Datasets

Reference data bundled with the package.

- [`CIE1931`](https://johnkirwan.github.io/luxR/reference/CIE1931.md) :
  CIE Photopic Luminous Efficiency Function
- [`CIE_scotopic`](https://johnkirwan.github.io/luxR/reference/CIE_scotopic.md)
  : CIE Scotopic Luminous Efficiency Function
- [`Naples`](https://johnkirwan.github.io/luxR/reference/Naples.md) :
  Example downwelling irradiance from Mare Chiaro, Gulf of Naples
- [`jerlov_types`](https://johnkirwan.github.io/luxR/reference/jerlov_types.md)
  : Diffuse attenuation coefficients for Jerlov optical water types.
- [`solar_spectra`](https://johnkirwan.github.io/luxR/reference/solar_spectra.md)
  : ASTM G173-03 reference solar spectral irradiance.
- [`species_sensitivities`](https://johnkirwan.github.io/luxR/reference/species_sensitivities.md)
  : Photoreceptor spectral sensitivities for selected species.
- [`species_channels`](https://johnkirwan.github.io/luxR/reference/species_channels.md)
  : Validated visual-channel memberships for selected species.
- [`species_channel_support`](https://johnkirwan.github.io/luxR/reference/species_channel_support.md)
  : Species visual-channel support decisions.

## Spectral abstraction

lux_spectrum S3 class, coercers, format readers, and unit conversion.

- [`lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/lux_spectrum.md)
  : Create a lux_spectrum object

- [`as_lux_spectrum()`](https://johnkirwan.github.io/luxR/reference/as_lux_spectrum.md)
  : Coerce an object to lux_spectrum

- [`as_rspec()`](https://johnkirwan.github.io/luxR/reference/as_rspec.md)
  :

  Convert luxR spectra to a pavo `rspec` object

- [`convert_unit()`](https://johnkirwan.github.io/luxR/reference/convert_unit.md)
  : Convert a lux_spectrum to a different unit

- [`resample_spectrum()`](https://johnkirwan.github.io/luxR/reference/resample_spectrum.md)
  : Resample a spectrum to a new wavelength grid

- [`plot_spectra()`](https://johnkirwan.github.io/luxR/reference/plot_spectra.md)
  : Plot a list of lux_spectrum objects as overlaid lines.

- [`from_naples()`](https://johnkirwan.github.io/luxR/reference/from_naples.md)
  : Load a Naples depth spectrum as a lux_spectrum

- [`from_solar()`](https://johnkirwan.github.io/luxR/reference/from_solar.md)
  : Load a reference solar spectrum as a lux_spectrum

- [`from_trios()`](https://johnkirwan.github.io/luxR/reference/from_trios.md)
  : Read a TriOS RAMSES file as calibrated radiance spectra

- [`from_ocean_optics()`](https://johnkirwan.github.io/luxR/reference/from_ocean_optics.md)
  : Read a calibrated Ocean Optics spectrum as a lux_spectrum
