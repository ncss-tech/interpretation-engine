library(InterpretationEngine)
r0 <- initRuleset("Similar Soil Grouping for APEX Modeling")
r <- r0#r0$children$RuleOperator_3886708d$children[[8]]
p <- getPropertySet(r)
p2 <- unique(p[,2:3])
coiid <- 667033:667036
prop <- lookupProperties(coiid, p2$propiid)
# my_data <- as.data.frame(lapply(seq(nrow(p2)), function(x) 25))# c(25, 50, 100)))
# my_data <- as.data.frame(as.list(prop$rv))
my_data <- reshape(
  prop,
  v.names = "rv",
  idvar = "coiid",
  timevar = "propiid",
  direction = "wide"
)
colnames(my_data) <- c("coiid", "comp_name", "comp_pct", make.names(p2$propname))

# handle missing values (TODO: this shouldnt be needed)
my_data$FRAGMENTS...250MM.ON.SURFACE <- ifelse(
  is.na(my_data$FRAGMENTS...250MM.ON.SURFACE),
  0,
  my_data$FRAGMENTS...250MM.ON.SURFACE
)

rsub <- r0$RuleOperator_3886708d$
  `Similar Soils Surface Rock Fragment Subrule`$
  RuleOperator_c5e1ae36$children[[1]]$RuleOperator_1257f912$`Surface Layer Fragment Modifier = "none" (is null)`
psub <- getPropertySet(rsub)
interpret(rsub, my_data[unique(make.names(psub$propname))])

# rt <- initRuleset("Similar Soil Grouping Flood Frequency Sub-rule")
interpret(r, my_data)
