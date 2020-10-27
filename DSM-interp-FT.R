library(soilDB)
library(RODBC)
library(XML)
library(data.tree)
library(digest)
library(jsonlite)
library(sharpshootR)
library(knitr)
library(furrr)

## TODO: phase-out this functionality
library(plyr)


# source local functions
source('local-functions.R')

# re-load cached data
# getAndCacheData()

# load cached data
load('cached-NASIS-data.Rda')


## two required by DSM/Interps FT
# Valley fever
# Dwellings with basements

## convenience function for setting up rules / evals
valley.fever <- initRuleset(rulename = 'Valley Fever')
basements <- initRuleset(rulename = 'ENG - Dwellings With Basements')

# get properties used
ps.valley.fever <- getPropertySet(valley.fever)
ps.basements <- getPropertySet(basements)

# full listing
cat(unique(ps.valley.fever$propname), sep = '\n')
cat(unique(ps.basements$propname), sep = '\n')


# init additional cores
plan(multisession)

# this is a NASIS component record ID
# parallel requests to national NASIS server
props <- lookupProperties(unique(ps.basements$propiid), coiid='1842387')

# stop additional cores
plan(sequential)

# join / check
z <- merge(ps.basements, props, by='propiid', all.x=TRUE, sort=FALSE)
kable(z)




# print more attributes
options(width=300)
print(valley.fever, 'Type', 'Value', 'RefId', 'rule_refid', 'eval_refid', 'evalType', limit=NULL)

sink('examples/valley_fever.txt')
print(valley.fever, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)
sink()



sink('examples/ENG - Dwellings With Basements.txt')
print(basements, 'Type', 'Value', 'evalType', 'propname', 'propiid', 'propuom', limit=NULL)
sink()


