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


# source local functions
source('local-functions.R')

# re-load cached data
# getAndCacheData()

# load cached data
load('cached-NASIS-data.Rda')

# quick check
properties[which(properties$propname == 'AWC, 0-50CM OR FIRST RESTRICTIVE LAYER'), ]
cat(property_def$prop[which(property_def$propiid == '10244')])


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


# determine nth-degree dependence structure
