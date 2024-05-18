library(InterpretationEngine)

r <- initRuleset("Soil Mass Movement Risk")

my_data <- expand.grid(
  `SLOPE` = seq(0, 100, 0.1),
  `KSAT DIFFERENTIAL DEPTH` = seq(0, 200, 0.2),
  `DEPTH TO FIRST RESTRICTIVE LAYER, NONE IS NULL` = 85,
  `DEPTH OF ISOTROPIC SOIL` = 25,
  `TWO-DIMENSIONAL SURFACE MORPHOMETRY` = "backslope", 
  #c("toeslope", "footslope", "backslope", "shoulder", "summit"),
  `SLOPE SHAPE ACROSS` = 1, #
  `CLAY IN DIFFERENTIAL ZONE` = 15,
  `LEP IN DIFFERENTIAL ZONE` = 1,
  `LIQUID LIMIT IN DIFFERENTIAL ZONE` = 1,
  `WET SOIL MONTHS - COUNT` = 12, # seq(1, 12, 3),
  `CLAY CONTENT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 15,
  `LEP OF LAST LAYER OR AT RESTRICTIVE LAYER` = 0.7,
  `LIQUID LIMIT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 20
)

# prepare a raster arranged by slope and depth to contrasting Ksat
colnames(my_data) <- make.names(colnames(my_data))
my_data <- my_data[order(my_data$WET.SOIL.MONTHS...COUNT,
                         my_data$SLOPE,
                         my_data$KSAT.DIFFERENTIAL.DEPTH),]
library(terra)
x <- terra::rast(nrows = sqrt(nrow(my_data)),
                 ncols = sqrt(nrow(my_data)),
                 xmin = min(my_data[[1]]), ymin = min(my_data[[2]]),
                 xmax = max(my_data[[1]]), ymax = max(my_data[[2]]),
                 crs = "local")
for (i in colnames(my_data)) {
  x[[i]] <- my_data[[i]]
}

t1 <- system.time(res <- interpret(r, x))

# cells per second
ncell(res) / t1[3]

par(mar = c(5, 5, 5, 5))
plot(res, 
     col = hcl.colors(50),
     range = c(0,1),
     main = "",
     xlab = colnames(my_data)[1],
     ylab = colnames(my_data)[2])

