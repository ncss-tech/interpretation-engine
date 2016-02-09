
getAndCacheData <- function() {
  # init connection
  channel <- odbcDriverConnect(connection = "DSN=nasis_local;UID=NasisSqlRO;PWD=nasisRe@d0n1y")
  
  # get rules, note that "rule" is a reserved word, use [] to protect
  # load ALL rules, even those not ready for use
  rules <- sqlQuery(channel, "SELECT rulename, rd.ChoiceName as ruledesign, primaryinterp, notratedphrase, ruledbiidref, ruleiid, [rule]
FROM rule_View_0 
LEFT OUTER JOIN (SELECT * FROM MetadataDomainDetail WHERE DomainID = 2822) AS rd ON ruledesign = rd.ChoiceValue", stringsAsFactors=FALSE)
  
  # get all evaluation curves
  evals <- sqlQuery(channel, "SELECT evaliid, evalname, evaldesc, eval, et.ChoiceName as evaluationtype, invertevaluationresults
FROM evaluation_View_0 
LEFT OUTER JOIN (SELECT * FROM MetadataDomainDetail WHERE DomainID = 4884) AS et ON evaluationtype = et.ChoiceValue", stringsAsFactors=FALSE)
  
  # save tables for offline testing
  save(rules, evals, file='cached-NASIS-data.Rda')
}


# parse evaluation chunk XML and return as list
xmlChunkParse <- function(x) {
  # replace bogus encoding
  x <- gsub('utf-16', 'utf-8', x)
  # parse and convert to list
  x.doc <- xmlParse(x)
  l <- xmlToList(x.doc)
  return(l)
}

# dispatch specialized functions based on eval type
# x: evalulation record
# res: number of intermediate points
extractEvalCurve <- function(x, res=25) {
  et <- x$evaluationtype
  # various types
  if(et %in% c('ArbitraryCurve','ArbitraryLinear')) {
    res <- extractArbitraryCurveEval(x$eval)
    return(res)
  }
    
  if(et == 'Sigmoid') {
    res <- extractSigmoidCurveEval(x$eval, res)
    return(res)
  }
    
  if(et == 'Crisp') {
    res <- extractCrispCurveEval(x$eval, res)
    return(res)
  }
    
  
  ## ... there are many others
#   Linear
#   Trapezoid
#   Beta
#   IsNull
#   Gauss
#   Triangle
#   PI
  warning("curve type not yet supported", call. = FALSE)
  return(NULL)
}

# x: evalulation curve XML text
extractArbitraryCurveEval <- function(x) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

# x: evalulation curve XML text
# res: number of intermediate points
extractSigmoidCurveEval <- function(x, res) {
  l <- xmlChunkParse(x)
  # get the lower and upper asymptotes
  dp <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
  # generate a sequence along domain
  domain <- seq(from=dp[1], to=dp[2], length.out=res)
  # create sigmoid curve
  sig.loc <- (dp[1] + dp[2])/2 # location parameter is center of range
  sig.scale <- 1
  rating <- plogis(domain, location=sig.loc, scale=sig.scale)
  # if the first value is > second, then swap direction
  if(dp[2] < dp[1])
    rating <- 1 - rating
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

## TODO: parsing expression must be generalized
# x: evalulation curve XML text
# res: number of intermediate points
extractCrispCurveEval <- function(x, res) {
  l <- xmlChunkParse(x)
  # get expression
  crisp.expression <- l$CrispExpression
  
  # insert domain vector at begining
  crisp.expression <- paste0('domain ', crisp.expression)
  
  # replace logical operators, and add domain vector
  crisp.expression <- gsub('and', '& domain', crisp.expression)
  crisp.expression <- gsub('or', '| domain', crisp.expression)
  
  # generate domain range
  domain.range <- range(na.omit(as.numeric(unlist(strsplit(crisp.expression, "[^0-9.]+")))))
  # extend domain by some fuzz.. ?
  fuzz <- mean(domain.range) / 2
  domain <- seq(from=domain.range[1] - fuzz, to=domain.range[2] + fuzz, length.out = res)
  
  # apply evaluation, implicitly converts TRUE/FALSE -> 1/0
  rating <- as.numeric(eval(parse(text=crisp.expression)))
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

# serial number added to names
makeNamesUnique <- function(l) {
  l.names <- names(l$Children)
  # multiple children types
  tab <- table(l.names)
  t.names <- names(tab)
  
  # iterate over types
  for(this.type in seq_along(t.names)) {
    # iterate over duplicate names
    # get an index to this type
    idx <- which(l.names == t.names[this.type])
    for(this.element in seq_along(idx)) {
      # make a copy of this chunk of the tree
      l.sub <- l$Children[[idx[this.element]]]
      # if this is a terminal leaf then re-name and continue
      if(is.null(l.sub$Children)) {
        # print('leaf')
        names(l$Children)[idx[this.element]] <- paste0(t.names[this.type], '_', this.element)
      }
      # otherwise re-name and then step into this element and apply this function recursively
      else {
        # print('branch')
        names(l$Children)[idx[this.element]] <- paste0(t.names[this.type], '_', this.element)
        # fix this branch and splice back into tree
        l$Children[[idx[this.element]]] <- makeNamesUnique(l.sub)
      }
    }
  }

  return(l)
}

# use hash function for unique names
makeNamesUnique2 <- function(l) {
  
  # iterate over list elements
  for(i in seq_along(l$Children)) {
    # get curret name
    i.name <- names(l$Children)[i]
    # get the contents
    i.contents <- l$Children[[i]]
    # make a new name via digest
    i.name.new <- paste0(i.name, '_', digest(i.contents, algo = 'xxhash32'))
    
    # if this is a terminal leaf then re-name and continue
    if(is.null(i.contents$Children)) {
      # print('leaf')
      names(l$Children)[i] <- i.name.new
    }
    # otherwise re-name and then step into this element and apply this function recursively
    else {
      # print('branch')
      names(l$Children)[i] <- i.name.new
      # fix this branch and splice back into tree
      l$Children[[i]] <- makeNamesUnique2(i.contents)
    }
  }
    
  return(l)
}



# lookup the actual rule name
# split Rule ref Ids from Evaluation ref Ids
makeNamesUnique3 <- function(l) {
  
  # iterate over list elements
  for(i in seq_along(l$Children)) {
    # get curret name
    i.name <- names(l$Children)[i]
    # get the contents
    i.contents <- l$Children[[i]]
    
    # make new name from sub-rule
    # note that ALL rules must be loaded
    if(grepl('RuleRule', i.name)) {
      # get sub-rule
      i.rid <- i.contents[['RefId']]
      sr <- rules[rules$ruleiid == i.rid, ]
      i.name.new <- sr$rulename
      # copy rule reference ID
      l$Children[[i]]$rule_refid <- i.rid
    }
    if(grepl('RuleEvaluation', i.name)) {
      # get evaluation
      i.eid <- i.contents[['RefId']]
      re <- evals[evals$evaliid == i.eid, ]
      i.name.new <- re$evalname
      # copy rule reference ID
      l$Children[[i]]$eval_refid <- i.eid
    }
    # otherwise use digest
    if(! grepl('RuleRule|RuleEvaluation', i.name))
      i.name.new <- paste0(i.name, '_', digest(i.contents, algo = 'xxhash32'))
    
    # if this is a terminal leaf then re-name and continue
    if(is.null(i.contents$Children)) {
      names(l$Children)[i] <- i.name.new
    }
    # otherwise re-name and then step into this element and apply this function recursively
    else {
      names(l$Children)[i] <- i.name.new
      # fix this branch and splice back into tree
      l$Children[[i]] <- makeNamesUnique3(i.contents)
    }
  }
  
  return(l)
}



# attempt to convert interpretation rule into data.tree representation
parseRule <- function(x) {
  
  # parse XML block into list
  l <- xmlChunkParse(x$rule)
  
  # node names must be made unique before data.tree object/methods are useful
  l$RuleStart <- makeNamesUnique3(l$RuleStart)
  
  # convert XML list into data.tree object
  n <- FromListExplicit(l$RuleStart, nameName=NULL, childrenName='Children')
  
  # copy interp name to top of tree
  n$name <- x$rulename
  
  return(n)
}


## TODO: this won't always link all subrules in a single pass... why?
linkSubRules <- function(node) {
  # if this is a sub-rule
  if(!is.null(node$rule_refid)) {
    # get sub-rule
    sr <- rules[rules$ruleiid == node$rule_refid, ]
    # get sub-rule as a Node
    sr.node <- parseRule(sr)
    # recursively look-up any sub rules
    sr.node$Do(linkSubRules)
    # splice-in sub rule
    node$parent$AddChildNode(sr.node)
  }
}

linkEvaluationFunctions <- function(node) {
  ## TODO: how can we splice-in evaluation functions?
}
