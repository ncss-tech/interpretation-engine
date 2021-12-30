
#' Lookup Rating Classes by Rule ID
#'
#' @param ruleiidref Rule ID
#'
#' @return A data.frame containing columns `ruleiidref` (Rule ID), `ratingclassname`, `ratingclassupperboundary` and `ruleratingclassiid`
#' @export
#
#' @importFrom soilDB format_SQL_in_statement dbQueryNASIS NASIS
lookupRatingClass <- function(ruleiidref) {
  soilDB::dbQueryNASIS(soilDB::NASIS(), paste0("SELECT ruleiidref, ratingclassname, ratingclassupperboundary, ruleratingclassiid 
                                                FROM ruleratingclass 
                                                WHERE ruleiidref IN ", soilDB::format_SQL_in_statement(ruleiidref)))
}

