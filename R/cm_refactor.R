### this is a quick helper function to make confusion matricies easier
### all it does is refactor two inputs and do the CM
### joe brehm 3-23-21

#' Helper function to make confusion matrices easier
#' 
#' Refactor two inputs and make confusion matrix with caret package
#' 
#' @param predvar Predictor variable
#' @param refvar Reference variable
#' @author Joseph Brehm
#'
#' @return A caret confusion matrix
#' @export
cm_refactor <- function(predvar, refvar){
  # refactor both inputs to have the same levels as one another
  
  stopifnot(requireNamespace("caret"))
  stopifnot(requireNamespace("forcats"))
  
  refvar <- forcats::fct_explicit_na(as.character(refvar))
  predvar <- forcats::fct_explicit_na(as.character(predvar))
  
  predvar <- factor(x = predvar, 
                    levels = levels(refvar))
  refvar <- factor(x = refvar,
                   levels = levels(predvar))
  
  cm <- caret::confusionMatrix(reference = refvar,
                        data = predvar)
  return(cm)
}
