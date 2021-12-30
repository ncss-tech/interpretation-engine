# prepare raster input data for InterpretationEngine HSG and SVI 
#    the SSURGO polygon that intersects this point will be returned, the bounding box calculated,
#   and potentially buffered. this is then used to query the SoilWeb MUKEY web coverage service

# save data for small (~11kB) self contained demo
# projectcode <- "Yolo1" # area of irrigated cropland in Yolo County near UC Davis
# latitude <- 38.5262
# longitude <- -121.785 # make buffer around extent (in geographic decimal degrees)
# geo_buf <- 0.01

# slightly larger and more variable, near the Dunnigan Hills
projectcode <- "Dunn1"
latitude <- 38.7941
longitude <- -121.955
geo_buf <- 0.01

# projectcode <- "Messick"
# latitude <- 37.5
# longitude <- -119.93
# geo_buf <- 0.01

# STEPS
#  - use soilDB to query SDA geometry extent near a target point
#  - get mapunit, component, horizon, muaggatt tables
#  - get mapunit key web coverage service raster
#  - ratify raster with various properties 1:1 with mukey
#  - deratify inputs to functions `hsg_calc` and `svi_calc`
#  - plot maps of results and comparisons to SSURGO


# packages
library(soilDB)  # SDA
library(elevatr) # DEM
library(sf)  
library(raster)
library(data.table) # Example "flattening" of custom attributes from SSURGO data
library(InterpretationEngine) # RASTER interpretation engine by @dylanbeaudette and @josephbrehm

# get the data

# get a single SSURGO polygon overlapping point, 
# and take a 0.01degree buffer around that polygon
poly_target <- st_buffer(st_as_sf(SDA_spatialQuery(as_Spatial(st_as_sf(
  data.frame(y = latitude, x = longitude), 
  coords = c("x","y"),
  crs = st_crs(4326)
)), 'mupolygon')), geo_buf)

# dem and slope map -- lower zoom level if needed/desiered
dem <- elevatr::get_elev_raster(poly_target, z = 14, expand = 0.01)
slope <- raster::terrain(dem, 'slope', unit = "tangent")*100

# get the raster MUKEY web coverage service result for the bbox of target
wcs_mukey <- mukey.wcs(aoi = poly_target)
MUKEY <- unique(wcs_mukey)

# # SOME EXAMPLE HOMEBREWED PROPERTIES FROM SSURGO/SDA
# #   1. calculate minimum ksat by cokey
# #   2. calculate surface horizon kw factor by cokey
# 
# query some tables from SDA
mu <- SDA_query(sprintf("SELECT * FROM mapunit WHERE mukey IN %s", format_SQL_in_statement(MUKEY)))
co <- SDA_query(sprintf("SELECT * FROM component WHERE mukey IN %s AND majcompflag = 'Yes' AND compkind != 'Miscellaneous area'", format_SQL_in_statement(MUKEY)))
ch <- SDA_query(sprintf("SELECT * FROM chorizon WHERE cokey IN %s", format_SQL_in_statement(co$cokey)))
maa <- SDA_query(sprintf("SELECT * FROM muaggatt WHERE mukey IN %s", format_SQL_in_statement(MUKEY)))
# 
# ## data.table approach
cokey_sda_derived <- data.table(ch)[, list(min_ksat = ksat_r[ksat_r == min(ksat_r, na.rm = TRUE)][1],
                                           surface_kw = kwfact[hzdept_r == min(hzdept_r, na.rm = TRUE)][1]),
                                    by = cokey]

# table of dominant cokey per mukey joined to SSURGO attributes of interest
co <- data.table(co)
dominant_components <- co[, list(comppct_max = max(comppct_r, na.rm=T), # calculate dominant component
                                 cokey = cokey[which.max(comppct_r)[1]]),
                          by = mukey][maa, on = "mukey"][cokey_sda_derived, on = "cokey"]
dominant_components <- subset(dominant_components, !is.na(mukey))
                          #           ^^^                      ^^^ join to other tables merge into raster attribute table
levels(wcs_mukey) <- merge(levels(wcs_mukey)[[1]],
                           dominant_components,
                           by.x = "ID",
                           by.y = "mukey",
                           all.x = TRUE)

# derived from a not-yet-live NASIS SSURGO export
# source("../soilDB/misc/NASIS-ssurgo-export-tools/ssurgo-export.R")
# co <- .get_SSURGO_export_interp_reasons_by_mrulename("E:/workspace/Cochran_InterpCompare/SWR template/SWR template.mdb", 
#                                                      "FOR - Mechanical Site Preparation (Surface)")
# 
# dominant_components <- data.table::as.data.table(co)[, list(comppct_max = max(comppct_r), # calculate dominant component
#                                  coiid = coiid[which.max(comppct_r)[1]]),
#                           by = mukey]
# co_sub <- subset(co, coiid %in% dominant_components$coiid)
# coiid_nasis_derived <- dominant_components[co_sub, on = "coiid"]
#                           #           ^^^                      ^^^ join to other tables
#                                   
# 
# #                           #           ^^^                      ^^^ join to other tables
# # merge into raster attribute table
# levels(wcs_mukey) <- merge(levels(wcs_mukey)[[1]],
#                            coiid_nasis_derived,
#                            by.x = "ID",
#                            by.y = "i.mukey",
#                            all.x = TRUE)
# 
# ras_siteprep_surface <- deratify(wcs_mukey, "interphr")
# names(ras_siteprep_surface) <- "siteprep_surface_hr"
# writeRaster(ras_siteprep_surface, filename = "sitepreptestraster.tif")

# inspect ratified raster
# plot(wcs_mukey, "min_ksat")
# plot(wcs_mukey, "surface_kw")
# plot(wcs_mukey, "wtdepannmin")

# deratify individual raster layers (TODO: vectorize)
ras_muaggatt_hsg <- deratify(wcs_mukey, "hydgrpdcd")
names(ras_muaggatt_hsg) <- "hsg_SSURGO"

ras_min_ksat <- deratify(wcs_mukey, "min_ksat")
names(ras_min_ksat) <- "ksat"

ras_surface_kw <- deratify(wcs_mukey, "surface_kw")
names(ras_surface_kw) <- "kwfact"

ras_brockdepmin <- deratify(wcs_mukey, "brockdepmin")
names(ras_brockdepmin) <- "rl"

ras_wtdepannmin <- deratify(wcs_mukey, "wtdepannmin")
names(ras_wtdepannmin) <- "wt"

# prepare detailed slope map
slope_prj <- projectRaster(slope, ras_min_ksat)
slope_crp <- crop(slope_prj, ras_min_ksat)

# write to test files for each interp kind using specified project code
if(!dir.exists(sprintf("inst/extdata/Input/SVI/%s", projectcode))) 
  dir.create(sprintf("inst/extdata/Input/SVI/%s", projectcode), recursive = TRUE)

writeRaster(slope_crp, sprintf("inst/extdata/Input/SVI/%s/%s_slope.tif", projectcode, projectcode), overwrite=TRUE)
writeRaster(ras_surface_kw, sprintf("inst/extdata/Input/SVI/%s/%s_kwfact.tif", projectcode, projectcode), overwrite=TRUE)

if(!dir.exists(sprintf("inst/extdata/Input/HSG/%s", projectcode))) 
  dir.create(sprintf("inst/extdata/Input/HSG/%s", projectcode), recursive = TRUE)

writeRaster(ras_min_ksat, sprintf("inst/extdata/Input/HSG/%s/%s_ksat.tif", projectcode, projectcode), overwrite=TRUE)
writeRaster(ras_brockdepmin, sprintf("inst/extdata/Input/HSG/%s/%s_rl.tif", projectcode, projectcode), overwrite=TRUE)
writeRaster(ras_wtdepannmin, sprintf("inst/extdata/Input/HSG/%s/%s_wt.tif", projectcode, projectcode), overwrite=TRUE)

# prepare HSG brick
paths.ml1.hsg <- list.files(sprintf("inst/extdata/Input/HSG/%s", projectcode),"tif$", full.names = TRUE)
brick.ml1.hsg <- brick(sapply(paths.ml1.hsg, raster))
names(brick.ml1.hsg) <- gsub(".*_(.*)\\.tif", "\\1", paths.ml1.hsg)

# prepare SVI brick
paths.ml1.svi <- list.files(sprintf("inst/extdata/Input/SVI/%s", projectcode),"tif$", full.names = TRUE)
brick.ml1.svi <- brick(sapply(paths.ml1.svi, raster))
names(brick.ml1.svi) <- gsub(".*_(.*)\\.tif", "\\1", paths.ml1.svi)

df.hsg <- as.data.frame(brick.ml1.hsg)

# NA water table goes to 201cm
df.hsg$wt[is.na(df.hsg$wt)] <- 201

# run hsg_calc
df.hsg$hsg <- hsg_calc(df.hsg, ncores = "auto")

out.hsg <- brick.ml1.hsg$wt %>%
  setValues(factor(df.hsg$hsg, levels = rev(c(
    "A", "A/D", "B", "B/D", "C", "C/D", "D"
  ))))

# make a comparison data frame based on SSURGO muaggatt table (mapunit aggregate attribute)
df.hsg.cmp <- as.data.frame(ras_muaggatt_hsg)
df.hsg$hsgcmp <- df.hsg.cmp$hydgrpdcd
df.hsg$cokey <- values(deratify(wcs_mukey, "cokey"))

# add custom factor levels
cmp.hsg <- ras_muaggatt_hsg %>%
  setValues(factor(df.hsg.cmp$hydgrpdcd, levels = rev(c(
    "A", "A/D", "B", "B/D", "C", "C/D", "D"
  ))))

plot(brick.ml1.hsg)

# compare muaggatt with dominant component passed thru InterpretationEngine
rasterVis::levelplot(cmp.hsg,
                     main = "Hydrologic Soil Group\n(muaggatt)",
                     col.regions = heat.colors(7))
rasterVis::levelplot(out.hsg,
                     main = "Hydrologic Soil Group\n(Dominant Component; InterpretationEngine)",
                     col.regions = heat.colors(7))

# compare breakdown of A, B, C, D
table(df.hsg$hsg)
table(df.hsg.cmp$hydgrpdcd)

if (!dir.exists(sprintf("inst/extdata/Output/HSG/%s", projectcode)))
  dir.create(sprintf("inst/extdata/Output/HSG/%s", projectcode), recursive = TRUE)
             
writeRaster(out.hsg, filename = sprintf("inst/extdata/Output/HSG/%s/%s_HSG.tif",
                                        projectcode, projectcode))         

# prepare data.frame and short hsg code for SVI
df.svi <- as.data.frame(brick.ml1.svi)
df.svi$shorthsg <- gsub("(.*)/?.*", "\\1", df.hsg$hsg)
df.svi$slope[is.na(df.svi$slope)] <- runif(sum(is.na(df.svi$slope)),1E-4,1E-3)

# run svi_calc
df.svi$svi <- svi_calc(df.svi, ncores = "auto")

# add custom factor levels
out.svi <- brick.ml1.svi$slope %>%
  setValues(factor(
    df.svi$svi,
    levels = c("1 - Low", "2 - Moderate", "3 - Moderately High", "4 - High")
  ))

plot(brick.ml1.svi)

rasterVis::levelplot(out.svi,
                     main = "Soil Vulnerability Index\n(Cultivated Cropland)",
                     col.regions = rev(heat.colors(4)))

if (!dir.exists(sprintf("inst/extdata/Output/SVI/%s", projectcode)))
  dir.create(sprintf("inst/extdata/Output/SVI/%s", projectcode), recursive = TRUE)
             
writeRaster(out.svi, filename = sprintf("inst/extdata/Output/SVI/%s/%s_SVI.tif", 
                                        projectcode, projectcode), recursive = TRUE)
