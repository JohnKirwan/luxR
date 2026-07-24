# Weber contrast

Computes the Weber contrast: \\(I\_{target} - I\_{background}) /
I\_{background}\\. Positive values indicate a target brighter than its
background; negative values indicate a darker target. Commonly used for
isolated objects on a uniform background.

## Usage

``` r
weber_contrast(I_target, I_background)
```

## Arguments

- I_target:

  Luminance or radiance of the target (scalar or vector).

- I_background:

  Luminance or radiance of the background (scalar or vector). Must be
  non-zero.

## Value

Contrast value(s); unbounded but typically in \\\[-1, \infty)\\.

## See also

\[michelson_contrast()\]

## Examples

``` r
weber_contrast(I_target = 8, I_background = 4)
#> [1] 1
```
