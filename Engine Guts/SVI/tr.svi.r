require(data.tree)

### 1.2 define svi tree ####
tr.svi <- Node$new(name = "site",
                   nextvar = "shorthsg",
                   nextlogical = "shorthsg == 'A' ; shorthsg == 'B' ; shorthsg == 'C' ; shorthsg == 'D'")

### level 1 hsg ###
tr.svi$AddChild("HSG A",
                result = "1 - Low") 

tr.svi$AddChild("HSG B",
                nextvar = "slope",
                nextlogical = "slope < 4 ; slope >= 4 & slope <= 6 ; slope > 6")

tr.svi$AddChild("HSG C",
                nextvar = "slope",
                nextlogical = "slope < 2 ; slope >= 2 & slope <= 6 ; slope > 6")

tr.svi$AddChild("HSG D",
                nextvar = "slope",
                nextlogical = "slope < 2 ; slope >= 2 & slope <= 4 ; slope > 4")

### level 2 slope ###
## B
tr.svi$`HSG B`$AddChild("Low slope",
                        result = "1 - Low") 
                        
tr.svi$`HSG B`$AddChild("Moderate slope",
                        nextvar = "kwfact",
                        nextlogical = "kwfact < 0.28 ; kwfact >= 0.28")

tr.svi$`HSG B`$AddChild("High slope",
                        result = "4 - High")

## C
tr.svi$`HSG C`$AddChild("Low slope",
                        result = "1 - Low") 

tr.svi$`HSG C`$AddChild("Moderate slope",
                        nextvar = "kwfact",
                        nextlogical = "kwfact < 0.28 ; kwfact >= 0.28")

tr.svi$`HSG C`$AddChild("High slope",
                        result = "4 - High")

## D
tr.svi$`HSG D`$AddChild("Low slope",
                        nextvar = "kwfact",
                        nextlogical = "kwfact < 0.28 ; kwfact >= 0.28")

tr.svi$`HSG D`$AddChild("Moderate slope",
                        result = "3 - Moderately High")

tr.svi$`HSG D`$AddChild("High slope",
                        result = "4 - High")


### level 3 kwfact ###
tr.svi$`HSG B`$`Moderate slope`$AddChild("Low kwfact",
                                         result = "2 - Moderate")

tr.svi$`HSG B`$`Moderate slope`$AddChild("High kwfact",
                                         result = "3 - Moderately High")


tr.svi$`HSG C`$`Moderate slope`$AddChild("Low kwfact",
                                         result = "2 - Moderate")

tr.svi$`HSG C`$`Moderate slope`$AddChild("High kwfact",
                                         result = "3 - Moderately High")

tr.svi$`HSG D`$`Low slope`$AddChild("Low kwfact",
                                         result = "1 - Low")

tr.svi$`HSG D`$`Low slope`$AddChild("High kwfact",
                                         result = "2 - Moderate")

save(tr.svi, file = "Engine Guts/SVI/datatree-svi.rdata")
