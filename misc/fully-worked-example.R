library(InterpretationEngine)

## manual init of rules / evals
rules <- InterpretationEngine::NASIS_rules
evals <- InterpretationEngine::NASIS_evaluations

y <- rules[rules$rulename == 'ENG - Dwellings With Basements', ]

y <- rules[rules$rulename == 'SVI - Main', ]

dt <- parseRule(y)

# print intermediate results
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', limit=NULL)

# recursively splice-in sub-rules
dt$Do(traversal='pre-order', fun=linkSubRules)

## TODO: is this working?
# splice-in evaluation functions, if possible
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)

# print more attributes
options(width=300)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=NULL)

print(dt, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)

# https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html
# https://cran.r-project.org/web/packages/data.tree/vignettes/applications.html

SetNodeStyle(dt, fontsize=10, fontname = 'helvetica', shape='none')
SetGraphStyle(dt, rankdir='TD', inherit=TRUE)

dt$Do(function(x) SetNodeStyle(x, shape = 'box', inherit = FALSE), 
      filterFun = function(x) x$isLeaf)

plot(dt$RuleOperator_c451bdee$`Depth to Hard Bedrock < 150cm (60") (revised)`)

## TODO: getting to the evaluation function of each rule is hard work... need to traverse each eval to the baseline function for plugging in properties

ee <- dt$RuleOperator_c451bdee$`Slope 8 to > 15%`$RuleHedge_f060a2d5$`Slopes <8 to >15%`
print(ee, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)

e <- evals[evals$evaliid == ee$eval_refid, ]
plotEvaluation(e, xlim = c(0,50))

points(20, ee$evalFunction(20), col='royalblue', pch=16, cex=2)

# get unique set of properties required for this interp
(ps <- getPropertySet(dt))

# init additional cores
plan(multisession)

# this is a component ID (NASIS only)
# parallel requests to national NASIS server
props <- lookupProperties(unique(ps$propiid), coiid='1842461')

# stop additional cores
plan(sequential)

# merge 
z <- merge(ps, props, by='propiid', all.x = TRUE, sort = FALSE)
kable(z)

# ... crumbs: there is no way to inject local "slope" into an upstream property



