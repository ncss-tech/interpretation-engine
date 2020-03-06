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


x <- initRuleset(rulename = 'Valley Fever')

# print more attributes
options(width=300)
print(x, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=NULL)

print(x, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)


(ps <- getPropertySet(x))

props <- lookupProperties(unique(ps$propiid), coiid='1842387')

z <- merge(ps, props, by='propiid', all.x=TRUE, sort=FALSE)

kable(z)
