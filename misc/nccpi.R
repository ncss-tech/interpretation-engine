library(InterpretationEngine)

r <- initRuleset("NCCPI - National Commodity Crop Productivity Index (Ver 3.0)")
p <- getPropertySet(r)
p <- merge(p, data.table::rbindlist(propdefByPropname(p$propname)), by = "propiid")
p2 <- p
p2$evaluation <- NULL
View(unique(p2))

cvirrr::cleanCVIR(p$prop[2]) |> 
  cvirrr::CVIRScript() |> 
  cvirrr::parseCVIR() |>
  attr("TSQL") |> 
  soilDB::dbQueryNASIS(soilDB::NASIS(), q = _)
