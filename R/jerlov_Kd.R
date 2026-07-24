# jerlov_Kd — accessor for Jerlov optical water type data

.jerlov_dataset_context <- function(tab = jerlov_types) {
  required <- c(
    "supported_wavelength_range_nm", "wavelength_step_nm",
    "table_checksum_md5", "source_path", "build_commit", "model_version"
  )
  metadata <- attributes(tab)[required]
  missing <- required[vapply(metadata, is.null, logical(1))]
  if (length(missing) > 0L) {
    error <- structure(
      list(
        message = paste0(
          "Bundled dataset `jerlov_types` is missing required metadata: ",
          paste(missing, collapse = ", "), "."
        ),
        call = NULL,
        dataset = "jerlov_types",
        source_path = "data/jerlov_types.rda",
        missing_fields = missing
      ),
      class = c("luxR_jerlov_data_error", "error", "condition")
    )
    stop(error)
  }
  metadata$package_version <- as.character(utils::packageVersion("luxR"))
  metadata
}

.stop_jerlov <- function(message, class, field, value = NULL, index = NULL,
                         context = list()) {
  error <- structure(
    c(
      list(
        message = message,
        call = NULL,
        field = field,
        value = value,
        index = index
      ),
      context
    ),
    class = c(class, "luxR_jerlov_error", "error", "condition")
  )
  stop(error)
}

.validate_jerlov_lambda <- function(lambda, context) {
  if (!is.numeric(lambda) || is.complex(lambda) || is.object(lambda) ||
      !is.null(dim(lambda)) || length(lambda) == 0L) {
    .stop_jerlov(
      "`lambda` must be a non-empty numeric vector of wavelengths in nm.",
      class = "luxR_jerlov_input_error", field = "lambda", value = lambda,
      context = context
    )
  }
  invalid <- which(!is.finite(lambda))
  if (length(invalid) > 0L) {
    i <- invalid[[1L]]
    .stop_jerlov(
      paste0("`lambda` must contain only finite wavelengths; index ", i,
             " is ", format(lambda[[i]]), "."),
      class = "luxR_jerlov_input_error", field = "lambda",
      value = lambda[[i]], index = i, context = context
    )
  }
  invisible(lambda)
}

.prepare_jerlov_domain <- function(lambda, values,
                                   wavelength_policy = c("error", "trim",
                                                         "constant"),
                                   type = "IA", operation) {
  wavelength_policy <- match.arg(wavelength_policy)
  .validate_jerlov_lambda(
    lambda,
    c(.jerlov_dataset_context(), list(
      type = type, operation = operation,
      wavelength_policy = wavelength_policy
    ))
  )
  if (length(lambda) != length(values)) {
    stop("Internal Jerlov domain preparation received misaligned wavelengths ",
         "and values in `", operation, "`.", call. = FALSE)
  }
  supported <- .jerlov_dataset_context()$supported_wavelength_range_nm
  input_range <- range(lambda)
  keep <- lambda >= supported[[1L]] & lambda <= supported[[2L]]

  if (wavelength_policy == "trim") {
    if (!any(keep)) {
      .stop_jerlov(
        paste0("`", operation, "` cannot trim the requested wavelength range ",
               paste(format(input_range), collapse = "--"),
               " nm to the supported Jerlov range ",
               paste(format(supported), collapse = "--"),
               " nm because the ranges do not overlap."),
        class = "luxR_jerlov_range_error", field = "lambda",
        value = input_range,
        context = c(.jerlov_dataset_context(), list(
          type = toupper(type), operation = operation,
          wavelength_policy = wavelength_policy,
          requested_wavelength_range_nm = input_range
        ))
      )
    }
    lambda_out <- lambda[keep]
    values_out <- values[keep]
    extrapolation <- "error"
  } else {
    lambda_out <- lambda
    values_out <- values
    extrapolation <- if (wavelength_policy == "constant") "constant" else "error"
  }

  Kd <- jerlov_Kd(type, lambda_out, extrapolation = extrapolation)
  metadata <- attr(Kd, "luxR.jerlov", exact = TRUE)
  if (is.null(metadata)) {
    metadata <- c(.jerlov_dataset_context(), list(
      type = toupper(type), interp = "linear", extrapolation = "error",
      requested_wavelength_range_nm = range(lambda_out),
      extrapolated = FALSE, extrapolated_wavelength_count = 0L
    ))
  }
  metadata$wavelength_policy <- wavelength_policy
  metadata$input_wavelength_range_nm <- input_range
  metadata$calculated_wavelength_range_nm <- range(lambda_out)
  metadata$trimmed_wavelength_count <- sum(!keep)

  Kd_out <- as.numeric(Kd)
  attr(Kd_out, "luxR.jerlov") <- metadata

  list(
    lambda = lambda_out,
    values = values_out,
    Kd = Kd_out,
    metadata = metadata,
    keep = keep
  )
}

#' Diffuse attenuation coefficient for Jerlov optical water types.
#'
#' Returns Kd(lambda) for the specified Jerlov water type from the bundled
#' \code{jerlov_types} dataset (Jerlov 1976; Solonenko & Mobley 2015).
#' Optionally interpolates onto a user-supplied wavelength grid.
#'
#' @param type Jerlov water type. One of \code{"I"}, \code{"IA"},
#'   \code{"IB"}, \code{"II"}, \code{"III"}, \code{"C1"}, \code{"C2"},
#'   \code{"C3"}. Case-insensitive.
#' @param lambda Wavelengths in nm to interpolate Kd onto. If \code{NULL}
#'   (default), returns the full tabulated rows as a data frame.
#' @param interp Interpolation method when \code{lambda} is supplied.
#'   One of \code{"linear"} (default), \code{"spline"}, or
#'   \code{"nearest"}. Interpolation is applied only within the supported
#'   wavelength range.
#' @param extrapolation Out-of-range policy. The default \code{"error"}
#'   raises a \code{luxR_jerlov_range_error}. Set to \code{"constant"} to
#'   explicitly extend the nearest endpoint value; the choice is recorded in
#'   the returned vector's \code{"luxR.jerlov"} attribute.
#' @return If \code{lambda} is \code{NULL}: a data frame with columns
#'   \code{type}, \code{lambda}, \code{Kd} and dataset metadata attributes.
#'   If \code{lambda} is supplied: a numeric vector of Kd values (1/m) with a
#'   \code{"luxR.jerlov"} provenance attribute recording the water type,
#'   interpolation and extrapolation policies, supported and requested ranges,
#'   source checksum, build commit, and model version.
#' @details The bundled Jerlov table supports 350--700 nm. Values outside that
#'   domain are not measured by this dataset and therefore fail by default.
#'   Constant endpoint extension is available only as an explicit modelling
#'   assumption; linear or spline extrapolation is not supported.
#' @references
#'   Jerlov NG (1976) Marine Optics. Elsevier, Amsterdam.
#'
#'   Solonenko MG, Mobley CD (2015) Inherent and apparent optical
#'   properties of Jerlov water types. Applied Optics 54(17):5392-5401.
#' @examples
#' jerlov_Kd("IA")
#' Kd_IA <- jerlov_Kd("IA", lambda = c(400, 450, 500, 550, 600))
#' as.numeric(Kd_IA)
#' attr(Kd_IA, "luxR.jerlov")[c("type", "interp", "extrapolation",
#'                               "supported_wavelength_range_nm")]
#'
#' lam <- seq(400, 700, by = 10)
#' Kd  <- jerlov_Kd("II", lambda = lam)
#' attenuate_spectrum(rep(1, length(lam)), Kd, depths = c(10, 25, 50),
#'                   lambda = lam)
#' @export
jerlov_Kd <- function(type = "IA", lambda = NULL,
                      interp = c("linear", "spline", "nearest"),
                      extrapolation = c("error", "constant")) {
  interp <- match.arg(interp)
  extrapolation <- match.arg(extrapolation)
  dataset_context <- .jerlov_dataset_context()

  if (!is.character(type) || length(type) != 1L || is.na(type) ||
      !nzchar(type)) {
    .stop_jerlov(
      "`type` must be one non-empty, non-missing Jerlov water-type string.",
      class = "luxR_jerlov_input_error", field = "type", value = type,
      context = dataset_context
    )
  }
  type <- toupper(type)
  tab <- jerlov_types[jerlov_types$type == type, , drop = FALSE]
  if (nrow(tab) == 0L) {
    .stop_jerlov(
      paste0("unknown Jerlov type: '", type, "'. Valid types: ",
             paste(sort(unique(jerlov_types$type)), collapse = ", ")),
      class = "luxR_jerlov_type_error", field = "type", value = type,
      context = dataset_context
    )
  }

  if (is.null(lambda)) return(tab)
  context <- c(dataset_context, list(
    type = type, interp = interp, extrapolation = extrapolation
  ))
  .validate_jerlov_lambda(lambda, context)

  supported <- dataset_context$supported_wavelength_range_nm
  outside <- which(lambda < supported[[1L]] | lambda > supported[[2L]])
  if (length(outside) > 0L && extrapolation == "error") {
    i <- outside[[1L]]
    .stop_jerlov(
      paste0(
        "Jerlov Kd data support wavelengths from ", supported[[1L]], " to ",
        supported[[2L]], " nm; `lambda[", i, "]` is ", format(lambda[[i]]),
        " nm. Use `extrapolation = \"constant\"` only if endpoint extension ",
        "is an explicit modelling assumption."
      ),
      class = "luxR_jerlov_range_error", field = "lambda",
      value = lambda[[i]], index = i,
      context = c(context, list(
        requested_wavelength_range_nm = range(lambda),
        supported_wavelength_range_nm = supported
      ))
    )
  }

  lambda_bounded <- pmin(pmax(lambda, supported[[1L]]), supported[[2L]])
  out <- switch(
    interp,
    linear = stats::approx(tab$lambda, tab$Kd, xout = lambda_bounded,
                           rule = 1)$y,
    spline = stats::spline(tab$lambda, tab$Kd, xout = lambda_bounded,
                           method = "natural")$y,
    nearest = vapply(
      lambda_bounded,
      function(wavelength) {
        tab$Kd[[which.min(abs(tab$lambda - wavelength))]]
      },
      numeric(1)
    )
  )
  if (any(!is.finite(out)) || any(out < 0)) {
    .stop_jerlov(
      "Jerlov interpolation produced a non-finite or negative Kd value.",
      class = "luxR_jerlov_interpolation_error", field = "Kd", value = out,
      context = context
    )
  }

  attr(out, "luxR.jerlov") <- c(context, list(
    requested_wavelength_range_nm = range(lambda),
    extrapolated = length(outside) > 0L,
    extrapolated_wavelength_count = length(outside)
  ))
  out
}
