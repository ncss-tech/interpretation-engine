library(InterpretationEngine)

r <- initRuleset("Soil Mass Movement Risk")

my_data <- expand.grid(
  `SLOPE` = seq(0, 100, 5),
  `KSAT DIFFERENTIAL DEPTH` = seq(0, 200, 10),
  `DEPTH TO FIRST RESTRICTIVE LAYER, NONE IS NULL` = 85,
  `DEPTH OF ISOTROPIC SOIL` = 50,
  `TWO-DIMENSIONAL SURFACE MORPHOMETRY` = "backslope", 
    #c("toeslope", "footslope", "backslope", "shoulder", "summit"),
  `SLOPE SHAPE ACROSS` = 1, #
  `CLAY IN DIFFERENTIAL ZONE` = 15,
  `LEP IN DIFFERENTIAL ZONE` = 1,
  `LIQUID LIMIT IN DIFFERENTIAL ZONE` = 1,
  `WET SOIL MONTHS - COUNT` = seq(1, 12, 3),
  `CLAY CONTENT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 15,
  `LEP OF LAST LAYER OR AT RESTRICTIVE LAYER` = 0.7,
  `LIQUID LIMIT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 20
)
colnames(my_data) <- make.names(colnames(my_data))

evalNodes <- function(x, evaldata) {
  # message(x$name)
  if (x$isRoot) {
    x$rating <- x$children[[1]]$rating
  } else if (!is.null(x$propname)) {
    # print(x$propname)
    x$data <- evaldata[[make.names(x$propname)]]
    x$rating <- x$evalFunction(x$data)
  } else if (!is.null(x$rule_refid)) {
    # print(x$rule_refid)
    x$rating <- sapply(x$children, function(y) y$rating)
  } else if (!is.null(x$Type)) {
    # print(x$Type)
    x$rating <- x$evalFunction(sapply(x$children, function(y) y$rating))
  }
  # x$not_rated <- x$rating == "Not rated"
  x$rating <- as.numeric(x$rating)
  # print(paste0(unique(x$rating), collapse = ", "))
}

# debug(evalNodes)
tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data))
nrow(my_data) / tt[3]

# data.tree::ToDataFrameTree(r, "Type", "not_rated", "rating") |> View()

rgl::plot3d(
  my_data$SLOPE,
  my_data$KSAT.DIFFERENTIAL.DEPTH,
  r$rating,
  xlab = "Slope (%)",
  ylab = "Ksat Differential Depth (cm)",
  zlab = "Soil Mass Movement Risk Rating [0-1]",
  col = hcl.colors(12)[my_data$WET.SOIL.MONTHS...COUNT]
)

r <- initRuleset("Soil Mass Movement Risk")

# p <- getPropertySet(r)
# p2 <- unique(p[,c("propiid","propname")])

comp <- openxlsx::read.xlsx("D:/DebrisFlow/CA_soil_mass_movement_interp_3_2023/CA_all_soiil_mass_movement_interp_3_2023.xlsx")
mu <- sf::st_read('D:/DebrisFlow/mosquito.gpkg')
comp2 <- subset(comp, mukey %in% mu$mukey)

# prop <- do.call('rbind', lapply(comp2$coiid, lookupProperties, unique(p$propiid)))
# prop2 <- merge(p2, prop, by = "propiid")
# View(prop2)            
# openxlsx::write.xlsx(prop2, "D:/DebrisFlow/mosquito_SMMR_properties.xlsx")

prop <- openxlsx::read.xlsx("D:/DebrisFlow/mosquito_SMMR_properties.xlsx", 1)
prop$propcolname <- make.names(prop$propname)
prop <- merge(prop, comp2[, c("coiid", "Mass_movement_rt",
                              "loading_factors_sr",
                              "slope_factors_sr",
                              "strength_factors_sr")], by = "coiid",
              all.x = TRUE, all.y = TRUE)
prop$Mass_movement_rt[is.na(prop$Mass_movement_rt)] <- "Not rated"
prop_wide <- reshape(subset(unique(prop), select = c("coiid",
                                                     "comp_name",
                                                     "comp_pct",
                                                     "Mass_movement_rt",
                                                     "loading_factors_sr",
                                                     "slope_factors_sr",
                                                     "strength_factors_sr",
                                                     "rv",
                                                     "propcolname")),
                     direction = "wide", 
                     timevar = "propcolname", 
                     v.names = "rv", 
                     idvar = c("coiid", "comp_name", "comp_pct", "Mass_movement_rt"))
colnames(prop_wide) <- gsub("^rv\\.", "", colnames(prop_wide))
# View(prop_wide[complete.cases(prop_wide),])

prop_wide$Mass_movement_rt[prop_wide$Mass_movement_rt == "Not rated"] <- NA

my_data <- type.convert(prop_wide, as.is = TRUE)

## checking specific instances
# my_data <- subset(my_data, coiid %in% c(642414, 628222))

tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data))
nrow(my_data) / tt[3]
my_data$rating <- r$rating

# ToDataFrameTree(r, "name", "Type", "Value", "rating") |> View()
# my_data[c(1:4, grep("_sr$", colnames(my_data)))] |> View()

f <- Mass_movement_rt ~ rating
plot(f,
     data = my_data,
     xlim = c(0, 1),
     ylim = c(0, 1))
abline(0, 1)

## these have missing RV/multiple values for slope 2D position
my_data2 <- subset(my_data, abs(Mass_movement_rt - rating) > 0.04)
tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data2))
# data.tree::ToDataFrameTree(r, "name", "Type", "Value", "rating") |> View()
# my_data2[c(1:4, grep("_sr$", colnames(my_data)))] |> View()

## these are supposed to be not rated
my_data3 <- subset(my_data, is.na(Mass_movement_rt))
tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data3))
# data.tree::ToDataFrameTree(r, "name", "Type", "Value", "rating") |> View()
# my_data3[c(1:4, grep("_sr$", colnames(my_data)))] |> View()
# comp2 <- merge(my_data, comp2, all.x = TRUE)
# View(comp2)

## web report returns different RV than NASIS interp uses
# fixres <- lookupProperties(unique(comp2$coiid), 13658)

# NASIS uses "backslope"
my_data2$TWO.DIMENSIONAL.SURFACE.MORPHOMETRY <- "backslope"

# rerun, and they plot on 1:1 line
tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data2))
my_data2$rating <- r$rating
plot(f,
     data = my_data2,
     xlim = c(0, 1),
     ylim = c(0, 1))
abline(0, 1)
my_data_fix <- my_data2
my_data$TWO.DIMENSIONAL.SURFACE.MORPHOMETRY[my_data$coiid %in% my_data_fix$coiid] <- "backslope"
tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data))
my_data$rating <- r$rating

plot(f,
     data = my_data,
     xlim = c(0, 1),
     ylim = c(0, 1))
abline(0, 1)
m <- lm(f, data = my_data)
abline(m, col = "RED")
m1 <-  summary(m)
mtext(paste0("R squared: ", round(m1$r.squared,2), "\n",
             paste0("P-value: ", format.pval(pf(m1$fstatistic[1], # F-statistic
                                                m1$fstatistic[2], # df
                                                m1$fstatistic[3], # df
                                                lower.tail = FALSE)))), adj = 0)
mtext(paste0("RMSE: ", signif(sqrt(mean(m1$residuals^2)), 3)),
      adj = 0.5)
mtext(paste0("NASIS_rating ~ ",round(m1$coefficients[1], 2)," + ", 
             round(m1$coefficients[2],2), "R_rating"),
      adj = 1)

# rgl::plot3d(
#   my_data$SLOPE,
#   my_data$DEPTH.TO.FIRST.RESTRICTIVE.LAYER..NONE.IS.NULL,
#   r$rating,
#   xlab = "Slope (%)",
#   ylab = "Ksat Differential Depth (cm)",
#   zlab = "Soil Mass Movement Risk Rating [0-1]"#,
#   #col = hcl.colors(12)[my_data$WET.SOIL.MONTHS...COUNT]
# )

plot(density(r$rating, from = 0, to = 1, na.rm = TRUE))
max(r$rating)

library(terra)
ssurgo <- vect("D:/DebrisFlow/mosquito.gpkg")
ssurgo_b <- aggregate(ssurgo)
ssurgo_r <- soilDB::mukey.wcs(ssurgo_b, db = "gSSURGO")
ssurgo_b <- project(ssurgo_b, ssurgo_r)
ssurgo_r <- mask(ssurgo_r, ssurgo_b)
plot(ssurgo_r)
plot(ssurgo_b, add = T)

comp3 <- merge(data.table::data.table(comp2), my_data, all.x = TRUE)
muagg <- comp3[, .SD[which.max(comp_pct)[1], ], by = "mukey"]
ssurgo_rc <- ssurgo_r
levels(ssurgo_rc) <- cbind(data.frame(ID = as.numeric(muagg$mukey)), muagg)
ssurgo_rc <- catalyze(ssurgo_rc)
ssurgo_rc_wgs84 <- project(ssurgo_rc, "EPSG:4326")

plot(ssurgo_rc_wgs84$Mass_movement_rt, 
     col = hcl.colors(20), 
     range = c(0, 0.8))
plot(ssurgo_rc_wgs84$rating_new, 
     col = hcl.colors(20), 
     range = c(0, 0.8))

plot(ssurgo_rc_wgs84$SLOPE, 
     col = hcl.colors(20), 
     range = c(0, 100))
plot(ssurgo_rc_wgs84$TWO.DIMENSIONAL.SURFACE.MORPHOMETRY, 
     col = hcl.colors(20))
cnm <- c("SLOPE", "DEPTH.OF.ISOTROPIC.SOIL", "LIQUID.LIMIT.OF.LAST.LAYER.OR.AT.RESTRICTIVE.LAYER", 
  "CLAY.IN.DIFFERENTIAL.ZONE", "LEP.OF.LAST.LAYER.OR.AT.RESTRICTIVE.LAYER", 
  "LIQUID.LIMIT.IN.DIFFERENTIAL.ZONE", "DEPTH.TO.FIRST.RESTRICTIVE.LAYER..NONE.IS.NULL", 
  "LEP.IN.DIFFERENTIAL.ZONE", "KSAT.DIFFERENTIAL.DEPTH", "CLAY.CONTENT.OF.LAST.LAYER.OR.AT.RESTRICTIVE.LAYER", 
  "WET.SOIL.MONTHS...COUNT", "SLOPE.SHAPE.ACROSS", "TWO.DIMENSIONAL.SURFACE.MORPHOMETRY")
plot(ssurgo_rc[[cnm]], col = hcl.colors(10))

# dem <- elevatr::get_elev_raster(sf::st_as_sf(ssurgo_b), z = 14, expand = 0.01)
# dem <- writeRaster(rast(dem), "D:/DebrisFlow/mosquito.tif")
dem <- rast("D:/DebrisFlow/mosquito.tif")
# slope <- tan(terra::terrain(terra::rast(dem), 'slope', unit = "radians"))*100
# slope <- writeRaster(slope, "D:/DebrisFlow/mosquito_slope.tif")
slope <- rast("D:/DebrisFlow/mosquito_slope.tif")
# whitebox::wbt_relative_topographic_position("D:/DebrisFlow/mosquito.tif",
#                                             "D:/DebrisFlow/mosquito_rtp.tif",
#                                             filterx = 100,
#                                             filtery = 100)
rtp <- rast("D:/DebrisFlow/mosquito_rtp.tif")

# plot(density(spatSample(rtp, 1000, na.rm= TRUE)[[1]]))

test <- c(ssurgo_rc$SLOPE, 
          project(mask(slope, ssurgo_b), ssurgo_rc),
          project(mask(rtp, ssurgo_b), ssurgo_rc))
test_wgs84 <- project(test, "EPSG:4326")

plot(test_wgs84$slope, 
     col = hcl.colors(20), 
     range = c(0, 100))
plot(test_wgs84$mosquito_rtp, 
     col = hcl.colors(5))
# plot(test[[1:2]], range = c(0,100), col = hcl.colors(10))
# plet(rtp, alpha=0.5, tiles="OpenTopoMap")

## perform kmeans clustering on relative topo position
set.seed(123)
rtpk <- k_means(test[[3]], centers = 5)

## determine labels for kmeans clusters manually
## note that class order depends on seed
plet(rtpk, alpha=0.5, tiles="OpenTopoMap")

plot(project(rtpk, "EPSG:4326"), 
     col = hcl.colors(5))

luth <- c("backslope", # 1
          "toeslope",  # 2
          "footslope", # 3 
          "summit",    # 4
          "shoulder")  # 5

## inspect 
levels(rtpk) <- data.frame(ID = 1:5, 
                           TWO.DIMENSIONAL.SURFACE.MORPHOMETRY = luth[1:5])
plot(rtpk)

# convert raster to data.frame
my_data2 <- as.data.frame(ssurgo_rc[[colnames(my_data)]], na.rm = FALSE)

# splice in spatially varying attributes
my_data2$SLOPE <- round(values(test[[2]])[, 1])
my_data2$TWO.DIMENSIONAL.SURFACE.MORPHOMETRY <- luth[values(rtpk)[, 1]]

slpl <- values(ssurgo_rc$slope_l)
slpr <- values(ssurgo_rc$slope_r)
slph <- values(ssurgo_rc$slope_h)
slp <- c(slpl, slpr, slph)

# inspect continuous vs old slope range
plot(density(my_data2$SLOPE, na.rm = T, from = 0, to = 150,
             bw = 10, kernel = "rectangular"), 
     ylim = c(0, 0.04), xlab = "Slope Gradient (%)")
lines(density(slp, na.rm = T, from = 0, to = 150,
              bw = 10, kernel = "rectangular"), 
      lty = 2, col = "BLACK")
# lines(density(slpl, na.rm = T, from = 0, to = 150,
#               bw = 10, kernel = "rectangular"),
#       lty = 5, col = "BLUE")
lines(density(slpr, na.rm = T, from = 0, to = 150,
              bw = 10, kernel = "rectangular"),
      lty = 1, lwd = 2, col = "GREEN")
# lines(density(slph, na.rm = T, from = 0, to = 150,
#               bw = 10, kernel = "rectangular"),
#       lty = 5, col = "PURPLE")
# abline(v=c(15,30,50,60,75,100))

legend(
  "topright",
  lty = 1:4,
  col = c("BLACK", "BLUE", "GREEN", "PURPLE"),
  legend = c(
    paste0("Raster ", "(n=", nrow(my_data2[!is.na(my_data2$SLOPE), ]), ")"),
    paste0("Component Low ", "(n=", sum(!is.na(slpl)), ")"),
    paste0("Component RV ", "(n=", sum(!is.na(slpr)), ")"),
    paste0("Component High ", "(n=", sum(!is.na(slph)), ")")
  )
)

# inspect distribution of slope position
table(my_data2$TWO.DIMENSIONAL.SURFACE.MORPHOMETRY, useNA = "ifany")

# my_data2 <- head(my_data2[!is.na(my_data2$coiid), ])
my_data <- my_data2[!is.na(my_data2$SLOPE),]

# profvis::profvis(
  tt <- system.time(r$Do(traversal = "post-order", evalNodes, my_data))
# )

# tt
# nrow(my_data) / tt[3]

# data.tree::ToDataFrameTree(r, "name", "Type", "Value", "rating") |> View()
# my_data2[c(1:4, grep("_sr$", colnames(my_data)))] |> View()

my_data2$rating_new <- NA
my_data2$rating_new[!is.na(my_data2$SLOPE)] <- r$rating
ssurgo_rc$rating_new <- my_data2$rating_new

plot(ssurgo_rc[[c("rating", "rating_new")]],
     col = hcl.colors(20),
     range = c(0,1))
plot((ssurgo_rc[["rating"]] - ssurgo_rc[["rating_new"]]),
     col = rev(hcl.colors(20, palette = "Zissou 1")))
plot(project(ssurgo, ssurgo_rc), add = TRUE)
plet(ssurgo)
writeRaster(ssurgo_rc$rating_new, overwrite = TRUE,
            "D:/DebrisFlow/mosquito_continuous_rating.tif")
