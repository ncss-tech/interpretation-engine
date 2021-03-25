load("misc/cached-NASIS-data.Rda")
load("misc/TODO/SVI/datatree-svi.rdata")
load("misc/TODO/HSG/datatree-hsg.rdata")

NASIS_evaluations <- evals
NASIS_properties <- properties
NASIS_property_def <- property_def
NASIS_rules <- rules

save(NASIS_evaluations, file = "data/NASIS_evaluations.rda", compress = "xz")
save(NASIS_properties, file = "data/NASIS_properties.rda", compress = "xz")
save(NASIS_property_def, file = "data/NASIS_property_def.rda", compress = "xz")
save(NASIS_rules, file = "data/NASIS_rules.rda", compress = "bzip2")

datatree_svi <- tr.svi
datatree_hsg <- tr.hsg

save(datatree_svi, file = "data/datatree_svi.rda", compress = "xz")
save(datatree_hsg, file = "data/datatree_hsg.rda", compress = "bzip2")
