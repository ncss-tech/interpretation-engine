#### InteRpretations Engine ###
#### version 0.9 2021-3-23
### Joe Brehm, jrbrehm@nmsu.edu

#### TO DO LIST
### All
## fix levelPlot code or replace with another categorical raster plotter
## move factoring code into the functions
## demo layer substitution
## demo with tabular and vector data
#### HSG & SVI
## Faster as raster math? Data trees as preferred structure didn't pan out for DWB and VF
## tree_eval : Improve parallelization
## svi_calc & hsg_calc : inherent raster mode (copy from calc_dwb code)
## tree_eval : rename to navigate_tree()
## svi_calc : write a function to do shorthsg if in a dataframe, or if a parameter set
#### DWB
## prune the list of layers
## unify naming convention with VF (continuous to fuzzdwb)

require(tidyverse)
require(rasterVis) # used for currently broken categorical plots
require(sf)

#@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#@@@@# USER INPUT HERE #@@@@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## 0.1 run parameters ### ###
# set to the interp engine
setwd("E:/NMSU/interpretation-engine")

# project code is used to organize input and output
projectcode <- "UTGrand250"

# all output will be in this crs (5070 = albers AEA conus)
crs <- raster::crs("+init=epsg:5070")

sf.studyarea <-
  sf::st_read(dsn = "demo files/Utah_County_Boundaries-shp", layer = "Counties") %>%
  subset(NAME == "GRAND") %>% st_transform(crs) %>% st_make_valid()


#@@@@@@@@@@@@@@@@@@@@@@@@@@@#

## 0.2 load packages and engine functions ####

source("Engine Guts/Functions/local-functions.r")
load("Engine Guts/cached-NASIS-data.rda")
load("Engine Guts/HSG/datatree-hsg.rdata")
load("Engine Guts/SVI/datatree-svi.rdata")

## everything from here shouldnt need input 
paths.dwb <- list.files(path = paste0("Input/DWB/NASIS Property Rasters/", projectcode), pattern = "tif$", full.names = T)
paths.vf <- list.files(path = paste0("Input/VF/NASIS Property Rasters/", projectcode), full.names = T)
paths.hsg <- list.files(path = paste0("Input/HSG/", projectcode), pattern = "tif$", full.names = T)
paths.svi <- list.files(path = paste0("Input/SVI/", projectcode), pattern = "tif$", full.names = T)

brick.dwb <- brick(sapply(paths.dwb, raster)) %>% projectRaster(crs = crs)
brick.vf <- brick(sapply(paths.vf, raster)) %>% projectRaster(crs = crs)
brick.hsg <- brick(sapply(paths.hsg, raster)) %>% projectRaster(crs = crs)
brick.svi <- brick(sapply(paths.svi, raster)) %>% projectRaster(crs = crs)

## get the layer names from the file basenames, dropping prefix and extension
names.dwb <- basename(paths.dwb) %>% 
  gsub(pattern = paste0(projectcode, "_"), replacement = "") %>%
  gsub(pattern = ".tif", replacement = "")
names(brick.dwb) <- names.dwb

names.vf <- basename(paths.vf) %>% 
  gsub(pattern = paste0(projectcode, "_"), replacement = "") %>%
  gsub(pattern = ".tif", replacement = "")
names(brick.vf) <- names.vf

names.hsg <- basename(paths.hsg) %>% 
  gsub(pattern = paste0(projectcode, "_"), replacement = "") %>%
  gsub(pattern = ".tif", replacement = "")
names(brick.hsg) <- names.hsg

names.svi <- basename(paths.svi) %>% 
  gsub(pattern = paste0(projectcode, "_"), replacement = "") %>%
  gsub(pattern = ".tif", replacement = "")
names(brick.svi) <- names.svi

## 1.1 check data
plot(brick.dwb) # drainageclass looks wrong
summary(brick.dwb)

plot(brick.vf)
summary(brick.vf)

plot(brick.hsg)
summary(brick.hsg)

plot(brick.svi)
summary(brick.svi)

### 2 interp demos ####
## 2.1 HSG ####

df.hsg <- as.data.frame(brick.hsg)
t1 <- Sys.time()
df.hsg$hsg <- hsg_calc(df.hsg)
timeHSG <- Sys.time() - t1

### factoring, move this into hsg_calc
out.hsg <-   
  brick.hsg$wt %>%
  setValues(factor(df.hsg$hsg,
                   levels = rev(c("A", "A/D", "B", "B/D", "C", "C/D", "D"))))

### plotting
plot(brick.hsg[[1:3]], 
     main = c("ksat (um/sec)", "Depth to Restrictive Layer (cm)", "Depth to Water Table (cm)"),
     nr = 1, nc = 3, cex.main = 2, cex.axis = 1.5)

## broken by package update, supposed to do categorical plots
# rasterVis::levelplot(out.hsg, main = "Hydrologic Soil Group", col.regions = rev(terrain.colors(7)))

plot(out.hsg)

## 2.2 SVI #####
# this into a new function, hsg to primary hsg
df.hsg$shorthsg <- sapply(df.hsg$hsg,
                          function(h){
                            strsplit(h, 
                                     "/")[[1]][1]
                          })
brick.svi$shorthsg <- 
  brick.svi$slope %>%
  setValues(factor(df.hsg$shorthsg,
                   levels = rev(c("A", "B", "C", "D"))))

df.svi <- as.data.frame(brick.svi)
colnames(df.svi)[3] <- "shorthsg"

## run function
t1 <- Sys.time()
df.svi$svi <- svi_calc(df.svi)
timeSVI <- Sys.time() - t1
beepr::beep()

# factoring, this into svi calc
out.svi <-   
  brick.svi$slope %>%
  setValues(factor(df.svi$svi,
                   levels = c("1 - Low", "2 - Moderate", "3 - Moderately High", "4 - High")))

# broken categorical plots
# rasterVis::levelplot(out.svi, main = "Soil Vulnerability Index", col.regions = (terrain.colors(4)))

plot(brick.svi[[1:3]],
     main = c("Kw Factor", "Slope (%)", "Primary HSG"),
     nr = 1, nc = 3, cex.main = 2, cex.axis = 1.5)

plot(out.svi)

## 2.3 DWB ####
out.dwb <- dwb_calc(brick.dwb) %>% mask(sf.studyarea)

# factoring. this into dwb_calc
r <- ratify(out.dwb$dwb)
rat <- levels(r)[[1]]
rat$dwb <- c("Not limited", "Somewhat limited", "Very limited")
levels(r) <- rat
out.dwb$dwb <- r

## plotting
plot(brick.dwb %>% dropLayer(c(11,14,16)),
     # 11: Noncemented. 14: pftex. 16: restricthardness
     main = c(
       "Dep to Bedrock (Hard, cm)",
       "Dep to Bedrock (Soft, cm)",
       "Dep to Cement (Thick, cm)",
       "Dep to Cement (Thin, cm)",
       "NASIS Drainage Class",
       "Flooding (T/F)",
       "Rock Fragment (%)",
       "Subsidence (Gypsum, cm)",
       "Impacted Layer (T/F)",
       "LEP (%)",
       #"Noncemented Restriction (T/F)",
       "Humus Bottom Layer (T/F)",
       "Dep to Permafrost (cm)",
       #"Permafrost Textures (T/F)",
       "Ponding (T/F)",
       "Slope (%)",
       "Subsidence (Total, cm)",
       "Reconstructed Soil (T/F)",
       "Dep to Water Table (cm)"
     ),
     maxnl = 20)

plot(out.dwb$dwb)

## 2.4 VF ####
out.vf <- vf_calc(brick.vf) %>% mask(sf.studyarea)

## this into vf_calc
r2 <- ratify(out.vf$vf)
rat2 <- levels(r2)[[1]]
rat2$vf <- c("Not suitable", "Somewhat suitable", "Moderately suitable", "Suitable")
levels(r2) <- rat2

out.vf$vf <- r2

## plotting
plot(brick.vf,
     main = c(
       "Mean Annual Air Temp (°C)",
       "Albedo",
       "Aspect (°)",
       "Electr. Conductivity (mmhos/cm)",
       "Number of Months Flooded",
       "Gypsum Content (%)",
       "Mean Annual Precipitation (mm)",
       "Organic Matter (kg/m2)",
       "pH",
       "Na Adsorption Ratio",
       "Number of Months Saturated",
       "Slope (%)",
       "NASIS Water Gathering Surface",
       "Water Retention Difference (%)",
       "Xeric Biological Climate (T/F)"
     ))


plot(out.vf)

### 3 Save data ####
if(!dir.exists("Output")) dir.create("Output")
if(!dir.exists(paste0("Output/", projectcode))) dir.create(paste0("Output/", projectcode))

writeRaster(out.hsg,
            paste0("Output/", projectcode,"/", projectcode, "_hsg.tif"))
writeRaster(out.svi,
            paste0("Output/", projectcode,"/", projectcode, "_svi.tif"))

writeRaster(out.dwb$maxfuzz,
            paste0("Output/", projectcode,"/", projectcode, "_dwbRating.tif"))
writeRaster(out.vf$fuzzvf,
            paste0("Output/", projectcode,"/", projectcode, "_vfRating.tif"))

### factoring is currently outside of the functions, because saving these doesn't work:
# writeRaster(out.dwb$dwb,
#             paste0("Output/", projectcode,"/", projectcode, "_dwbClass.tif"))
# writeRaster(out.vf$vf,
#             paste0("Output/", projectcode,"/", projectcode, "_vfClass.tif"))

## yet saving these does, even though the last step is to take these rasters and send them to the layers used in the broken code
writeRaster(r, 
            paste0("Output/", projectcode,"/", projectcode, "_dwbClass.tif"))
writeRaster(r2,
            paste0("Output/", projectcode,"/", projectcode, "_vfClass.tif"))


