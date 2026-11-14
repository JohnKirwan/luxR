# lux_spectrum — S3 spectral abstraction class

# Controlled unit vocabulary. `basis` is the conversion family and `scale`
# converts a value to that family's base unit (W or mol).
.UNITS <- data.frame(
  unit = c("W/m2/nm", "umol/m2/s/nm", "mmol/m2/s/nm", "mol/m2/s/nm",
           "W/m2/sr/nm", "mW/m2/sr/nm", "umol/m2/s/sr/nm",
           "mmol/m2/s/sr/nm", "mol/m2/s/sr/nm", "dimensionless"),
  quantity = c(rep("irradiance", 4L), rep("radiance", 5L), "reflectance"),
  basis = c("energy", rep("photon", 3L), "energy", "energy",
            rep("photon", 3L), NA),
  scale = c(1, 1e-6, 1e-3, 1, 1, 1e-3, 1e-6, 1e-3, 1, NA),
  stringsAsFactors = FALSE
)

.UNIT_QUANTITIES <- stats::setNames(.UNITS$quantity, .UNITS$unit)

.VALID_UNITS <- .UNITS$unit

.HC_J_NM <- 1.98644585714893e-16  # Planck constant x speed of light, J nm
.AVOGADRO <- 6.02214076e23        # photons per mol

.validate_scalar_character <- function(x, field, context) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    .luxr_abort(
      paste0("`", field, "` must be one non-empty, non-missing string."),
      field = field, value = x, kind = "type",
      context = context
    )
  }
  invisible(x)
}

.grid_tolerance <- function(...) {
  sqrt(.Machine$double.eps) * max(1, abs(c(...)))
}

#' Create a lux_spectrum object
#'
#' Constructs a validated \code{lux_spectrum} — the core spectral container
#' used throughout luxR. The object carries spectral values, wavelength grid,
#' physical quantity, unit, bin width, and free-form metadata together, so
#' unit conversions and arithmetic operations stay consistent.
#'
#' @param E        Numeric vector of spectral values, one per wavelength bin.
#' @param lambda   Numeric vector of bin-centre wavelengths in nm.
#' @param quantity Physical quantity: \code{"irradiance"}, \code{"radiance"},
#'   or \code{"reflectance"}.
#' @param unit     Unit string from the controlled vocabulary. See Details.
#' @param binwidth Bin width in nm. Inferred from the wavelength spacing
#'   when \code{NULL}; required for a single-bin spectrum. An explicit
#'   value must be finite, positive, scalar, and match the regular wavelength
#'   spacing.
#' @param meta     Named list of free-form metadata (depth, instrument, etc.).
#' @return An S3 object of class \code{"lux_spectrum"}.
#' @details Valid unit strings: \code{"W/m2/nm"}, \code{"W/m2/sr/nm"},
#'   \code{"mW/m2/sr/nm"}, \code{"umol/m2/s/nm"}, \code{"mmol/m2/s/nm"},
#'   \code{"mol/m2/s/nm"}, \code{"umol/m2/s/sr/nm"},
#'   \code{"mmol/m2/s/sr/nm"}, \code{"mol/m2/s/sr/nm"},
#'   \code{"dimensionless"}.
#'
#'   Both spectral vectors must be non-empty, numeric, finite, and equal in
#'   length. Wavelengths must be strictly increasing, unique, and regularly
#'   spaced. Irradiance and radiance values must be non-negative; reflectance
#'   values must lie in \code{[0, 1]}. Units without \code{"/sr"} describe
#'   irradiance, units with \code{"/sr"} describe radiance, and
#'   \code{"dimensionless"} is valid only for reflectance.
#'
#'   \strong{S3 methods available on \code{lux_spectrum} objects:}
#'   \code{print()}, \code{summary()}, \code{plot()},
#'   \code{as.data.frame()}, \code{[} (wavelength subsetting),
#'   and the arithmetic operators \code{+}, \code{-}, \code{*}, \code{/}.
#'   A list of \code{lux_spectrum} objects can be plotted with
#'   \code{\link{plot_spectra}}.
#' @aliases print.lux_spectrum summary.lux_spectrum [.lux_spectrum as.data.frame.lux_spectrum +.lux_spectrum -.lux_spectrum *.lux_spectrum /.lux_spectrum plot.lux_spectrum plot.list
#' @examples
#' lam <- seq(400, 700, by = 10)
#' x   <- lux_spectrum(rep(1, length(lam)), lam, "irradiance", "W/m2/nm")
#' print(x)
#' @seealso \code{\link{as_lux_spectrum}}, \code{\link{convert_unit}},
#'   \code{\link{plot_spectra}}
#' @export
lux_spectrum <- function(E, lambda,
                         quantity = "irradiance",
                         unit     = "W/m2/nm",
                         binwidth = NULL,
                         meta     = list()) {
  context <- if (is.list(meta)) meta else list()

  fail <- .lux_spectrum_fail(context)
  .check_numeric(E, "E", fail)
  .check_numeric(lambda, "lambda", fail)
  .validate_scalar_character(quantity, "quantity", context)
  .validate_scalar_character(unit, "unit", context)

  if (!is.list(meta)) {
    .luxr_abort(
      "`meta` must be a named list.",
      field = "meta", value = meta, kind = "type"
    )
  }
  if (length(meta) > 0L &&
      (is.null(names(meta)) || anyNA(names(meta)) ||
       any(!nzchar(names(meta))) ||
       anyDuplicated(names(meta)))) {
    .luxr_abort(
      "`meta` must have unique, non-empty names.",
      field = "meta", value = meta, kind = "value",
      context = context
    )
  }

  if (length(E) != length(lambda)) {
    .luxr_abort(
      paste0("`E` and `lambda` must have equal length; got ",
             length(E), " and ", length(lambda), "."),
      field = c("E", "lambda"), value = c(length(E), length(lambda)),
      kind = "dimension", context = context
    )
  }

  valid_quantities <- unique(unname(.UNIT_QUANTITIES))
  if (!quantity %in% valid_quantities) {
    .luxr_abort(
      paste0("`quantity` must be one of: ",
             paste(valid_quantities, collapse = ", "), "; got '",
             quantity, "'."),
      field = "quantity", value = quantity,
      kind = "unit", context = context
    )
  }
  if (!unit %in% .VALID_UNITS) {
    .luxr_abort(
      paste0("`unit` '", unit, "' is not in the controlled vocabulary. ",
             "Valid: ", paste(.VALID_UNITS, collapse = ", ")),
      field = "unit", value = unit,
      kind = "unit", context = context
    )
  }
  expected_quantity <- unname(.UNIT_QUANTITIES[[unit]])
  if (quantity != expected_quantity) {
    .luxr_abort(
      paste0("`quantity` and `unit` describe different dimensions: unit '",
             unit, "' requires quantity '", expected_quantity,
             "', not '", quantity, "'."),
      field = c("quantity", "unit"), value = c(quantity, unit),
      kind = "unit", context = context
    )
  }

  decreasing <- which(diff(lambda) <= 0)
  if (length(decreasing) > 0L) {
    i <- decreasing[1L] + 1L
    .luxr_abort(
      paste0("`lambda` must be strictly increasing and unique; index ", i,
             " has value ", format(lambda[i]), " after ",
             format(lambda[i - 1L]), "."),
      field = "lambda", value = lambda[i], index = i,
      kind = "grid", context = context
    )
  }

  spacing <- NULL
  if (length(lambda) > 1L) {
    differences <- diff(lambda)
    spacing <- differences[1L]
    irregular <- which(abs(differences - spacing) >
                         .grid_tolerance(differences, spacing))
    if (length(irregular) > 0L) {
      i <- irregular[1L] + 1L
      .luxr_abort(
        paste0("`lambda` must be regularly spaced because `binwidth` is ",
               "scalar; spacing before index ", i, " is ",
               format(differences[i - 1L]), " nm, expected ",
               format(spacing), " nm. Resample raw vectors explicitly ",
               "before constructing a lux_spectrum."),
        field = "lambda", value = differences[i - 1L], index = i,
        kind = "grid", context = context
      )
    }
  }

  invalid_physical <- which(E < 0 | (quantity == "reflectance" & E > 1))
  if (length(invalid_physical) > 0L) {
    i <- invalid_physical[1L]
    expected <- if (quantity == "reflectance") "[0, 1]" else "non-negative"
    .luxr_abort(
      paste0("`E` values for ", quantity, " must be ", expected,
             "; index ", i, " is ", format(E[i]), "."),
      field = "E", value = E[i], index = i,
      kind = "value", context = context
    )
  }

  if (is.null(binwidth)) {
    if (is.null(spacing)) {
      .luxr_abort(
        "`binwidth` is required for a single wavelength.",
        field = "binwidth", value = NULL,
        kind = "value", context = context
      )
    }
    binwidth <- spacing
  } else {
    if (!is.numeric(binwidth) || is.complex(binwidth) ||
        is.object(binwidth) || !is.null(dim(binwidth)) ||
        length(binwidth) != 1L) {
      .luxr_abort(
        "`binwidth` must be one numeric scalar.",
        field = "binwidth", value = binwidth,
        kind = "type", context = context
      )
    }
    if (!is.finite(binwidth) || binwidth <= 0) {
      .luxr_abort(
        paste0("`binwidth` must be finite and positive; got ",
               format(binwidth), "."),
        field = "binwidth", value = binwidth,
        kind = "value", context = context
      )
    }
    if (!is.null(spacing) &&
        abs(binwidth - spacing) > .grid_tolerance(binwidth, spacing)) {
      .luxr_abort(
        paste0("`binwidth` must match the regular wavelength spacing; got ",
               format(binwidth), " nm but spacing is ",
               format(spacing), " nm."),
        field = "binwidth", value = binwidth,
        kind = "grid", context = context
      )
    }
  }

  structure(
    list(E = E, lambda = lambda, quantity = quantity,
         unit = unit, binwidth = binwidth, meta = meta),
    class = "lux_spectrum"
  )
}

#' @export
print.lux_spectrum <- function(x, ...) {
  cat(sprintf(
    "<lux_spectrum> %s [%s] | %.4g-%.4g nm, %.4g nm bins (%d pts)\n",
    x$quantity, x$unit,
    min(x$lambda), max(x$lambda), x$binwidth, length(x$lambda)
  ))
  if (length(x$meta) > 0) {
    for (nm in names(x$meta))
      cat(sprintf("  %s: %s\n", nm, x$meta[[nm]]))
  }
  invisible(x)
}

#' @export
summary.lux_spectrum <- function(object, ...) {
  print(object)
  cat(sprintf(
    "  E: min=%.4g  mean=%.4g  max=%.4g\n",
    min(object$E), mean(object$E), max(object$E)
  ))
  cat(sprintf("  peak lambda: %.4g nm\n",
              object$lambda[which.max(object$E)]))
  invisible(object)
}

#' @export
`[.lux_spectrum` <- function(x, lambda_min, lambda_max) {
  idx <- x$lambda >= lambda_min & x$lambda <= lambda_max
  if (!any(idx))
    .luxr_abort(paste0("No wavelengths in [", lambda_min, ", ", lambda_max, "] nm."), "grid")
  lux_spectrum(x$E[idx], x$lambda[idx],
               quantity = x$quantity, unit = x$unit,
               binwidth = x$binwidth, meta = x$meta)
}

.lux_arithmetic <- function(a, b, op) {
  if (inherits(a, "lux_spectrum") && inherits(b, "lux_spectrum")) {
    if (!identical(a$lambda, b$lambda))
      .luxr_abort("lux_spectrum arithmetic requires identical lambda grids.", "grid")

    if (identical(op, `+`) || identical(op, `-`)) {
      if (a$unit != b$unit || a$quantity != b$quantity)
        .luxr_abort(paste0("Cannot ", if (identical(op, `+`)) "add" else "subtract",
                           " lux_spectrum objects with different quantities or units: ",
                           a$quantity, " [", a$unit, "] and ",
                           b$quantity, " [", b$unit, "]."), "unit")

      E_new <- op(a$E, b$E)
      return(lux_spectrum(E_new, a$lambda, a$quantity, a$unit,
                          a$binwidth, a$meta))
    }

    if (identical(op, `*`)) {
      if (a$quantity == "reflectance" && b$quantity == "reflectance")
        return(lux_spectrum(a$E * b$E, a$lambda, "reflectance",
                            "dimensionless", a$binwidth, a$meta))
      if (a$quantity == "reflectance" &&
          b$quantity %in% c("irradiance", "radiance"))
        return(lux_spectrum(a$E * b$E, a$lambda, b$quantity, b$unit,
                            b$binwidth, b$meta))
      if (b$quantity == "reflectance" &&
          a$quantity %in% c("irradiance", "radiance"))
        return(lux_spectrum(a$E * b$E, a$lambda, a$quantity, a$unit,
                            a$binwidth, a$meta))

      .luxr_abort(paste0("Unsupported lux_spectrum multiplication: ",
                         a$quantity, " [", a$unit, "] * ",
                         b$quantity, " [", b$unit, "]."), "type")
    }

    if (identical(op, `/`))
      .luxr_abort(paste0("Unsupported lux_spectrum division between two spectra; ",
                         "the resulting dimensions are not represented by lux_spectrum."), "type")

    .luxr_abort("Unsupported lux_spectrum operator.", "internal")
  } else if (inherits(a, "lux_spectrum")) {
    if (!is.numeric(b) || length(b) != 1L)
      .luxr_abort("A lux_spectrum may only be combined with a numeric scalar.", "type")
    lux_spectrum(op(a$E, b), a$lambda, a$quantity, a$unit, a$binwidth, a$meta)
  } else {
    if (!is.numeric(a) || length(a) != 1L)
      .luxr_abort("A lux_spectrum may only be combined with a numeric scalar.", "type")
    if (identical(op, `/`))
      .luxr_abort(paste0("Division of a numeric scalar by a lux_spectrum is unsupported: ",
                         "the reciprocal dimensions are not represented by lux_spectrum."), "type")
    lux_spectrum(op(a, b$E), b$lambda, b$quantity, b$unit, b$binwidth, b$meta)
  }
}

#' @export
`+.lux_spectrum` <- function(a, b) .lux_arithmetic(a, b, `+`)
#' @export
`-.lux_spectrum` <- function(a, b) {
  if (missing(b))
    return(lux_spectrum(-a$E, a$lambda, a$quantity, a$unit,
                        a$binwidth, a$meta))
  .lux_arithmetic(a, b, `-`)
}
#' @export
`*.lux_spectrum` <- function(a, b) .lux_arithmetic(a, b, `*`)
#' @export
`/.lux_spectrum` <- function(a, b) .lux_arithmetic(a, b, `/`)

#' @export
as.data.frame.lux_spectrum <- function(x, ...) {
  df <- data.frame(lambda = x$lambda, E = x$E)
  attr(df, "unit")     <- x$unit
  attr(df, "quantity") <- x$quantity
  df
}

#' Convert a lux_spectrum to a different unit
#'
#' Converts the spectral values in a \code{lux_spectrum} between energy and
#' photon-flux units, or between mW and W for radiance spectra. Supported
#' conversions: \code{"W/m2/nm"} \eqn{\leftrightarrow}
#' \code{"umol/m2/s/nm"} / \code{"mmol/m2/s/nm"} / \code{"mol/m2/s/nm"},
#' and the corresponding \code{"/sr"} photonic units. Energy radiance units
#' \code{"W/m2/sr/nm"} and \code{"mW/m2/sr/nm"} are also interchangeable.
#'
#' @param x  A \code{lux_spectrum} object.
#' @param to Target unit string from the controlled vocabulary.
#' @param ... Ignored.
#' @return A new \code{lux_spectrum} with updated \code{unit} and \code{E}.
#' @examples
#' lam   <- seq(400, 700, by = 10)
#' x_W   <- lux_spectrum(rep(1, length(lam)), lam, "irradiance", "W/m2/nm")
#' x_mol <- convert_unit(x_W, "umol/m2/s/nm")
#' x_mol$unit
#' @export
convert_unit <- function(x, to, ...) UseMethod("convert_unit")

#' @export
convert_unit.lux_spectrum <- function(x, to, ...) {
  if (!to %in% .VALID_UNITS)
    .luxr_abort(paste0("'", to, "' is not in the controlled unit vocabulary."), "unit")
  if (to == "dimensionless")
    .luxr_abort("Cannot convert to 'dimensionless' via unit conversion.", "unit")
  if (x$unit == to) return(x)

  from <- .UNITS[.UNITS$unit == x$unit, ]
  target <- .UNITS[.UNITS$unit == to, ]
  if (from$quantity != target$quantity)
    .luxr_abort(paste0("No conversion defined from '", x$unit, "' to '", to, "'",
                       if (!is.na(from$basis))
                         ": cannot convert between irradiance and radiance units",
                       "."), "unit")

  E <- x$E * from$scale
  if (from$basis != target$basis) {
    joules_per_mol <- .HC_J_NM * .AVOGADRO / x$lambda
    E <- if (from$basis == "energy") E / joules_per_mol else E * joules_per_mol
  }
  lux_spectrum(E / target$scale, x$lambda, x$quantity, to, x$binwidth, x$meta)
}

# Spectral irradiance in W/m2/nm, or a typed error for any other quantity.
.as_energy_irradiance <- function(x, operation) {
  if (!identical(x$quantity, "irradiance")) {
    .luxr_abort(
      paste0(operation, " requires spectral irradiance; got quantity '",
             x$quantity, "' with unit '", x$unit, "'."),
      field = c("quantity", "unit"), value = c(x$quantity, x$unit),
      kind = "unit", context = x$meta
    )
  }
  convert_unit(x, "W/m2/nm")
}

#' @export
plot.lux_spectrum <- function(x, main = x$quantity, ...) {
  graphics::plot(x$lambda, x$E, type = "l",
                 xlab = "Wavelength (nm)",
                 ylab = unit_expression(x$unit),
                 main = main,
                 ...)
  invisible(x)
}

#' Plot a list of lux_spectrum objects as overlaid lines.
#'
#' Draws all spectra in \code{x} on a single plot with a shared wavelength
#' axis. Line colours cycle through the default palette. Names of the list
#' (or \code{meta$label} if present) are used for the legend. Additional
#' arguments in \code{...} are passed to the initial \code{plot()} call.
#'
#' @param x   A named or unnamed list of \code{lux_spectrum} objects.
#' @param ... Additional arguments passed to \code{plot} and \code{lines}.
#' @return \code{invisible(x)} — called for its side effect (plot).
#' @export
plot_spectra <- function(x, ...) {
  if (!is.list(x) || length(x) == 0L) {
    .luxr_abort("`x` must be a non-empty list of lux_spectrum objects.",
                if (is.list(x)) "value" else "type", field = "x")
  }
  labels <- if (!is.null(names(x))) names(x) else as.character(seq_along(x))
  for (i in seq_along(x))
    if (!is.null(x[[i]]$meta$label)) labels[i] <- x[[i]]$meta$label

  all_lam <- x[[1]]$lambda
  all_E   <- x[[1]]$E
  for (s in x[-1]) { all_lam <- c(all_lam, s$lambda); all_E <- c(all_E, s$E) }

  graphics::plot(range(all_lam), range(all_E), type = "n",
                 xlab = "Wavelength (nm)", ylab = unit_expression(x[[1]]$unit), ...)
  for (i in seq_along(x))
    graphics::lines(x[[i]]$lambda, x[[i]]$E, col = i)
  graphics::legend("topright", legend = labels,
                   col = seq_along(x), lty = 1)
  invisible(x)
}

#' @export
plot.list <- function(x, ...) {
  if (length(x) > 0 && all(vapply(x, inherits, logical(1), "lux_spectrum")))
    return(plot_spectra(x, ...))
  NextMethod()
}
