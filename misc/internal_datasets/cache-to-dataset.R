load("misc/cached-NASIS-data.Rda")
load("misc/TODO/SVI/datatree-svi.rdata")
load("misc/TODO/HSG/datatree-hsg.rdata")

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
