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

bad <- subset(evals, is.na(propmin) & is.na(propmax))
bad2 <- do.call('rbind', lapply(split(bad, 1:nrow(bad)), function(x) InterpretationEngine:::extractCrispExpression(x$eval, asString = TRUE)))

View(data.frame(a=bad2))

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

# make a null_not_rated RuleHedge function
.NULL_NOT_RATED <- function(x) {
  x[is.na(x)] <- "Not rated"
  x
}

# this property only returns a compkind value for interpretable component kinds
.NULL_NOT_RATED(as.numeric(f.INTERPRETABLE_COMPONENT(component_property$rv)))
.NULL_NOT_RATED(as.numeric(dt$RuleOperator_369952a0$`Component Kind Misc. and CHIID is null`$children$RuleHedge_7314c2a3$children$`Component Kind Misc. (Null)`$Get('evalFunction', component_property$rv)))

node <- dt$RuleOperator_369952a0$children[[1]]
cp <- lookupProperties(coiids, na.omit(node$Get('propiid')))
cp$rv
foo <- dbQueryNASIS(NASIS(), "SELECT ruleiidref, ratingclassname, ratingclassupperboundary, ruleratingclassiid 
                       FROM ruleratingclass 
                       WHERE ruleiidref = 378")
node$children$`Slope <6% to >12%`$children$RuleHedge_c9d4901f$children$`Slope <6% to >12%`$Get('evalFunction', cp$rv)[,1] |> factor(levels = foo$ratingclassupperboundary, labels = foo$ratingclassname)
