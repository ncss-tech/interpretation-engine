library(soilDB)
library(RODBC)
library(XML)
library(plyr)
library(data.tree)
library(digest)
library(jsonlite)
library(sharpshootR)
library(knitr)

library(stringr)

# devtools::load_all()

# re-load cached data
# getAndCacheData()

# load cached data
load('cached-NASIS-data.Rda')

# quick check
properties[which(properties$propname == 'UNIFIED BOTTOM LAYER'), ]
cat(property_def$prop[which(property_def$propiid == '16681')])


# properties that accept arguments
# find all cases of DERIVE ... using (folder):(property)
z <- str_match_all(property_def$prop, 'accept')

# index properties that accept arguments
args.idx <- which(sapply(z, function(i) length(i) > 0))
property_def$propiid[args.idx]

# mostly variations on a theme: find a thickness within a range
properties$propname[properties$propiid %in% property_def$propiid[args.idx]]

# how would this be implemented in R ??

## example: 
# "AASHTO GROUP INDEX NUMBER THICKEST LAYER IN DEPTH 10-40 in."
# DERIVE layer_thickness from rv using "NSSC Pangaea":"LAYER THICKNESS IN RANGE; ABOVE A RESTRICTIVE LAYER" (25,100).
#



# find all cases of DERIVE ... using (folder):(property)
z <- str_match_all(property_def$prop, 'DERIVE.*using.*?(["a-zA-Z0-9 ]+):(["a-zA-Z0-9 ]+)')

# calls to other properties within each propertie
derive.per.prop <- sapply(z, nrow)

# breakdown 1st-degree dependence structure
addmargins(table('DERIVE calls per property'=derive.per.prop))


## TODO: convert to purrr syntax for conditional eval
# property groups mentioned
cleanText <- function(x, idx) {
  x <- x[, idx]
  x <- trimws(x)
  x <- gsub(pattern = '"', '', x)
  return(x)
}

grp <- sapply(z, cleanText, idx=2)
prop <- sapply(z, cleanText, idx=3)

sort(table(unlist(grp)), decreasing = TRUE)
sort(table(unlist(prop)), decreasing = TRUE)


# AWC example from above
prop[[477]]


## TODO: 
# determine nth-degree dependence structure


# determin all field utilized by a property



