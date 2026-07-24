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
    n = value * 6.02214076e23
  }else if(
    molar_unit %in% c("mmol","millimole","milliEinstein","mE")){
    n = value * 6.02214076e20
  }else if(
    molar_unit %in% c("umol","micromole","microEinstein","uE")){
    n = value * 6.02214076e17
  } else {
    stop("Unrecognised molar_unit '", molar_unit, "'. ",
         "Use 'mol', 'mmol', 'umol' or their aliases.")
  }
  return(n)
}