library(soilDB)
library(RODBC)
library(XML)
library(plyr)
library(data.tree)
library(digest)


## TODO: finish evaluation parsing functions


# source local functions
source('local-functions.R')

# re-load cached data
# getAndCacheData()

# load cached data
load('cached-NASIS-data.Rda')

###
### evaluation curves
###

## arbitrary curve: example: Storie Index C factor 
idx <- grep('storie factor c', evals$evalname, ignore.case = TRUE)
res <- extractEvalCurve(evals[idx, ])
plot(0:200, res(0:200), type='l', xlab='domain', ylab='fuzzy rating', main=evals$evaluationtype[idx])

## sigmoid: "SAR, <.5, 0-100cm (0 to 40")"
idx <- grep('SAR, <.5, 0-100cm (0 to 40")', evals$evalname, fixed = TRUE)
res <- extractEvalCurve(evals[idx, ])
plot(0:13, res(0:13), type='l', xlab='domain', ylab='fuzzy rating', main=evals$evaluationtype[idx])

## arbitrary linear
idx <- grep("GRL - EC maximum in depth 25 to 50 cm (NV)", evals$evalname, fixed = TRUE)
res <- extractEvalCurve(evals[idx, ])
plot(0:25, res(0:25), type='l', xlab='domain', ylab='fuzzy rating', main=evals$evaluationtype[idx])

## crisp: "Soil pH (water) >= 4.5 and <= 8.4, 0-100cm"
idx <- grep('Soil pH (water) >= 4.5 and <= 8.4, 0-100cm', evals$evalname, fixed = TRUE)
res <- extractEvalCurve(evals[idx, ])
plot(0:14, res(0:14), type='l', xlab='domain', ylab='fuzzy rating', main=evals$evaluationtype[idx])


###
### Rules
###


# check a couple, RefId points to rows in rules table
# the dt$Do call links child sub-rules
# recursion is used to traverse to the deepest nodes, seems to work
# caution: don't run several times on the same object!


## example
# just some random rule
y <- rules[rules$rulename == 'Dust PM10 and PM2.5 Generation', ]
dt <- parseRule(y)
# print intermediate results
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid')
# recusively splice-in sub-rules
dt$Do(traversal='pre-order', fun=linkSubRules)
# splice-in evaluation functions, if possible
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType')


## more examples
y <- rules[rules$rulename == 'AGR - California Revised Storie Index (CA)', ]
dt <- parseRule(y)
dt$Do(traversal='pre-order', fun=linkSubRules)
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType')

y <- rules[rules$rulename == 'DHS - Catastrophic Mortality, Large Animal Disposal, Pit', ]
dt <- parseRule(y)
dt$Do(traversal='pre-order', fun=linkSubRules)
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType')


# this one has a single RuleEvaluation: RefId points to rows in evals table
y <- rules[rules$rulename == 'Clay %, in surface - MO2', ]
dt <- parseRule(y)
dt$Do(traversal='pre-order', fun=linkSubRules)
dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)
print(dt, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType')


# check total number of nodes within data.tree object
dt$totalCount
