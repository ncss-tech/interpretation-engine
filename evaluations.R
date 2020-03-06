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


# how many of each
knitr::kable(t(sort(prop.table(table(evals$evaluationtype)), decreasing = TRUE)), digits = 3)


# trapezoid
e <- evals[evals$evalname == 'American Optimum Average pH (1:1 H2O) 0-150 cm', ]
plotEvaluation(e)
plotEvaluation(e, xlim = c(3, 9))


# beta
# pretty sure this is defined by two values: "center" and "flex"
# ... hmm this isn't right
# dbeta(36:66, 50, 5)
e <- evals[evals$evalname == 'GRL-Elevation 1,840m (beta)', ]

# crisp based on threshold
e <- evals[evals$evalname == 'Soil pH (water) >= 4.5 and <= 8.4, 0-100cm', ]
plotEvaluation(e)

## TODO: figure this out
# crisp based on logical expression... extractCrispCurveEval() can't handle this
e <- evals[evals$evalname == 'GRL-Frost Action = moderate', ]
# plotEvaluation(e)
extractEvalCurve(e)
