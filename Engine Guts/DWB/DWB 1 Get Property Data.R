### this script accesses NASIS property data needed for the DWB calculation, an entire state at a time
### It is very slow, regardless of area size, and should be used to create a data cache only
### it also requires NASIS, and is an interactive process (you have to load data one area at a time)

require(plyr)
require(tidyverse)
require(sf)
require(raster)
require(XML)
require(digest)
require(data.tree)
require(dplyr)
require(soilDB)

### to do
## parallel!
## check drainage class, it looks off as a raster
## add time estimate output

setwd("E:/NMSU/interpretation-engine/")

## if you have a list of nasis coiid values, enter it here
## (NB: Not cokeys from SDA or other projects. Only coiids)
v.coiid <- NULL

## if no list of coiids is supplied, it will default to pulling all coiids from the specified state
## (2 letter codes)
stcode <- "RI"

## currently, this has do be done one state at a time
## one way to get multi-state data at once would be to get a list of coiids independently


### 1: do things in NASIS ####
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

dt <- initRuleset('ENG - Dwellings With Basements')
ps <- getPropertySet(dt)

### loading the nasis data is slow, and *must* save intermediates along the way. 
### This code does this by saving chunks of 100 components at a time
v.splitcoiid <- split(v.coiid, ceiling(seq_along(v.coiid)/100))

### iterate through the split list, pulling in the properties specified in 'ps' and saving them. 
### this is very slow
for(i in 1:length(v.splitcoiid)){
  if(!dir.exists("Input")) dir.create("Input")
  if(!dir.exists("Input/DWB/")) dir.create("Input/DWB/")
  if(!dir.exists("Input/DWB/NASIS Property Tables")) dir.create("Input/NASIS Property Tables")
  if(!dir.exists(paste0("Input/DWB/NASIS Property Tables/", stcode))) {
    dir.create(paste0("Input/DWB/NASIS Property Tables/", stcode))
  }
  
  name <- 
    paste0("Input/DWB/NASIS Property Tables/", stcode, 
           "/DWBpropertyChunk", stcode, i, ".rdata")
  print(paste("Writing chunk", i, "of", length(v.splitcoiid)))
  
  if(!file.exists(name))
  {
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
  list.files(path = paste0("Input/DWB/NASIS Property Tables/", stcode),
             pattern = paste0("DWBpropertyChunk", stcode), full.names = T)

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
  ## l.props is a list of dataframes, length 100 (except the last one)
  
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
## and process the non-numeric rasters into logicals
t.nasisrename <- 
  t.nasisjoin %>% dplyr::rename(
    depbrockhard = `DEPTH TO BEDROCK HARD, BELOW O HORIZON`,
    fragvol_wmn = `FRAGMENTS > 75MM WEIGHTED AVE. IN DEPTH 0-100CM`,
    permdepth = `DEPTH TO PERMAFROST`,
    floodfreq = `FLOODING FREQUENCY (Maximum Frequency)`,
    depbrocksoft = `DEPTH TO BEDROCK SOFT, BELOW O HORIZON`,
    lep = `LEP WTD_AVG 25-150cm OR ABOVE RESTRICTION, BELOW O HORIZON`,
    slope_r = `SLOPE`,
    depcementthick = `DEPTH TO CEMENTED PAN THICK, BELOW O HORIZON`,
    restricthardness = `RESTRICTIVE FEATURE HARDNESS`,
    depcementthin = `DEPTH TO CEMENTED PAN THIN, BELOW O HORIZON`,
    totalsub_r = `SUBSIDENCE TOTAL`,
    wt = `HIGH WATER TABLE DEPTH MINIMUM`,
    gypsum = `SUBSIDENCE DUE TO GYPSUM, REV`,
    bottomtexture = `UNIFIED BOTTOM LAYER`,
    texmod = `USDA TEXTURE MODIFIER`,
    texinlieu = `USDA TEXTURE (IN-LIEU-OF)`,
    ponddur = `PONDING DURATION`,
    pondfreq = `PONDING FREQUENCY`,
    unstablefill = `COMPONENT LOCAL PHASE UNSTABLE FILL`,
    impaction = `COMPONENT LOCAL PHASE IMPACTED`,
    drainageclass = `DRAINAGE CLASS IS NOT SUBAQUEOUS`
  ) %>% 
  mutate(
    texinlieu = as.factor(texinlieu),
    texmod = as.factor(texmod),
    permdepth = as.numeric(permdepth),
    pondfreq = as.factor(pondfreq),
    ponddur = as.factor(ponddur),
    slope_r = as.numeric(slope_r),
    totalsub_r = as.numeric(totalsub_r),
    floodfreq = as.factor(floodfreq),
    wt = as.numeric(wt),
    lep = as.numeric(wt),
    bottomtexture = as.factor(bottomtexture),
    depbrockhard = as.numeric(depbrockhard),
    depbrocksoft = as.numeric(depbrocksoft),
    fragvol_wmn = as.numeric(fragvol_wmn),
    restricthardness = as.factor(restricthardness),
    depcementthick = as.numeric(depcementthick),
    depcementthin = as.numeric(depcementthin),
    unstablefill = as.factor(unstablefill),
    gypsum = as.numeric(gypsum),
    impaction = as.factor(impaction),
    drainageclass = as.factor(drainageclass),
    mukey = as.character(mukey),
    cokey = as.character(cokey),
    lkey = as.character(lkey),
    muiid = as.character(muiid),
    coiid = as.character(coiid),
    liid = as.character(liid),
    dmuiid = as.character(dmuiid),
    comppct = as.integer(comppct)
  ) %>% # limit to only majority components, so it can be one to a map unit
  arrange(
    mukey,
    -comppct
  ) %>%
  group_by(
    mukey
  ) %>%
  summarise_all(
    first
  ) %>% # do the conversion to logicals here
  mutate(
    pftex = grepl(pattern = "cpf", x = texinlieu) | grepl(pattern = "pf", x = texmod),
    ponding = 
      (tolower(str_trim(ponddur)) %in% c("very brief", "brief", "long", "very long") & !is.na(ponddur)) |
      (tolower(str_trim(pondfreq)) != "none" & !is.na(pondfreq)),
    flooding = tolower(str_trim(floodfreq)) %in% c("very rare", "rare", "occasional", "frequent", "very frequent"),
    organicsoil = grepl("(pt)|(ol)|(oh)", bottomtexture),
    noncemented = tolower(str_trim(restricthardness)) == "noncemented", # this var is no longer used anywhere after this step
    unstablefill = unstablefill == "1",
    impaction = impaction == "1",
    drainageclass = drainageclass == "1"
  )
### 6: Save ####
write.csv(t.nasisrename,
          file = paste0("Input/DWBpropertyData-", stcode, ".csv"))

