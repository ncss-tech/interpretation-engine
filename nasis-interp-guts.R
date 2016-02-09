library(soilDB)
library(RODBC)
library(XML)
library(plyr)
library(data.tree)
library(igraph)

## TODO: add support for inverted results

# source local functions
source('local-functions.R')

# init connection
channel <- odbcDriverConnect(connection = "DSN=nasis_local;UID=NasisSqlRO;PWD=nasisRe@d0n1y")


###
### get evaluation curves, need to join in metadata to convert most columns from codes -> values
###

# get all evaluation curves
evals <- sqlQuery(channel, "SELECT evaliid, evalname, evaldesc, eval, et.ChoiceName as evaluationtype, invertevaluationresults
FROM evaluation_View_0 
LEFT OUTER JOIN (SELECT * FROM MetadataDomainDetail WHERE DomainID = 4884) AS et ON evaluationtype = et.ChoiceValue", stringsAsFactors=FALSE)

## arbitrary curve: example: Storie Index C factor 
idx <- grep('storie factor c', evals$evalname, ignore.case = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractArbitraryCurveEval(y$eval)
plot(0:200, res(0:200), type='l', xlab='domain', ylab='fuzzy rating', main='Arbitrary Curve')

## sigmoid: "SAR, <.5, 0-100cm (0 to 40")"
idx <- grep('SAR, <.5, 0-100cm (0 to 40")', evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractSigmoidCurveEval(y$eval)
plot(0:13, res(0:13), type='l', xlab='domain', ylab='fuzzy rating', main='Sigmoid Curve')

## arbitrary linear
idx <- grep("GRL - EC maximum in depth 25 to 50 cm (NV)", evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractArbitraryCurveEval(y$eval)
plot(0:25, res(0:25), type='l', xlab='domain', ylab='fuzzy rating', main='Arbitrary Linear Curve')

## crisp: "Soil pH (water) >= 4.5 and <= 8.4, 0-100cm"
idx <- grep('Soil pH (water) >= 4.5 and <= 8.4, 0-100cm', evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractCrispCurveEval(y$eval)
plot(0:14, res(0:14), type='l', xlab='domain', ylab='fuzzy rating', main='Crisp Curve')


###
### get rules
###

# get rules, note that "rule" is a reserved word, use [] to protect
rules <- sqlQuery(channel, "SELECT rulename, rd.ChoiceName as ruledesign, primaryinterp, notratedphrase, ruledbiidref, ruleiid, [rule]
FROM rule_View_0 
LEFT OUTER JOIN (SELECT * FROM MetadataDomainDetail WHERE DomainID = 2822) AS rd ON ruledesign = rd.ChoiceValue
WHERE dataafuse = 1", stringsAsFactors=FALSE)

# check a couple, RefId points to rows in rules table
y <- rules[rules$rulename == 'AGR - California Revised Storie Index (CA)', ]
dt <- parseRule(y)
print(dt, 'Type', 'Value', 'RefId')

y <- rules[rules$rulename == 'DHS - Catastrophic Mortality, Large Animal Disposal, Pit', ]
dt <- parseRule(y)
print(dt, 'Type', 'Value', 'RefId')

# get sub-rules
dt$Get('RefId')

# this one has a single RuleEvaluation: RefId points to rows in evals table
y <- rules[rules$rulename == 'Clay %, in surface - MO2', ]
dt <- parseRule(y)
print(dt, 'Type', 'Value', 'RefId')

# check evaluation: yes!
evals[evals$evaliid == '11393', ]
res <- extractCrispCurveEval(evals$eval[evals$evaliid == '11393'])
plot(0:60, res(0:60), type='l', xlab='domain', ylab='fuzzy rating', main='Crisp Curve')

## iterate over tree and splice-in via Do()
# next: splice sub-rules into data.tree object
y <- rules[rules$rulename == 'DHS - Catastrophic Mortality, Large Animal Disposal, Pit', ]
dt <- parseRule(y)
print(dt, 'Type', 'Value', 'RefId')

# works!
dt$Do(function(node) {
  # if this is a sub-rule
  if(grepl('RuleRule', node$name)) {
    # get sub-rule
    sr <- rules[rules$ruleiid == node$Get('RefId'), ]
    node$AddChildNode(parseRule(sr))
    return(node)
  }
})


### ... almost correct
print(dt, 'Type', 'Value', 'RefId')

# more ideas 
# https://cran.r-project.org/web/packages/data.tree/vignettes/applications.html


