# Michelson contrast

Computes the Michelson (sinusoidal) contrast: \\(I\_{bright} -
I\_{dark}) / (I\_{bright} + I\_{dark})\\. Values range from 0 (no
contrast) to 1 (maximum contrast). Commonly used for periodic patterns
such as gratings.

## Usage

``` r
michelson_contrast(I_bright, I_dark)
```

## Arguments

- I_bright:

  Luminance or radiance of the brighter region (scalar or vector). Must
  be \\\ge I\_{dark}\\.

- I_dark:

  Luminance or radiance of the darker region (scalar or vector).

## Value

Contrast value(s) in \\\[0, 1\]\\.

## See also

\[weber_contrast()\]

## Examples

``` r
michelson_contrast(I_bright = 8, I_dark = 2)
#> [1] 0.6
```
