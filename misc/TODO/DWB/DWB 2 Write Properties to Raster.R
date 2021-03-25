### this script rasterizes generated NASIS property data (from the corresponding r script)
### it also requires a gssurgo or other database with map unit polygons

#setwd("E:/NMSU/interp-engine-personal/TEST FULL WORKFLOW")

require(raster)
require(tidyverse)
require(sf)
require(dplyr)

## this projectcode is prefixed to all final & intermediate outputs; used for file organization
projectcode <- "UTGrand250"

## define master crs, all files will be transformed into this
crs <- raster::crs("+init=epsg:5070")

## define desired output resolution
res <- 250

## nasis properties are organized by state. enter the 2 letter state code here. 
stcode <- "UT"

## load a study area with sf (any polygon will do)
## this will be used to define a raster template below
sf.studyarea <-
  sf::st_read(dsn = "E:/NMSU/GIS/Utah_County_Boundaries-shp", layer = "Counties") %>%
  subset(NAME == "GRAND")

## load a gssurgo database containing the entire study area (must contain map unit polygons)
sf.mupolygon <- sf::st_read(dsn = "E:/NMSU/Data/gSSURGO/gSSURGO_UT.gdb", layer = "MUPOLYGON")


### 1 Attach nasis data to map unit polygons ####
## data quality stuff that I cut out of the abbreviated code above
sf.studyarea <- sf.studyarea %>% st_transform(crs) %>% st_make_valid()
sf.mupolygon <- sf.mupolygon %>% dplyr::rename(mukey = MUKEY) %>% st_transform(crs) %>% st_make_valid()

## limit mupolygons to a test area ##
sf.mupolygon.subset <-
  st_intersection(sf.mupolygon, sf.studyarea) %>%
  mutate(mukey = as.character(mukey))

## load nasis data written in part 1
df.nasis <-
  read.csv(paste0("Input/DWB/NASIS Property Tables/DWBpropertyData-", stcode, ".csv")) %>%
  mutate(mukey = as.character(mukey))

## attach all the nasis data to the study area polygon(s)
sf.nasis <-
  left_join(sf.mupolygon.subset,
            df.nasis,
            by = "mukey")

### 2 rasterize nasis data polygons ####
## create a template raster with the extent, crs, and resolution needed
r.template <-
  raster(
    extent(sf.studyarea),
    resolution = res,
    crs = crs
  )

## identify which columns (from sf.nasis / df.nasis) to rasterize
vec.layernames.dwb <- 
  c("permdepth", # permafrost depth (cm)
    "slope_r", # mean slope (%)
    "totalsub_r", # total subsidence (cm)
    "wt", # depth to water table (cm)
    "lep", # percent linear extensibility of thickest layer (%)
    "depbrockhard", # depth to hard bedrock (cm)
    "depbrocksoft", # depth to soft bedrock (cm)
    "fragvol_wmn", # percent content of large stones (%)
    #"restricthardness", # relict. if this shows up anywhere else, it escaped deletion
    "depcementthick", # depth to thick cement layer (cm)
    "depcementthin", # depth to thin cement layer (cm)
    "unstablefill", # presence/absence of unstable fill soil (1/0)
    "gypsum", # subsidence due to gypsum (cm)
    "impaction", # presence/absence of impaction (1/0)
    "drainageclass", # presence/absence of subaqueous drainage class (1/0)
    "pftex", # presence/absence of permafrost soil textures (1/0)
    "ponding", # presence/absence of ponding (1/0)
    "flooding", # presence/absence of flooding (1/0)
    #"noncemented", # used to override the depcement variables. Relict that may have escaped
    "organicsoil" # presence/absence of high organic matter soil classes (1/0) 
    )

## directory management (all rasters saved to the same place)
if(!dir.exists("Input")) dir.create("Input")
if(!dir.exists("Input/DWB")) dir.create("Input/DWB")
if(!dir.exists("Input/DWB/NASIS Property Rasters")) dir.create("Input/DWB/NASIS Property Rasters")
if(!dir.exists(paste0("Input/DWB/NASIS Property Rasters/", projectcode))) {
  dir.create(paste0("Input/DWB/NASIS Property Rasters/", projectcode))
}

l.r <- sapply(
  vec.layernames.dwb,
  function(l){
    print(l)
    name <- paste0("Input/DWB/NASIS Property Rasters/", projectcode, "/", projectcode, "_", l, ".tif")
    if(file.exists(name)){
      print("Loading existing raster")
      r <- raster(name)
    } else {
      print("Writing new raster")
      p <- sf.nasis[l]
      r <- rasterize(
        x = p,
        field = l,
        y = r.template,
        filename = name,
        driver = "GTiff"
      ) %>% mask(sf.studyarea)
    }
    return(r)
  }
)

