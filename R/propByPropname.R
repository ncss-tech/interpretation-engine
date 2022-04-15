#' Property by Property Name
#'
#' @param propname Character. Property Name
#'
#' @return a row from the `NASIS_properties` data.frame
#' @export
#'
#' @examples
#' propByPropname("SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)")
propByPropname <- function(propname) {
  props <- InterpretationEngine::NASIS_properties
  lapply(seq_along(propname), function(i) {
    props[props$propname == propname[i], ]
  })
}

#' Property Definition by Property Name
#'
#' @param propname Character. Property Name
#'
#' @return a row from the `NASIS_property_def` data.frame
#' @export
#'
#' @examples
#' propdefByPropname("SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)")
propdefByPropname <- function(propname) {
  props <- InterpretationEngine::NASIS_properties
  pdefs <- InterpretationEngine::NASIS_property_def
  lapply(seq_along(propname), function(i) {
    iid <- props[props$propname == propname[i],]$propiid
    pdefs[pdefs$propiid %in% iid, ]
  })
}

# x <- propdefByPropname("SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)")

# library(cvirrr)
# cvir <- (x[[1]]$prop |>
#   strsplit("\n"))[[1]] |>
#   cleanCVIR() |>
#   capitalizeKeywords()
# 
# res <- CVIRScript(cvir)
# library(soilDB)
# dbQueryNASIS(NASIS(), "SELECT hzdept_r, hzdepb_r, ph1to1h2o_l, ph1to1h2o_h, ph1to1h2o_r, ph01mcacl2_l, ph01mcacl2_h, ph01mcacl2_r, coiid, chiid FROM component INNER JOIN chorizon ON
# component.coiid = chorizon.coiidref WHERE ( hzdept_r < 100 OR hzdept_r = 100 ) ORDER BY component.coiid, hzdept_r,hzdepb_r")
