
# get all properties for single coiid and vector of property IDs
# TODO: vectorize over both arguments
# TODO: parallel requests?
# https://cran.r-project.org/web/packages/curl/vignettes/intro.html#async_requests

# this web report undestands multiple component rec. ids
#' Lookup Properties using NASIS Web Report
#' 
#' This function uses `WEB-PROPERY-COMPONENT_property` NASIS Web Report to lookup property data
#'
#' @param coiid Vector of component IDs (`coiid`)
#' @param propIDs Vector of property IDs 
#'
#' @return properties?
#' @export
#'
#' @importFrom soilDB parseWebReport
#' @importFrom plyr ldply
lookupProperties <- function(coiid, propIDs) {
  
  # get a single property for a single component
  .getSingleProperty <- function(i, coiid) {
    url <- 'https://nasis.sc.egov.usda.gov/NasisReportsWebSite/limsreport.aspx?report_name=WEB-PROPERY-COMPONENT_property'
    args <- list(prop_id=i, cokey=coiid)
    res <- parseWebReport(url, args, index=1)
    
    # HTTP errors will result in NULL
    if(is.null(res))
      return(NULL)
    
    # otherwise, add property name back to the results for joining
    res <- cbind(propiid=i, res)
    return(res)
  }
  
  # convert back to DF and return
  res <- ldply(propIDs, .getSingleProperty, coiid=coiid, .progress='text')
  return(res)
}
