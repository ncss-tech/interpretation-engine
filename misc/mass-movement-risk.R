library(InterpretationEngine)

r <- ruleByRulename("Soil Mass Movement Risk")

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
  `WET SOIL MONTHS - COUNT` = 1:12,
  `CLAY CONTENT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 15,
  `LEP OF LAST LAYER OR AT RESTRICTIVE LAYER` = 0.7,
  `LIQUID LIMIT OF LAST LAYER OR AT RESTRICTIVE LAYER` = 20
)
colnames(my_data) <- make.names(colnames(my_data))

evalNodes <- function(x) {
  # message(x$name)
  if (x$isRoot) {
    x$rating <- x$children[[1]]$rating
  } else if (!is.null(x$propname)) {
    # print(x$propname)
    x$data <- my_data[[make.names(x$propname)]]
    x$rating <- x$evalFunction(x$data)
  } else if (!is.null(x$rule_refid)) {
    # print(x$rule_refid)
    x$rating <- sapply(x$children, function(y) y$rating)
  } else if (!is.null(x$Type)) {
    # print(x$Type)
    x$rating <- x$evalFunction(sapply(x$children, function(y) y$rating))
  }
  # x$rating <- round(as.numeric(x$rating), 2)
  # print(paste0(unique(x$rating), collapse = ", "))
}

# debug(evalNodes)
tt <- system.time(dt$Do(traversal = "post-order", evalNodes))
nrow(my_data) / tt[3]

# print(dt, "rating")
# data.tree::ToDataFrameTree(dt, "Type", "rating") |> View()

rgl::plot3d(
  my_data$SLOPE,
  my_data$KSAT.DIFFERENTIAL.DEPTH,
  dt$rating,
  xlab = "Slope (%)",
  ylab = "Ksat Differential Depth (cm)",
  zlab = "Soil Mass Movement Risk Rating [0-1]",
  col = hcl.colors(12)[my_data$WET.SOIL.MONTHS...COUNT]
)
