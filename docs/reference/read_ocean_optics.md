# Strictly parse an Ocean Optics / Ocean Insight spectrum file

Parses the plain-text format without assigning a physical quantity or
unit. Every row must contain exactly two tab-separated numeric fields.
Instrument values, including negatives, are preserved without clipping.

## Usage

``` r
read_ocean_optics(path)
```

## Arguments

- path:

  Path to the Ocean Optics `.txt` file.

## Value

A data frame containing `lambda` and `signal`. Parsed header and import
provenance are attached as `"luxR.header"` and `"luxR.import"`
attributes.
