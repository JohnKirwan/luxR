# Diffuse attenuation coefficients for Jerlov optical water types.

Long-format table of Kd(lambda) values for five oceanic and three
coastal water types from Jerlov (1976) and Solonenko & Mobley (2015).
Attributes record the supported wavelength range and spacing, a table
checksum, source artifact path, build commit, model version, and package
version.

## Usage

``` r
jerlov_types
```

## Format

A data frame with 120 rows and 3 columns:

- type:

  Jerlov water type (character): `"I"`, `"IA"`, `"IB"`, `"II"`, `"III"`
  (oceanic, clearest to most turbid) and `"C1"`, `"C2"`, `"C3"`
  (coastal).

- lambda:

  Wavelength in nm (350 to 700, 25 nm steps).

- Kd:

  Diffuse attenuation coefficient in 1/m.

## References

Jerlov NG (1976) Marine Optics. Elsevier, Amsterdam.

Solonenko MG, Mobley CD (2015) Inherent and apparent optical properties
of Jerlov water types. Applied Optics 54(17):5392-5401.

## Examples

``` r
data(jerlov_types)
subset(jerlov_types, type == "IA")
#>    type lambda    Kd
#> 16   IA    350 0.076
#> 17   IA    375 0.044
#> 18   IA    400 0.033
#> 19   IA    425 0.023
#> 20   IA    450 0.016
#> 21   IA    475 0.018
#> 22   IA    500 0.024
#> 23   IA    525 0.032
#> 24   IA    550 0.041
#> 25   IA    575 0.068
#> 26   IA    600 0.125
#> 27   IA    625 0.185
#> 28   IA    650 0.257
#> 29   IA    675 0.391
#> 30   IA    700 0.558
```
