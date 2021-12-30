library(InterpretationEngine)

# load cached data
load('cached-NASIS-data.Rda')

y <- rules[rules$rulename == 'FOR - Road Suitability (Natural Surface)', ]

dt <- parseRule(y)

# recusively splice-in sub-rules
dt$Do(traversal = 'pre-order', fun = linkSubRules)

# splice-in evaluation functions, if possible
dt$Do(traversal = 'pre-order', fun = linkEvaluationFunctions)

# # print more attributes
# options(width=300)
# print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=25)
# 
# print(dt, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=25)

# bad <- subset(evals, is.na(propmin) & is.na(propmax))
# bad2 <- do.call('rbind', lapply(split(bad, 1:nrow(bad)), function(x) {
#             InterpretationEngine:::extractCrispExpression(x$eval, asString = TRUE)
#           }))
# View(data.frame(a=bad2))

e <- evals[evals$evaliid == 12765,]
f.INTERPRETABLE_COMPONENT <- InterpretationEngine:::extractCrispExpression(e$eval, invert = e$invertevaluationresults)
coiids <- c("642626", "1498364", "1154650", "627824", "1693178", "1419756", 
            "666236", "666657", "720510", "1270409", "642168", "1693202", 
            "635415", "659217", "1451814", "1976422", "2714408", "666222", 
            "1434478", "642641", "642166", "2029004", "720642", "1498380", 
            "642172", "2669525", "666363", "1562817", "645899", "628609", 
            "641731", "641757", "696370", "1498357", "666570", "628644", 
            "642829", "666227", "938589", "666064", "1169541", "2292963", 
            "712188", "666183", "2775950", "642445", "643048", "665515", 
            "666188", "641728")
component_property <- lookupProperties(coiids, e$propiid)

dt$RuleOperator_369952a0$Get("Type")[1]

print(dt$RuleOperator_369952a0$`Component Kind Misc. and CHIID is null`, 
      'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=25)

# this property only returns a compkind value for interpretable component kinds
#  for interpretable components the expected value is "0" and non-interpretable "Not rated"
InterpretationEngine:::.NULL_NOT_RATED(f.INTERPRETABLE_COMPONENT(component_property$rv))
InterpretationEngine:::.NULL_NOT_RATED(dt$RuleOperator_369952a0$`Component Kind Misc. and CHIID is null`$children$RuleHedge_7314c2a3$children$`Component Kind Misc. (Null)`$Get('evalFunction', component_property$rv))

node <- dt$RuleOperator_369952a0$children[[1]]
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
cp$rv

rc <- InterpretationEngine:::lookupRatingClass(max(na.omit(node$Get('rule_refid'))))

node$children$`Slope <6% to >12%`$children$RuleHedge_c9d4901f$children$`Slope <6% to >12%`$Get('evalFunction', cp$rv)[,1] |> 
  factor(levels = rc$ratingclassupperboundary, labels = rc$ratingclassname)

node <- dt$RuleOperator_369952a0$children[[2]]
node |> print("Type")
pids <- na.omit(node$Get('propiid'))
cp <- lapply(pids, function(x) lookupProperties(coiids, x))
names(cp) <- pids
rids <- na.omit(node$Get('rule_refid'))
rc <- lapply(rids, function(x) InterpretationEngine:::lookupRatingClass(x))

node$children$RuleOperator_131c5cf9$`Fragments <15% to >50% Surface Cover (>=75 & <250mm)`$children$RuleHedge_991b51b6$children[[1]]$Get('evalFunction', cp[[3]]$rv)[,1] |> 
  factor(levels = rc[[3]]$ratingclassupperboundary, labels = rc[[3]]$ratingclassname)

node <- dt$RuleOperator_369952a0$children[[3]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Plasticity Index >=30 Thickest Layer in Depth 0-15cm, Rev`

node <- dt$RuleOperator_369952a0$children[[4]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Particles 0 to >85% Coarser vfs, >=7cm Thck, 0-15cm Dp, Rev`

node <- dt$RuleOperator_369952a0$children[[5]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node1 <- node$RuleOperator_43c9b640$children[[1]]
cp <- lookupProperties(coiids, na.omit(node1$Get('propiid')))
node1$`Unified (Inorganic) In Layer >=7cm Thick In Depth 0-15cm`$RuleHedge_6291e31f$`Unified (Inorganic) In Layer >=7cm Thick In Depth 0-15cm`$Get('evalFunction', cp$rv)
node2 <- node$RuleOperator_43c9b640$children[[2]]
cp <- lookupProperties(coiids, na.omit(node2$Get('propiid')))
node2$`Unified (Organic) In Layer >=7cm Thick In Depth 0-15cm`$Get('evalFunction', cp$rv)

node <- dt$RuleOperator_369952a0$children[[6]]
node |> print("Type")
node1 <- node$RuleOperator_951eaacf$children[[1]]
cp <- lookupProperties(coiids, na.omit(node1$Get('propiid')))
node1$Get('evalFunction', cp$rv)$`Months With Frequent Ponding`
node2 <- node$RuleOperator_951eaacf$children[[2]]
cp <- lookupProperties(coiids, na.omit(node2$Get('propiid')))
node2$Get('evalFunction', cp$rv)$`Months With Occasional Ponding`

node <- dt$RuleOperator_369952a0$children[[7]]
node |> print("Type")
node1 <- node$RuleOperator_088b4dbf$children[[1]]
cp <- lookupProperties(coiids, na.omit(node1$Get('propiid')))
node1$Get('evalFunction', cp$rv)$`Months With Frequent or Very Frequent Flooding`
node2 <- node$RuleOperator_088b4dbf$children[[2]]
cp <- lookupProperties(coiids, na.omit(node2$Get('propiid')))
node2$Get('evalFunction', cp$rv)$`Months With Occasional Flooding`

node <- dt$RuleOperator_369952a0$children[[8]]
node |> print("Type")
node1 <- node$RuleOperator_cde17137$children[[1]]
cp <- lookupProperties(coiids, na.omit(node1$Get('propiid')))
node1$Get('evalFunction', cp$rv)$`Soil Slippage Potential, Revised`
node2 <- node$RuleOperator_cde17137$children[[2]]
cp <- lookupProperties(coiids, na.omit(node2$Get('propiid')))
node2$Get('evalFunction', cp$rv)$`Soil Slippage Potential Slope Percent 5 to 25`

node <- dt$RuleOperator_369952a0$children[[9]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Depth to Water Table Average for Consecutive Months`

node <- dt$RuleOperator_369952a0$children[[10]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Component Kind Misc. (Null)`

node <- dt$RuleOperator_369952a0$children[[11]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Null Horizon Data`

node <- dt$RuleOperator_369952a0$children[[12]]
node |> print("Type")
node1 <- node$RuleHedge_de473ab5$RuleOperator_0a397761$children[[1]]
node2 <- node$RuleHedge_de473ab5$RuleOperator_0a397761$children[[2]]
node3 <- node2$children[[1]]
node4 <- node2$children[[2]]

# oh these property results are rounded off to integer values...
cp1 <- lookupProperties(coiids, na.omit(node1$Get('propiid')))

node1$Get('evalFunction', cp1$rv)
plotEvaluation(subset(evals, evalname == "Dryness Index 0.5 to 3"), xlim=c(0,3))
v <- extractEvalCurve(subset(evals, evalname == "Dryness Index 0.5 to 3"))
v(c(0.5, 0.75, 2.75, 3))
v(c(1.098901099)) # close to expected value of 0.115
#> [1] 0.1158786

cp3 <- lookupProperties(coiids, na.omit(node3$Get('propiid')))
node3$Get('evalFunction', cp3$rv)$`Dust from Gypsum Content 2 to 15 Percent`
plotEvaluation(subset(evals, evalname == "Dust from Gypsum Content 2 to 15 Percent"), xlim=c(0,20))

cp4 <- lookupProperties(coiids, na.omit(node4$Get('propiid')))
node4$Get('evalFunction', cp4$rv)$`Dust from Silt and Clay Content 20 to 70 Percent Sand`
plotEvaluation(subset(evals, evalname == "Dust from Silt and Clay Content 20 to 70 Percent Sand"), xlim=c(20,70))

node3$Get('evalFunction', cp3$rv)$`Dust from Gypsum Content 2 to 15 Percent` + node4$Get('evalFunction', cp4$rv)$`Dust from Silt and Clay Content 20 to 70 Percent Sand` * node1$Get('evalFunction', cp1$rv) * 0.5

node <- dt$RuleOperator_369952a0$children[[13]]
node |> print("Type")
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
node$Get('evalFunction', cp$rv)$`Drainage Class is Not Subaqueous`

