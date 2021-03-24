### this script accesses NASIS property data needed for the Valley Fever calculation, an entire state at a time
### It is very slow, regardless of area size, and should be used to create a data cache only

### to do 
## is the xeric part working? should GC UT be non-xeric?
## add time estimate output

setwd("E:/NMSU/interpretation-engine/")

require(plyr)
require(tidyverse)
require(sf)
require(raster)
require(XML)
require(digest)
require(data.tree)
require(dplyr)
require(soilDB)

## if you have a list of nasis coiid values, enter it here
## (NB: Not cokeys from SDA or other projects. Only coiids)
v.coiid <- NULL

## if no list of coiids is supplied, it will default to pulling all coiids from the specified state
## (2 letter code)
stcode <- "RI"

## currently, this has do be done one state at a time
## one way to get multi-state data at once would be to get a list of coiids independently

### 1: do things in NASIS ####
#### You maybe dont actually have to do this??? Just need nasis for the crosswalk
### open NASIS download all component, map unit, and legend tables for the state
### use the query 'NSSC Pangaea::Area/Legend/Mapunit/DMU by areasymbol (official data)'
### load them into the selected set
### keep them there until this entire script is run

### 2: get list of NASIS coiid's to work with (skipped if v.coiid defined above) ####
## here, this loads from a crosswalk file connecting NASIS and SDA keys. 
## Any vector of coiids (not cokeys) will work.

## load the crosswalk
dbcrosswalk <- read.csv(paste0("dbcrosswalk/dbcrosswalk_inner_", stcode, ".csv"))

if(is.null(v.coiid)){
  ## get the nasis coiids from that state
  v.coiid <- dbcrosswalk[dbcrosswalk$state == stcode, "coiid"] %>% as.character() %>% as.vector()
}

### 3: get and save property data associated with those coiids ####
## load nasis cache containing id codes for the nasis evaluations, and functions to work with it
source('Engine Guts/Functions/local-functions.R')
load('Engine Guts/cached-NASIS-data.Rda')

dt <- initRuleset('Soil Habitat for Saprophyte Stage of Coccidioides')
ps <- getPropertySet(dt)

#### ADD XERIC MLRA FLAG ####
#ps$propiid <- c(ps$propiid, 15380)

### loading the nasis data is slow, and *must* save intermediates along the way. 
### This code does this by saving chunks of 100 components at a time
v.splitcoiid <- split(v.coiid, ceiling(seq_along(v.coiid)/100))

### iterate through the split list, pulling in the properties specified in 'ps' and saving them. 
### this is very slow
if(!dir.exists("Input")) dir.create("Input")
if(!dir.exists("Input/VF/")) dir.create("Input/")
if(!dir.exists("Input/VF/NASIS Property Tables")) dir.create("Input/NASIS Property Tables")
if(!dir.exists(paste0("Input/VF/NASIS Property Tables/", stcode))) {
  dir.create(paste0("Input/VF/NASIS Property Tables/", stcode))
}

for(i in 1:length(v.splitcoiid)){
  name <- 
    paste0("Input/VF/NASIS Property Tables/", stcode, 
           "/VFpropertyChunk", stcode, i, ".rdata")
  print(paste("Writing chunk", i, "of", length(v.splitcoiid)))
  
  if(file.exists(name))
  {
    ## all this code does is write the files; no action taken if the file exists   
  } else {
    vv <- v.splitcoiid[[i]]
    l.props <- list()
    
    for(j in 1:length(vv)){
      l.props[[j]] <- lookupProperties(
        coiid = vv[j],
        propIDs = unique(ps$propiid)
      )
    }
    
    save(
      l.props,
      file = name
    )
  }
}

### 4: load and compile the property data ####

## find the rdata files saved in step 3
v.paths <- 
  list.files(path = paste0("Input/VF/NASIS Property Tables/", stcode),
             pattern = paste0("VFpropertyChunk", stcode), full.names = T)

## load each one and combine into a single data frame
for(i in 1:length(v.paths)){
  
  if(i==1){
    ## create an empty data frame, will be filled out as the for loops
    t.nasisdata <- data.frame(propiid = "", # at this point, its one row per property
                              coiid = "",
                              comp_name = "",
                              comp_pct = "",
                              rv = "") ## and all the property values in a single column
  }

  load(v.paths[i])
  ## each rdata file contails an object "l.props"
  ## l.props is a list of dataframes, length 100 (except the last one, which is a remainder)
  
  ## each data frame contains all the needed property values for a single component
  ## (colnames as set above when defining the empty data frame)
  
  ## flatten the list into a single table
  t <- do.call(rbind, l.props)
  
  ## and tack that table onto t.nasisdata
  t.nasisdata <- rbind(t.nasisdata, t)
}

### 5: reshape and rename ####
## reshape the dataframe to have one row per component
## and while we're at it, attach names to the properties (not just propiids)

## this ensures that the join columns work
t.nasisdata$coiid <- as.character(t.nasisdata$coiid)
dbcrosswalk$coiid <- as.character(dbcrosswalk$coiid)

##
t.nasisjoin <- 
  left_join(
    t.nasisdata,
    ps[,c("propiid", "propname")], 
    by = "propiid"
  ) %>%
  distinct() %>%
  pivot_wider(
    id_cols = c(coiid, comp_name),
    names_from = propname,
    values_from = rv,
    values_fn = first) %>%
  left_join(
    dbcrosswalk,
    by = "coiid"
  ) 


head(t.nasisjoin)
# this should have ~32 variables, all with nasis names like `DEPTH TO CEMENTED PAN THIN, BELOW O HORIZON`.
# there will be many NA's!

## rename the nasis data to more concise names, 
## ensure all data types are correct, 
## and process the non-numeric rasters into logicals ### didnt have to do this one

t.nasisrename <-
  t.nasisjoin %>%
  mutate(
    ## first four used by the chem subrule
    sar = as.numeric(`WTD_AVG SAR 0-30cm OR ABOVE RESTRICTION`),
    ec = as.numeric(`WTD_AVG EC 0-30cm OR ABOVE RESTRICTION`),
    gypsumcontent = as.numeric(`GYPSUM MAXIMUM, 0-50CM OR FIRST RESTRICTION`),
    ph = as.numeric(`SOIL REACTION 1-1 WATER MINIMUM IN DEPTH 0-30CM`),
    
    ## next used in climate subrule
    xeric = as.numeric(`XERIC BIOLOGIC CLIMATE`), # t/f (with '0' also occurring)
    map = as.numeric(`MEAN ANNUAL PRECIPITATION FROM H&L`), #mean annual precip -- used twice, with difft eqn if xeric or not
    albedo = as.numeric(`ALBEDO`), 
    slope = as.numeric(`SLOPE`),
    #aspectfactor = as.numeric(`VALLEY FEVER ASPECT FACTOR`), # uses complex subrules, derived from aspect. cut it and recreate the derivation code
    airtemp = as.numeric(`MEAN ANNUAL AIR TEMPERATURE, FROM H&L`),
    
    ## used in climate, look like they can be removed (use XERIC flag & air temp)
    #xericairtempchopper = as.numeric(`XERIC AIR TEMPERATURE CHOPPER, FROM H&L`), # subrules, but derives from airtemp  possibly just airtemp/16??
    #nonxericairtempchopper = as.numeric(`NON-XERIC AIR TEMPERATURE CHOPPER, FROM H&L`),
    
    ## no subrule
    wrd = as.numeric(`WTD_AVG WRD 0-30cm OR ABOVE RESTRICTION`),
    watergatheringsurface = as.numeric(`WATER GATHERING SURFACE SIMPLE`), # categorical, 0 1 2 or 3 depending on slope shape  Would be convertible to cross and down slope shape but thats hard
    om = as.numeric(`ORGANIC CARBON IN KG/M2 TO 30CM`),
    saturationmonths = as.numeric(`CUMULATIVE NEAR SURFACE SATURATION`),
    floodmonths = as.numeric(`MONTHS WITH FREQUENT OR OCCASIONAL LONG PONDING`)
  ) %>%
  dplyr::select(
    cokey, coiid, comp_name, comppct, mukey, muiid, lkey, liid, dmuiid, state, key.join, 
    sar, ec, gypsumcontent, ph,
    map,  albedo, slope, airtemp, #aspectfactor,xeric, 
    #xericairtempchopper, nonxericairtempchopper,
    wrd, watergatheringsurface, om, saturationmonths, floodmonths
  ) %>%
  arrange(
    mukey,
    -comppct
  #) %>%
  # group_by(
  #   mukey
  # ) %>%
  # summarize_all(first
     ) %>%
  mutate(mukey = as.character(mukey), cokey = as.character(cokey))

### the vf validation data uses all the components, and takes the highest fuzzy val from them all. don't summarize to the top component.

### 6: adjustments ####
# data drawn from nasis is coerced to integer
# this is a problem for several vf properties
# here, I pull data in from a saved SSURGO component table and overwrite
### albedo: pull directly from ssurgo
### aspect factor: pull aspectrep (0-360) from ssurgo, translate the nasis math inside the calc function
### air temp choppers: pull air temp from ssurgo, translate nasis math inside the calc function

path.gssurgo <- paste0("E:/NMSU/Data/gSSURGO/gSSURGO_", "UT", ".gdb")
gssurgo.component.full <- sf::st_read(dsn = path.gssurgo, layer = "component") %>% 
  mutate(mukey = as.character(mukey), cokey = as.character(cokey)) 

# gssurgo.mapunit.full <- sf::st_read(dsn = path.gssurgo, layer = "mapunit") %>% 
#   mutate(mukey = as.character(mukey)) 
# 
# gssurgo.all <- sapply(st_layers(path.gssurgo)$name, function(l)
#                               sf::st_read(dsn = path.gssurgo, layer = l))
# 
# gssurgo.colnames <- sapply(gssurgo.all, colnames) %>% unlist()
# 
# gssurgo.colnames[which(grepl("mlra", gssurgo.colnames))]



gssurgo.component <- 
  gssurgo.component.full %>%
  mutate(xeric = grepl("xer", taxsubgrp) |
                  grepl("xer", taxsuborder)) %>%
  dplyr::select("albedodry_r", 
                "aspectrep",
                "xeric", 
                "taxsubgrp", 
                "taxsuborder",
                "cokey")
  

gssurgo.component

# define rv	isnull(taxsuborder) then 0 else if 
# taxsuborder imatches "xer*" then 1 else if
# taxsubgrp imatches "*xer*" then 1 else  if 
# xericmlra == 1 then 1 else .8.


# %>%
#   mutate(
#     aspectfactor_calc = if_else( ## this is translated from cvir "VALLEY FEVER ASPECT FACTOR", property 35987
#       ### it has to be recreated here because web export turns the 0-1 decimal into 0 or 1 integer
#       is.na(aspectrep), 0,
#       if_else(
#         aspectrep >= 0 & aspectrep < 0, 0,
#         if_else(
#           aspectrep >= 80 & aspectrep < 280, -((aspectrep-180)**2)/9000+1,
#           0 # if all false
#         )
#       )
#     )
#   ) 


#### CUT THE CHOPPERS ENTIRELY
### HARD CODE INTO THE FUNCTION TO DO THE RATIO BASED ON A NORMAL INPUT MEASURE, AIRTEMP
# %>%
#   mutate( # these translated from CVIR air temp choppers, props 35988 and 35989 
#     xericairtempchopper_calc = airtempa_r / 16,
#     nonxericairtempchopper_calc = airtempa_r / 18.5
#   )


t.nasisrename <- 
  left_join(
    t.nasisrename,
    gssurgo.component
  ) %>% 
  mutate(
    albedo = albedodry_r,
    aspect = aspectrep
    # xericairtempchopper = xericairtempchopper_calc,
    # nonxericairtempchopper = nonxericairtempchopper_calc
  ) %>%
  dplyr::select(
    -albedodry_r,
    -aspectrep
    #-aspectfactor
    # -xericairtempchopper_calc
    # -nonxericairtempchopper_calc
  )

### 7: Save ####

 write.csv(t.nasisrename,
           file = paste0("Input/VFpropertyData-", stcode, ".csv"), row.names = F)

# write.csv(t.nasisrename,
#           file = paste0("Input/VFpropertyTestData-", stcode, ".csv"), row.names = F)
# 
# write.csv(t.nasisjoin,
#           file = paste0("Input/VFpropertyTestDataNoRename-", stcode, ".csv"), row.names = F)
# 
