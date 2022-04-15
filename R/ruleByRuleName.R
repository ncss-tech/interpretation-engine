
#' Rule by Rule Name
#'
#' @param rulename Character. Rule Name
#'
#' @return a row from the `NASIS_rules` data.frame
#' @export
#'
#' @examples
#' ruleByRulename("Erodibility Factor Maximum")
ruleByRulename <- function(rulename) {
  rules <- InterpretationEngine::NASIS_rules
  
  r <- InterpretationEngine::parseRule(rules[rules$rulename == rulename,][1,])
  r$Do(traversal = 'pre-order', fun = InterpretationEngine::linkSubRules)
  r$Do(traversal = 'pre-order', fun = InterpretationEngine::linkEvaluationFunctions)
  r
}

# a_rule <- ruleByRulename("Erodibility Factor Maximum")
# a_rule$attributesAll
# eid <- a_rule$Get("eval_refid")
# InterpretationEngine::evalByEID(na.omit(eid)[1], 0.55)
# 
# a_rule <- ruleByRulename("pH Minimum (acid)")
# a_rule$attributesAll
# eid <- a_rule$Get("eval_refid")
# InterpretationEngine::evalByEID(na.omit(eid)[2], 5.5)
# 

# evals <- InterpretationEngine::NASIS_evaluations
# props <- InterpretationEngine::NASIS_properties
# 
