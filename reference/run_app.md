# Launch the luxR Shiny explorer.

Opens an interactive Shiny application for analysing underwater light
environments. It has five guided tabs:

- **Depth Propagation** – attenuate a built-in or uploaded irradiance
  spectrum through a Jerlov water type and download the per-depth lux
  and photon-flux table.

- **Species Perception** – photoreceptor quantum catch for a chosen
  species under a selected bundled light-source condition at that
  source's stated reference depth.

- **Colour discrimination** – Vorobyev-Osorio just-noticeable difference
  (JND) between two reflectances under the in-water light field.

- **Visibility** – Secchi depth, photic depth, and horizontal
  visual-range scenario estimate.

- **Detection** – explicitly unvalidated object-background
  contrast-threshold distance scenarios.

Requires the `shiny` package.

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Arguments passed to
  [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Invisible `NULL`; called for its side effect of starting the app.

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
} # }
```
