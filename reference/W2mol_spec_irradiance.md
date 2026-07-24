# Convert energy spectral irradiance to molar photon flux.

Converts W m\\^{-2}\\ nm\\^{-1}\\ spectral irradiance to a photon-count
flux expressed in molar units (mol, mmol, or µmol photons m\\^{-2}\\
s\\^{-1}\\ nm\\^{-1}\\). The inverse operation is
[`n2W_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md).
The same per-bin conversion factor applies to spectral radiance (W
m\\^{-2}\\ sr\\^{-1}\\ nm\\^{-1}\\).

## Usage

``` r
W2mol_spec_irradiance(W, ...)

# S3 method for class 'numeric'
W2mol_spec_irradiance(W, lambda, molar_unit = "umol", ...)

# S3 method for class 'lux_spectrum'
W2mol_spec_irradiance(W, molar_unit = "umol", ...)
```

## Arguments

- W:

  Spectral irradiance in W/m^2/nm, or a `lux_spectrum` with an energy
  irradiance or radiance unit.

- ...:

  Ignored.

- lambda:

  Wavelength in nm for each bin.

- molar_unit:

  Target molar unit: `"umol"`, `"mmol"`, or `"mol"`. Default `"umol"`.

## Value

Numeric vector of photon flux in the requested molar unit per nm, or a
`lux_spectrum` with the updated unit. Radiance outputs retain the
`"/sr"` term.

## Details

The inverse of
[`n2W_spec_irradiance`](https://johnkirwan.github.io/luxR/reference/n2W_spec_irradiance.md):
photon flux is recovered via \\N = E\lambda/(hc)\\, then divided by
Avogadro's constant scaled to the requested molar unit:
\$\$\Phi(\lambda) = \frac{E(\lambda)\\\lambda}{hc\\N_A} \times s\$\$
where \\N_A = 6.022 \times 10^{23}\\ mol\\^{-1}\\ and \\s = 10^6\\ for
`"umol"`, \\10^3\\ for `"mmol"`, or \\1\\ for `"mol"`.

## Examples

``` r
sp <- solar_irradiance("clear_noon")
W2mol_spec_irradiance(sp$irradiance, sp$wavelength, molar_unit = "umol")
#>  [1] 0.00000000 0.02591398 0.37449876 0.99309045 1.84741574 2.60393666
#>  [7] 3.37048880 3.77340934 3.55773818 3.32534833 3.34373889 4.18134548
#> [13] 5.02062395 5.28394338 5.55395030 5.86826175 6.15247956 6.52196271
#> [19] 6.90147707 7.29102265 7.69059945 8.01494212 8.25903506 8.41786266
#> [25] 8.48640931 8.50563581 8.47303435 8.38609714 8.33928480 8.23646482
#> [31] 8.12528551 8.00574684 7.87784883 7.74159147 7.59697476 7.44399871
#> [37] 7.28266331 7.05696093 6.82122734 6.57546253 6.31966651 6.05383926
#> [43] 5.77798080 5.49209113 5.19617024 4.89021813 4.57423480 4.24822026
#> [49] 3.91217450 3.56609753 3.20998934
```
