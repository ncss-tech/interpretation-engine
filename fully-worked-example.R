library(soilDB)
library(RODBC)
library(XML)
library(plyr)
library(data.tree)
library(digest)
library(jsonlite)
library(sharpshootR)
library(knitr)

# source local functions
source('local-functions.R')

# re-load cached data
# getAndCacheData()

# load cached data
load('cached-NASIS-data.Rda')


y <- rules[rules$rulename == 'FOR - Potential Erosion Hazard (Off-Road/Off-Trail)(rev2)', ]

dt <- parseRule(y)

# print intermediate results
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', limit=25)

# recusively splice-in sub-rules
dt$Do(traversal='pre-order', fun=linkSubRules)
# splice-in evaluation functions, if possible
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)

# print more attributes
options(width=300)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=25)

print(dt, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=25)


(ps <- getPropertySet(dt))

props <- lookupProperties(unique(ps$propiid), coiid='1842387')

z <- join(ps, props, by='propiid', type='left')

kable(z)



# ... crumbs: there is no way to inject local "slope" into an upstream property



