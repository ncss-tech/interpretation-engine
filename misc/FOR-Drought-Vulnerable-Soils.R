# library(InterpretationEngine)
library(data.tree)
library(knitr)
library(furrr)


rules <- InterpretationEngine::NASIS_rules
evals <- InterpretationEngine::NASIS_evaluations

idx <- grep('drought', rules$rulename, ignore.case = TRUE)
rules$rulename[idx]




## manual init of rules / evals

y <- rules[rules$rulename == 'FOR - Drought Vulnerable Soils', ]

dt <- parseRule(y)

# print intermediate results
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', limit = NULL)

# recursively splice-in sub-rules
dt$Do(traversal = 'pre-order', fun = linkSubRules)


## TODO: remaining errors related to limits

# Evaluating CrispExpression (=1) has only experimental support
# Error in xy.coords(x, y, setLab = FALSE) : 'x' and 'y' lengths differ
# In addition: Warning message:
#   CVIRLinear xlim argument is ignored 
# Evaluating CrispExpression (>=2) has only experimental suppor

# splice-in evaluation functions, if possible
dt$Do(traversal = 'pre-order', fun = linkEvaluationFunctions)


# print more attributes
options(width = 300)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit = NULL)

print(dt, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit = NULL)


# https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html
# https://cran.r-project.org/web/packages/data.tree/vignettes/applications.html

SetNodeStyle(dt, fontsize=10, fontname = 'helvetica', shape='none')
SetGraphStyle(dt, rankdir='TD', inherit=TRUE)

dt$Do(function(x) SetNodeStyle(x, shape = 'box', inherit = FALSE), 
      filterFun = function(x) x$isLeaf)

plot(dt)

## TODO: getting to the evaluation function of each rule is hard work... need to traverse each eval to the baseline function for plugging in properties

ee <- dt$RuleHedge_ff2b84ac$RuleOperator_a5c67517$RuleOperator_d9db7cc2$RuleOperator_49ca0cdc$RuleOperator_a2a1ca3a$`Precipitation Deficit`$RuleHedge_6338d5cb$`Precipitation Minus Potential Evapotranspiration`

print(ee, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)

e <- evals[evals$evaliid == ee$Get('eval_refid'), ]

# plot using xlim as defined in the narrative of the evaluation
plotEvaluation(e)
points(20, ee$Get('evalFunction', 20), col='royalblue', pch=16, cex=2)


# get unique set of properties required for this interp
(ps <- getPropertySet(dt))

# init additional cores
# plan(multisession)

# this is a component ID (NASIS only)
# parallel requests to national NASIS server
props <- lookupProperties(unique(ps$propiid), coiid = '1842461')

# stop additional cores
plan(sequential)

# merge 
z <- merge(ps, props, by = 'propiid', all.x = TRUE, sort = FALSE)
kable(z)






