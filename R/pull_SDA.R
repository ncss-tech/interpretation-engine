# Quick SDA data acquisition
# Joe Brehm
# last edited 12/1/2020

## added a function to allow "like" commands
#' Quick SDA data acquisition
#' This function is a shortcut for loading in a broad set of SDA data, filtered to area symbols specified by an input character vector.
#' 
#' The following tables are returned:
#' 
#' - `legend`
#' - `mapunit`
#' - `component`
#' - `chorizon`
#' - `corestrictions`
#' - `cosurffrags`
#' - `cotaxfmmin`
#' - `codiagfeatures`
#' - `comonth`
#' - `chtexturegrp`
#' - `chfrags`
#' - `chtexture`
#' - `cosoilmoist`
#' - `muaggatt`
#' - `chunified`
#' - `cointerpENG` -- "ENG" rules only though
#' 
#' @param asym character. Area symbol
#' @param fun Default: "in" uses SQL "IN" operator. Alternately: "like".
#'
#' @author Joseph Brehm
#' @return SDA table result
#' @export
#' @importFrom soilDB SDA_query
pull_SDA <- function(asym, fun = "in") {
  ls.tables.sda <- list()
  
  # convert from character vector to a text string SDA_query can parse, using either an in or like areasymbol filter
  if (fun == "in") {
    parsesym <- paste0(" ('", paste0(asym, collapse = "', '"), "')")
    
    w <- paste0(" WHERE areasymbol IN", parsesym)
    
  } else if (fun == "like") {
    if (length(asym) > 1)
      stop("Only one area symbol at a time with the 'like' function")
    
    w <- paste0(" WHERE areasymbol LIKE '%", asym, "%'")
  }
  
  message("Pulling data from Soil Data Access for ", asym)
  
  #for all queries:
  ## get a list of keys in the selected area symbols
  ## attach data from the specified tables
  ## don't forget to left join when subordinate to component
  ## then drop the far left column, which is a duplicate key column
  
  ### tables above or parallel component ####
  ls.tables.sda[["legend"]] <-
    soilDB::SDA_query(paste0(
      "SELECT *
     FROM legend", 
      w))
  
  ls.tables.sda[["mapunit"]] <-
    soilDB::SDA_query(paste0(
      "WITH m AS (SELECT mukey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                ", w, ")
     SELECT *
     FROM m
     INNER JOIN mapunit ON m.mukey = mapunit.mukey")) |>
    dplyr::select(-1)
  
  ls.tables.sda[["component"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     INNER JOIN component ON c.cokey = component.cokey")) |>
    dplyr::select(-1)
  
  
  ### tables beneath component ####
  
  ls.tables.sda[["dwb"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     INNER JOIN cointerp ON c.cokey = cointerp.cokey
     WHERE mrulename = 'ENG - Dwellings With Basements'")) |>
    dplyr::select(-1)
  
  
  ls.tables.sda[["chorizon"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN chorizon ON c.cokey = chorizon.cokey")) |>
    dplyr::select(-1)
  
  ls.tables.sda[["corestrictions"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN corestrictions ON c.cokey = corestrictions.cokey"))[,-1]
  
  ls.tables.sda[["cosurffrags"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN cosurffrags ON c.cokey = cosurffrags.cokey"))[,-1]
  
  ls.tables.sda[["cotaxfmmin"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN cotaxfmmin ON c.cokey = cotaxfmmin.cokey"))[,-1]
  
  ls.tables.sda[["codiagfeatures"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN codiagfeatures ON c.cokey = codiagfeatures.cokey"))[,-1]
  
  ls.tables.sda[["comonth"]] <-
    soilDB::SDA_query(paste0(
      "WITH c AS (SELECT cokey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                INNER JOIN component ON component.mukey = mapunit.mukey
                ", w, ")
     SELECT *
     FROM c
     LEFT JOIN comonth ON c.cokey = comonth.cokey"))[,-1]
  
  ### tables beneath chorizon ####
  
  ls.tables.sda[["chtexturegrp"]] <-
    soilDB::SDA_query(paste0(
      "WITH ch AS (SELECT chkey 
                 FROM legend
                 INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                 INNER JOIN component ON component.mukey = mapunit.mukey
                 LEFT JOIN chorizon ON chorizon.cokey = component.cokey
                 ", w, ")
     SELECT *
     FROM ch
     LEFT JOIN chtexturegrp ON ch.chkey = chtexturegrp.chkey"))[,-1]
  
  ls.tables.sda[["chfrags"]] <-
    soilDB::SDA_query(paste0(
      "WITH ch AS (SELECT chkey 
                 FROM legend
                 INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                 INNER JOIN component ON component.mukey = mapunit.mukey
                 LEFT JOIN chorizon ON chorizon.cokey = component.cokey
                 ", w, ")
     SELECT *
     FROM ch
     LEFT JOIN chfrags ON ch.chkey = chfrags.chkey"))[,-1]
  
  ls.tables.sda[["chunified"]] <-
    soilDB::SDA_query(paste0(
      "WITH ch AS (SELECT chkey 
                 FROM legend
                 INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                 INNER JOIN component ON component.mukey = mapunit.mukey
                 LEFT JOIN chorizon ON chorizon.cokey = component.cokey
                 ", w, ")
     SELECT *
     FROM ch
     LEFT JOIN chunified ON ch.chkey = chunified.chkey"))[,-1]
  
  ### other tables ####
  
  ls.tables.sda[["chtexture"]] <-
    soilDB::SDA_query(paste0(
      "WITH chtg AS (SELECT chtgkey 
                   FROM legend
                   INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                   INNER JOIN component ON component.mukey = mapunit.mukey
                   LEFT JOIN chorizon ON chorizon.cokey = component.cokey
                   LEFT JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey
                   ", w, ")
     SELECT * 
     FROM chtg
     LEFT JOIN chtexture ON chtg.chtgkey = chtexture.chtgkey"))[,-1]
  
  ls.tables.sda[["chtexturemod"]] <-
    soilDB::SDA_query(paste0(
      "WITH cht  AS (SELECT chtkey 
                   FROM legend
                   INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                   INNER JOIN component ON component.mukey = mapunit.mukey
                   LEFT JOIN chorizon ON chorizon.cokey = component.cokey
                   LEFT JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey
                   LEFT JOIN chtexture ON chtexturegrp.chtgkey = chtexture.chtgkey
                   ", w, ")
     SELECT * 
     FROM cht
     LEFT JOIN chtexturemod ON cht.chtkey = chtexturemod.chtkey"))[,-1]
  
  
  
  
  ls.tables.sda[["cosoilmoist"]] <-
    soilDB::SDA_query(paste0(
      "WITH com AS (SELECT comonthkey 
                   FROM legend
                   INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                   INNER JOIN component ON component.mukey = mapunit.mukey
                   LEFT JOIN comonth ON comonth.cokey = component.cokey
                   ", w, ")
     SELECT * 
     FROM com
     LEFT JOIN cosoilmoist ON com.comonthkey = cosoilmoist.comonthkey"))[,-1]
  
  ls.tables.sda[["muaggatt"]] <-
    soilDB::SDA_query(paste0(
      "WITH m AS (SELECT mukey 
                FROM legend
                INNER JOIN mapunit ON mapunit.lkey = legend.lkey
                ", w, ")
     SELECT *
     FROM m
     INNER JOIN muaggatt ON m.mukey = muaggatt.mukey"))[,-1]
  
  ### end ####
  return(ls.tables.sda)
}

