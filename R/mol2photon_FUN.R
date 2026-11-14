# mol2photon_FUN
#
# This is a function named 'mol2photon_FUN'.
#
#' Converts photon number in moles or similar to n.
#'
#' @keywords internal
#' @param value The value to be converted to photon number.
#' @param molar_unit The metric used, e.g. moles or micromoles.
#' @return The value in photons.
#
mol2photon_FUN <- function(value,molar_unit=NULL){
  if(is.null(molar_unit)){molar_unit="mol"}
  
  if(molar_unit %in% c("mol","mole","Einstein","E")){
    n = value * .AVOGADRO
  }else if(
    molar_unit %in% c("mmol","millimole","milliEinstein","mE")){
    n = value * .AVOGADRO * 1e-3
  }else if(
    molar_unit %in% c("umol","micromole","microEinstein","uE")){
    n = value * .AVOGADRO * 1e-6
  } else {
    .luxr_abort(paste0("Unrecognised molar_unit '", molar_unit, "'. ",
                       "Use 'mol', 'mmol', 'umol' or their aliases."), "unit")
  }
  return(n)
}