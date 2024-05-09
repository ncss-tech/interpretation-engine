## re-make cached NASIS data with unexported function
InterpretationEngine:::getAndCacheData()
<<<<<<< HEAD
=======

>>>>>>> 785eea1aff735211a12fa48e8a5dc786e740731d

load("misc/cached-NASIS-data.Rda")

source("misc/internal-datasets/SVI/tr.svi.R")
load("misc/internal-datasets/SVI/datatree-svi.rdata")

source("misc/internal-datasets/HSG/tr.hsg.R")
load("misc/internal-datasets/HSG/datatree-hsg.rdata")

NASIS_evaluations <- evals
NASIS_properties <- properties
NASIS_property_def <- property_def
NASIS_rules <- rules

datatree_svi <- tr.svi
datatree_hsg <- tr.hsg

usethis::use_data(
  overwrite = TRUE,
  datatree_svi,
  datatree_hsg,
  NASIS_evaluations,
  NASIS_properties,
  NASIS_property_def,
  NASIS_rules
)
