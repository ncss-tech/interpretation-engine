
# TODO: parallel requests?
# https://cran.r-project.org/web/packages/curl/vignettes/intro.html#async_requests

# get a single property for a single component
.getSingleProperty <- function(i, coiid) {
  url <- 'https://nasis.sc.egov.usda.gov/NasisReportsWebSite/limsreport.aspx?report_name=WEB-PROPERY-COMPONENT_property'
  args <- list(prop_id = i, cokey = coiid)
  res <- parseWebReport(url, args, index = 1)

  # HTTP errors will result in NULL
  if (is.null(res)) {
    return(NULL)
  }

  # otherwise, add property name back to the results for joining
  res <- cbind(propiid = i, res)
  return(res)
}

# this web report undestands multiple component rec. ids
#' Lookup Properties using NASIS Web Report
#'
#' This function uses `WEB-PROPERY-COMPONENT_property` NASIS Web Report to look up component property data
#'
#' @param coiid Vector of component IDs (`coiid`)
#' @param propIDs Vector of property IDs
#'
#' @return A data.frame containing `propiid`, `coiid`, `comp_name`, `comp_pct` and the representative value for the property (`rv`).
#' @export
#'
#' @importFrom soilDB parseWebReport
lookupProperties <- function(coiid, propIDs) {

  # convert back to DF and return
  res <- do.call('rbind', lapply(seq_along(coiid), function(j) {
    do.call('rbind', lapply(seq_along(propIDs), function(i) {
      .getSingleProperty(propIDs[i], coiid = coiid[j])
    }))
  }))
  return(res)
}
