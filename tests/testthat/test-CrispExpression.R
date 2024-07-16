test_that("crisp expression parsing works", {
  # check that case is ignored for logical operators in crispexpression
  # debug(initRuleset)
  # debug(.crispFunctionGenerator)
  # 
  
 # test various rules that have specific handling in the parser
  
 expect_silent(initRuleset(rulename = "FOR - Potential Erosion Hazard, Road/Trail, Spring Thaw (AK)"))
  
 expect_silent(initRuleset(rulename = "FOR - Potential Seedling Mortality (FL)"))
  
 expect_silent(initRuleset(rulename = "AGR - Spring Wheat Yield (MT)"))
 
 expect_silent(initRuleset(rulename = "GRL-ESD (NE) MLRA 75, 102C, 106 KEY (NE-Test)"))
 
 expect_silent(initRuleset(rulename = "AGR-Growing Season Wetness (ND)"))
  
 expect_silent(initRuleset(rulename = "ENG - Daily Cover for Landfill (AK)"))
  
 expect_silent(initRuleset(rulename = "CLR-cropland limitation for wheat"))
  
 expect_silent(initRuleset(rulename = "WLF - Desert Tortoise (CA)"))
  
 expect_silent(initRuleset(rulename = "ENG - OSHA Soil Types (TX)"))
  
 expect_silent(initRuleset(rulename = "Ground Penetrating Radar Penetration"))
  
 expect_silent(initRuleset(rulename = "WMS - Subsurface Drains - Installation (VT)"))
  
 expect_silent(initRuleset(rulename = "Valley Fever"))
  
 expect_silent(initRuleset(rulename = "LCC - NIRR Land Capability Class"))
  
 expect_silent(initRuleset(rulename = "FOR - Windthrow Hazard (WA)"))
 
 expect_silent(initRuleset(rulename = "LCC-irr"))
 
 expect_silent(initRuleset(rulename = "FOR - Conservation Tree/Shrub Groups (MT)"))
 
 expect_silent(initRuleset(rulename = "Commodity Crop Productivity Index (Corn) (WI)"))
})
