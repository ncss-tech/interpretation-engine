### ~11/15 jrb
### Added yleft and yright arguments to the approxfun calls, in the extract[type]curve functions
### this should fix the min & max responses not being 0 and 1

### 2/18 jrb
### sigmoid scale defaulting to 1 creates poor fits with many evaluations, 
#### added sig.scale as a parameter passed from evalbyeid > extractevalcurve > extractSigmoidCurveEval
### added evalbyeid function

### 3/19/21 jrb
## added vf, dwb, svi, and hsg code

### 12/30/21 agb
## Cleaned and generalized evaluation curves based on NASIS implementation 
##  - See EvaluationCurves.R and CVIRCurve.R
##  - Implemented missing curve types: Beta, Gauss, Triangle, PI
##  - Added function generator for Crisp Expressions not involving "domain"
##  - Fixed scaling issues w/ sigmoid eval functions (no longer using plogis())
##  - Fixed strange results w/ trapezoid eval functions 
##  - The `sig.scale` argument for sigmoids, and `resolution` argument for curves are no longer used. The interpolator methods now will generate a sufficiently detailed domain such that this does not need to be customized at a high level.
## Moved Joe's tree_eval()-based functions to own file
## Moved plotEvaluation() to own file

## Issues encountered
##  - lookupProperties() WEB-PROPERY-COMPONENT_property rounds decimal values

#' Extract Evaluation Curve by Evaluation ID
#'
#' @param eid Evaluation ID -- NB: not rule id or property id. Evaluation only. 
#' @param d data to pass through evaluation curve?
#' @param sig.scale not used
#'
#' @return result of evaluation made with the specified evaluation curve
#' @export
#' @aliases evalbyeid
#' @rdname evalByEID
evalByEID <- function(eid, d, sig.scale = 1) {
  evals <- InterpretationEngine::NASIS_evaluations
  extractEvalCurve(evals[evals$evaliid == eid, ])(d)
}

#' @export
#' @rdname evalByEID
evalbyeid <- function(eid, d, sig.scale = 1) {
  .Deprecated("evalByEID")
  evalByEID(eid, d, sig.scale)
}

#' Initialize a ruleset
#'
#' @param rulename Rule name character
#'
#' @return ruleset
#' @export
initRuleset <- function(rulename) {
  rules <- InterpretationEngine::NASIS_rules
  
  y <- rules[rules$rulename == rulename, ]
  
  dt <- parseRule(y)
  
  # recursively splice-in sub-rules
  dt$Do(traversal = 'pre-order', fun = linkSubRules)
  dt$Do(traversal = 'pre-order', fun = linkEvaluationFunctions)
  dt$Do(traversal = 'pre-order', fun = linkHedgeOperatorFunctions)
  
  return(dt)
}

#' Get Attribute By Evaluation
#'
#' @param x a data.tree
#' @param a attribute
#'
#' @return attribute
#' @export
getAttributeByEval <- function(x, a) {
  p <- x$Get(a)
  # remove NA and convert to data.frame
  idx <- which(!is.na(p))
  p <- p[idx]
  d <- do.call('rbind', lapply(seq_along(p), function(i) {
    data.frame(evaluation = names(p[i]), V1 = p[i])
  }))
  names(d) <- c('evaluation', a)
  rownames(d) <- NULL
  return(d)
}

# get the unique set of properties for all evaluations
# this requires several calls to getAttributeByEval(), one for each attribute
# why?

#' Get unique properties for all evaluations
#'
#' @param x vector of evaluations
#'
#' @return a set of properties
#' @export
#'
getPropertySet <- function(x) {
  p.1 <- getAttributeByEval(x, 'propname')
  p.2 <- getAttributeByEval(x, 'propiid')
  
  # splice together with left join
  p <- merge(p.1, p.2, by = 'evaluation', all.x = TRUE, sort = FALSE)
  return(unique(p))
}

#' Cache dataset containing important NASIS data, not exported
#' 
#' soilDB::uncode() used to convert coded -> uncoded values
#' 
#' @return cached data
#' 
#' @importFrom soilDB uncode dbQueryNASIS NASIS
getAndCacheData <- function() {
  
  # get rules, note that "rule" is a reserved word, use [] to protect
  # load ALL rules, even those not ready for use
  rules <- soilDB::dbQueryNASIS(soilDB::NASIS(), 
                                "SELECT rulename, ruledesign, primaryinterp, notratedphrase, dataafuse, 
                                        ruledbiidref, ruleiid, [rule]
                                 FROM rule_View_0")
  
  # get all evaluation curves
  evals <- soilDB::dbQueryNASIS(soilDB::NASIS(), 
                                "SELECT evaliid, evalname, evaldesc, CAST(eval AS text) AS eval, dataafuse,
                                        evaluationtype, invertevaluationresults, propiidref AS propiid
                                 FROM evaluation_View_0")
  
  # get basic property parameters, but not the property definition
  properties <- soilDB::dbQueryNASIS(soilDB::NASIS(), 
                                     "SELECT propiid, propuom, propmin, propmax, propmod, propdefval,
                                             propname, dataafuse
                                      FROM property_View_0")
  
  # property descriptions and CVIR code
  property_def <- soilDB::dbQueryNASIS(soilDB::NASIS(), 
                                       "SELECT propiid, propdesc, prop 
                                        FROM property_View_0")
  
  # uncode
  rules <- soilDB::uncode(rules)
  evals <- soilDB::uncode(evals)
  
  properties <- soilDB::uncode(properties)
  
  # treat property IDs as characters
  evals$propiid <- as.character(evals$propiid)
  properties$propiid <- as.character(properties$propiid)
  property_def$propiid <- as.character(property_def$propiid)
  
  ## TODO: maybe useful to keep the split?
  # there is only 1 property / evaluation, so join them
  evals <- merge(evals, properties, by = 'propiid', all.x = TRUE, sort = FALSE)
  
  # save tables for offline testing
  save(rules, evals, properties, property_def, file = 'misc/cached-NASIS-data.Rda')
}

# parse evaluation chunk XML and return as list
#' Parse an evaluation chunk XML return a list
#'
#' @param x evaluation curve XML text
#'
#' @return parsed XML chunk
#' @export
#' @importFrom XML xmlParse xmlToList
xmlChunkParse <- function(x) {
  # replace bogus encoding
  x <- gsub('utf-16', 'utf-8', x)
  # parse and convert to list
  x.doc <- xmlParse(x)
  l <- xmlToList(x.doc)
  return(l)
}

#' serial number added to names
#'
#' @param l a data.tree
#'
#' @return a data.tree
#' @export
#'
makeNamesUnique <- function(l) {
  l.names <- names(l$Children)
  
  # multiple children types
  tab <- table(l.names)
  t.names <- names(tab)
  
  # iterate over types
  for (this.type in seq_along(t.names)) {
    
    # iterate over duplicate names
    # get an index to this type
    idx <- which(l.names == t.names[this.type])
    for (this.element in seq_along(idx)) {
      # make a copy of this chunk of the tree
      l.sub <- l$Children[[idx[this.element]]]
      
      # if this is a terminal leaf then re-name and continue
      if (is.null(l.sub$Children)) {
        # print('leaf')
        names(l$Children)[idx[this.element]] <- paste0(t.names[this.type], '_', this.element)
      } else {
        
        # otherwise re-name and then step into this element and apply recursively
        # print('branch')
        names(l$Children)[idx[this.element]] <- paste0(t.names[this.type], '_', this.element)
        
        # fix this branch and splice back into tree
        l$Children[[idx[this.element]]] <- makeNamesUnique(l.sub)
      }
    }
  }
  
  return(l)
}

# 
#' Use hash function for unique names
#'
#' @param l a data.tree
#'
#' @return a data.tree
#' @export
#' @importFrom digest digest
makeNamesUnique2 <- function(l) {
  
  # iterate over list elements
  for (i in seq_along(l$Children)) {
    
    # get current name
    i.name <- names(l$Children)[i]
    
    # get the contents
    i.contents <- l$Children[[i]]
    
    # make a new name via digest
    i.name.new <-
      paste0(i.name, '_', digest(i.contents, algo = 'xxhash32'))
    
    # if this is a terminal leaf then re-name and continue
    if (is.null(i.contents$Children)) {
      # print('leaf')
      names(l$Children)[i] <- i.name.new
    } else {
      # print('branch')
      names(l$Children)[i] <- i.name.new
      
      # fix this branch and splice back into tree
      l$Children[[i]] <- makeNamesUnique2(i.contents)
    }
  }
  
  return(l)
}

# lookup the actual rule name
# 
#' lookup rule name
#' 
#' Split Rule ref Ids from Evaluation ref Ids
#'
#' @param l a data.tree
#'
#' @return a data.tree
#' @export
#'
#' @importFrom digest digest
makeNamesUnique3 <- function(l) {
  evals <- InterpretationEngine::NASIS_evaluations
  rules <- InterpretationEngine::NASIS_rules
  
  # iterate over list elements
  for (i in seq_along(l$Children)) {
    
    # get current name
    i.name <- names(l$Children)[i]
    
    # get the contents
    i.contents <- l$Children[[i]]
    
    # make new name from sub-rule
    # note that ALL rules must be loaded
    if (grepl('RuleRule', i.name)) {
      
      # get sub-rule
      i.rid <- i.contents[['RefId']]
      sr <- rules[rules$ruleiid == i.rid,]
      i.name.new <- sr$rulename
      
      # copy rule reference ID
      l$Children[[i]]$rule_refid <- i.rid
    }
    
    if (grepl('RuleEvaluation', i.name)) {
      # get evaluation
      i.eid <- i.contents[['RefId']]
      re <- evals[evals$evaliid == i.eid,]
      i.name.new <- re$evalname
      
      # copy rule reference ID
      l$Children[[i]]$eval_refid <- i.eid
    }
    
    # otherwise use digest
    if (!grepl('RuleRule|RuleEvaluation', i.name))
      i.name.new <- paste0(i.name, '_', digest(i.contents, algo = 'xxhash32'))
    
    # if this is a terminal leaf then re-name and continue
    if (is.null(i.contents$Children)) {
      names(l$Children)[i] <- i.name.new
    } else { 
      # otherwise re-name and then step into this element and apply this function recursively
      names(l$Children)[i] <- i.name.new
      
      # fix this branch and splice back into tree
      l$Children[[i]] <- makeNamesUnique3(i.contents)
    }
  }
  
  return(l)
}

#' Convert interpretation rule into data.tree representation
#'
#' @param x should contain `rule` element with XML text to parse
#'
#' @return a data.tree
#' @export
#' @importFrom data.tree FromListExplicit 
parseRule <- function(x) {
  # parse XML block into list
  l <- xmlChunkParse(x$rule)
  
  # node names must be made unique before data.tree object/methods are useful
  l$RuleStart <- makeNamesUnique3(l$RuleStart)
  
  # convert XML list into data.tree object
  n <- FromListExplicit(l$RuleStart, nameName = NULL, childrenName = 'Children')
  
  # copy interp name to top of tree
  n$name <- x$rulename
  
  return(n)
}

#' Link Subrules
#'
#' @param node a data.tree node
#'
#' @return a modified data.tree object
#' @export
#'
linkSubRules <- function(node) {
  rules <- InterpretationEngine::NASIS_rules
  
  # if this is a sub-rule
  if (!is.null(node$rule_refid)) {
    # get sub-rule
    sr <- rules[rules$ruleiid == node$rule_refid,]
    # get sub-rule as a Node
    sr.node <- parseRule(sr)
    ## TEMP HACK: rename sub rule node
    # sr.node$name <- paste0(sr.node$name, '_', digest(sr.node, 'xxhash32'))
    # recursively look-up any sub rules
    sr.node$Do(linkSubRules)
    
    ### still figuring this out:
    
    ### 1. splice into parent node, then prune current node
    # node$parent$AddChildNode(sr.node)
    ## TODO: prune the current node
    
    ### 2. splice the children of the sub-rule to the current node [seems better]
    for (i in seq_along(sr.node$count)) {
      node$AddChildNode(sr.node$children[[i]])
    }
  }
}

#' Link Evaluation Functions
#'
#' @param node a data.tree node
#'
#' @return a modified data.tree object
#' @export
#'
linkEvaluationFunctions <- function(node) {
  evals <- InterpretationEngine::NASIS_evaluations
  
  # only operate on evaluations
  if (!is.null(node$eval_refid)) {
    
    # get eval record
    ev <- evals[evals$evaliid == node$eval_refid,]
    
    # assign eval metadata
    node$evalType <- ev$evaluationtype
    node$propname <- ev$propname
    node$propiid  <- as.character(ev$propiid)
    node$propuom  <- ev$propuom
    
    # get evaluation function
    # trap errors when an eval function fails
    f <- try(extractEvalCurve(ev), silent = FALSE)
    
    if (!inherits(f, 'try-error')) {
      node$evalFunction <- f
    } else {
      node$evalFunction <- function(x) {
        return(NULL)
      }
    }
  }
}

#' Link Hedge and Operator Functions
#'
#' @param node a data.tree node
#'
#' @return a modified data.tree object
#' @export
#'
linkHedgeOperatorFunctions <- function(node) {
  noc <- node$children
  for (n in noc) {
    name <- n$name
    if (is.null(name))
      return(NULL)
    if (grepl("Rule(Hedge|Operator)_", name)) {
        type <- n$Type
      if (!is.null(n$Value) && 
          is.numeric(as.numeric(n$Value))) {
        # used for POWER, MULTIPLY
        val <- n$Value
        n$evalFunction <- eval(substitute(function(x){
          FUN(x, val)
        }, list(FUN = functionHedgeOp(type),
                val = as.numeric(val))))
      } else {
        n$evalFunction <- eval(substitute(function(x) {
          FUN(x)
        }, list(FUN = functionHedgeOp(type))))
      }
    }
  }
}
