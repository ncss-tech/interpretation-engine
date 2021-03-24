### this is a quick helper function to make confusion matricies easier
### all it does is refactor two inputs and do the CM
### joe brehm 3-23-21

require(caret)

cm_refactor <- function(predvar, refvar){
  # refactor both inputs to have the same levels as one another
  
  refvar <- fct_explicit_na(as.character(refvar))
  predvar <- fct_explicit_na(as.character(predvar))
  
  predvar <- factor(x = predvar, 
                    levels = levels(refvar))
  refvar <- factor(x = refvar,
                   levels = levels(predvar))
  
  cm <- confusionMatrix(reference = refvar,
                        data = predvar)
  return(cm)
}
