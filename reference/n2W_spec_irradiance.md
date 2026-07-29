# Convert photon-count spectral irradiance to W m^-2 nm^-1.

Converts per-bin photon flux (photons m\\^{-2}\\ s\\^{-1}\\ nm\\^{-1}\\,
or molar equivalents) to energy-based spectral irradiance in W
m\\^{-2}\\ nm\\^{-1}\\. The inverse operation is
[`W2mol_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/W2mol_spec_irradiance.md).

## Usage

``` r
n2W_spec_irradiance(value, ...)

# S3 method for class 'numeric'
n2W_spec_irradiance(
  value,
  lambda,
  photonic = FALSE,
  molar_unit = "photons",
  ...
)

# S3 method for class 'lux_spectrum'
n2W_spec_irradiance(value, ...)
```

## Arguments

- value:

  Spectral irradiance in \\photons\\m^{-2}\\s^{-1}\\nm^{-1}\\ (or molar
  units), or a `lux_spectrum` with a photonic irradiance or radiance
  unit.

- ...:

  Ignored.

- lambda:

  Wavelength in nm for each bin.

- photonic:

  Logical; if `TRUE`, `value` is in molar units (\\\mu mol\\, mmol, or
  \\mol\\m^{-2}\\s^{-1}\\nm^{-1}\\) — specify which via `molar_unit`.
  Defaults to `FALSE`. Note: `photonic = TRUE` means raw photon counts
  in
  [`par_irradiance`](https://johnkirwan.github.io/luxR/reference/par_irradiance.md),
  and photon-or-molar units in
  [`irradiance2lux`](https://johnkirwan.github.io/luxR/reference/irradiance2lux.md).

- molar_unit:

  Molar unit string (e.g. `"umol"`). Defaults to `"photons"`.

## Value

Numeric vector of spectral irradiance in \\W\\m^{-2}\\nm^{-1}\\, or a
`lux_spectrum` with `unit = "W/m2/nm"` or `"W/m2/sr/nm"` according to
the input dimensionality.

## Details

Each photon at wavelength \\\lambda\\ carries energy \\E = hc/\lambda\\.
Spectral irradiance in W m\\^{-2}\\ nm\\^{-1}\\ is therefore the photon
flux \\N\\ (photons m\\^{-2}\\ s\\^{-1}\\ nm\\^{-1}\\) multiplied by the
per-photon energy: \$\$E(\lambda) = N(\lambda) \cdot
\frac{hc}{\lambda}\$\$ where \\h = 6.626 \times 10^{-34}\\ J s (Planck
constant) and \\c = 2.998 \times 10^8\\ m s\\^{-1}\\ (speed of light).
The constant \\hc\\ in nm-compatible units is \\1.98645 \times
10^{-16}\\ J nm, the value used internally.

## Examples

``` r
utils::data(Naples)
n2W_spec_irradiance(Naples$depth_0m, Naples$wv, photonic = TRUE, molar_unit = "umol")
#>   [1] 0.27424602 0.24126393 0.26762964 0.31135078 0.26569105 0.29119546
#>   [7] 0.23792557 0.25633630 0.27247262 0.32820588 0.42158393 0.40393943
#>  [13] 0.42836925 0.42618633 0.41625798 0.37786576 0.36771242 0.42164085
#>  [19] 0.44300894 0.45851513 0.47053821 0.46809339 0.46037631 0.45524011
#>  [25] 0.45399282 0.45868533 0.44936449 0.41334402 0.43362165 0.42308153
#>  [31] 0.40057142 0.40933521 0.39216767 0.35843778 0.38036506 0.37017866
#>  [37] 0.37030261 0.36910845 0.35720779 0.35476225 0.35104575 0.33837757
#>  [43] 0.33918030 0.32915501 0.32736576 0.32229470 0.32185370 0.29570239
#>  [49] 0.28632886 0.28988148 0.29048273 0.28946892 0.27970679 0.27613916
#>  [55] 0.27413115 0.26529430 0.26305895 0.26229405 0.25707661 0.24415329
#>  [61] 0.24171249 0.22855315 0.24248749 0.23947249 0.23476624 0.23148846
#>  [67] 0.22667883 0.19709924 0.19743193 0.20173409 0.19663048 0.20022861
#>  [73] 0.19727908 0.16200707 0.16070020 0.15656334 0.16882651 0.17589551
#>  [79] 0.17869892 0.17996372 0.17740950 0.15355273 0.08077991 0.14398860
#>  [85] 0.16386352 0.16316457 0.16107135 0.15499395 0.14896140 0.14727310
#>  [91] 0.14345521 0.14282245 0.12904936 0.11167420 0.11679813 0.12195687
#>  [97] 0.12017625 0.12716373 0.12856936 0.12640937 0.11644867 0.12297237
#> [103] 0.12395377
```
