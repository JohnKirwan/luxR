# Deploying the luxR app to Posit Connect Cloud

`app.R` here is a thin entry point: it loads `luxR` + `shiny` and serves the app
bundled inside the package (`inst/app/`). Connect Cloud needs this file plus a
`manifest.json` generated locally.

## One-time / on-update: generate the manifest

`manifest.json` must be regenerated whenever the app's dependency set changes.
Run this from an R session **with luxR installed the way Connect Cloud should
obtain it** — see the non-CRAN note below.

```r
# 1. Install luxR so its source is recorded in the manifest.
#    Recommended (guaranteed on Connect Cloud's free plan): from GitHub
remotes::install_github("JohnKirwan/luxR")
#    Alternative to try: from r-universe (also serves the WASM binary)
# install.packages("luxR", repos = "https://johnkirwan.r-universe.dev")

# 2. Write the manifest for this directory.
install.packages("rsconnect")
setwd("connect")                # run from the repo root; this folder must exist
rsconnect::writeManifest()      # scans app.R -> records luxR + shiny + closure
```

Commit `connect/app.R` and `connect/manifest.json`, then push to GitHub (the repo
must be public for the free plan).

## Publish on Connect Cloud

1. Sign in at <https://connect.posit.cloud>.
2. **Publish** -> content type **Shiny**.
3. Choose the public `JohnKirwan/luxR` repo and confirm the branch.
4. Set **`connect/app.R`** as the primary file.
5. **Publish** and watch the build log.

To update later: push changes to GitHub, then use the **republish** icon on the
content's page.

## Non-CRAN dependency note

luxR is not on CRAN, so how Connect Cloud obtains it depends on what the manifest
records:

- **GitHub source (recommended, documented):** installing luxR with
  `remotes::install_github("JohnKirwan/luxR")` before `writeManifest()` records a
  GitHub source, which Connect Cloud explicitly supports.
- **r-universe source (cleaner, unconfirmed):** installing from
  `https://johnkirwan.r-universe.dev` records that repository. Connect Cloud's
  docs do not confirm it installs from arbitrary CRAN-like repos, so treat this as
  "try it; fall back to the GitHub source if the build cannot find luxR".

The app only needs `luxR` + `shiny` (plus base packages and luxR's own imports),
so the manifest closure is small.
