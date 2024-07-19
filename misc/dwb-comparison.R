library(terra)

projectcode <- "UTGrand250"

paths.dwb <- list.files(path = paste0("inst/extdata/Input/DWB/NASIS Property Rasters/", projectcode), pattern = "tif$", full.names = T)

# all output will be in this crs (5070 = albers AEA conus)
crs <- crs("EPSG:5070")

sf.studyarea <- vect("demo//Utah_County_Boundaries-shp", "Counties") |>
  subset(NAME == "GRAND", NSE = TRUE)

paths.dwb <- list.files(path = paste0("inst/extdata/Input/DWB/NASIS Property Rasters/", projectcode), pattern = "tif$", full.names = T)

rast.dwb <- rast(paths.dwb)
names.dwb <- basename(paths.dwb) |>  
  gsub(pattern = paste0(projectcode, "_"), replacement = "") |> 
  gsub(pattern = ".tif", replacement = "")
names(rast.dwb) <- names.dwb

df.dwb <- as.data.frame(rast.dwb)
t1 <- Sys.time()
df.dwb$dwb <- dwb_calc(df.dwb)
timeDWB <- Sys.time() - t1
timeDWB

r <- initRuleset("ENG - Dwellings With Basements")
newnames <- c(
  "DEPTH.TO.BEDROCK.HARD..BELOW.O.HORIZON",
  "DEPTH.TO.BEDROCK.SOFT..BELOW.O.HORIZON",
  "DEPTH.TO.CEMENTED.PAN.THICK..BELOW.O.HORIZON",
  "DEPTH.TO.CEMENTED.PAN.THIN..BELOW.O.HORIZON",
  "DRAINAGE.CLASS.IS.NOT.SUBAQUEOUS",
  "FLOODING.FREQUENCY..Maximum.Frequency.",
  "FRAGMENTS...75MM.WEIGHTED.AVE..IN.DEPTH.0.100CM",
  "SUBSIDENCE.DUE.TO.GYPSUM..REV",
  "COMPONENT.LOCAL.PHASE.IMPACTED",
  "LEP.WTD_AVG.25.150cm.OR.ABOVE.RESTRICTION..BELOW.O.HORIZON",
  "USDA.TEXTURE.MODIFIER",
  "UNIFIED.BOTTOM.LAYER",
  "DEPTH.TO.PERMAFROST",
  "USDA.TEXTURE..IN.LIEU.OF.",
  "PONDING.FREQUENCY",
  "RESTRICTIVE.FEATURE.HARDNESS",
  "SLOPE",
  "SUBSIDENCE.TOTAL",
  "COMPONENT.LOCAL.PHASE.UNSTABLE.FILL",
  "HIGH.WATER.TABLE.DEPTH.MINIMUM"
)
names(rast.dwb) <- newnames
rast.dwb$PONDING.DURATION <- rast.dwb$PONDING.FREQUENCY
df.dwb2 <- as.data.frame(rast.dwb)
profvis::profvis(res <- interpret(r, rast.dwb, cores = 8))
plot(res$rating ~ df.dwb$dwb$maxfuzz)
