# Posit Connect Cloud entry point for the bundled luxR Shiny explorer.
#
# The app itself ships inside the luxR package (inst/app/). This wrapper installs
# nothing — it loads luxR + shiny and serves the packaged app directory, so the
# only deployment dependencies are luxR (non-CRAN) and shiny.
#
# Connect Cloud runs this file as the app's "primary file". Generate the
# dependency manifest next to it with rsconnect::writeManifest() (see README.md).

library(luxR)
library(shiny)

shiny::shinyAppDir(system.file("app", package = "luxR"))
