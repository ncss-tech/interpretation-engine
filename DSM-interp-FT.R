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


## two required by DSM/Interps FT
# Valley fever
# Dwellings with basements


valley.fever <- initRuleset(rulename = 'Valley Fever')
basements <- initRuleset(rulename = 'ENG - Dwellings With Basements')

ps.valley.fever <- getPropertySet(valley.fever)
ps.basements <- getPropertySet(basements)


cat(unique(ps.valley.fever$propname), sep = '\n')
cat(unique(ps.basements$propname), sep = '\n')





props <- lookupProperties(unique(ps.basements$propiid), coiid='1842387')

z <- merge(ps.basements, props, by='propiid', all.x=TRUE, sort=FALSE)

kable(z)




# print more attributes
options(width=300)
print(valley.fever, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=NULL)

sink('examples/valley_fever.txt')
print(valley.fever, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)
sink()
