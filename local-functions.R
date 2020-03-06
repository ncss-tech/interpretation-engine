
initRuleset <- function(rulename) {
  
  ## rules has to be loaded from somewhere
  
  y <- rules[rules$rulename == rulename, ]
  
  dt <- parseRule(y)
  
  # recusively splice-in sub-rules
  dt$Do(traversal='pre-order', fun=linkSubRules)
  
  ## TODO: is this working?
  # splice-in evaluation functions, if possible
  dt$Do(traversal='pre-order', fun=linkEvaluationFunctions)
  
  return(dt)
  
}



# get all properties for single coiid and vector of property IDs
# TODO: vectorize over both arguments
# TODO: parallel requests?
# https://cran.r-project.org/web/packages/curl/vignettes/intro.html#async_requests

# this web report undestands multiple component rec. ids
lookupProperties <- function(coiid, propIDs) {
  
  # get a single property for a single component
  .getSingleProperty <- function(i, coiid) {
    url <- 'https://nasis.sc.egov.usda.gov/NasisReportsWebSite/limsreport.aspx?report_name=WEB-PROPERY-COMPONENT_property'
    args <- list(prop_id=i, cokey=coiid)
    res <- parseWebReport(url, args, index=1)
    
    # HTTP errors will result in NULL
    if(is.null(res))
      return(NULL)
    
    # otherwise, add property name back to the results for joining
    res <- cbind(propiid=i, res)
    return(res)
  }
  
  # convert back to DF and return
  res <- ldply(propIDs, .getSingleProperty, coiid=coiid, .progress='text')
  return(res)
}

getAttributeByEval <- function(x, a) {
  p <- x$Get(a)
  # remove NA and convert to data.frame
  idx <- which(!is.na(p))
  p <- p[idx]
  as.list(p)
  d <- ldply(p)
  names(d) <- c('evaluation', a)
  return(d)
}


# get the unique set of properties for all evaluations
# this requires several calls to getAttributeByEval(), one for each attribute
# why?
getPropertySet <- function(x) {
  p.1 <- getAttributeByEval(x, 'propname')
  p.2 <- getAttributeByEval(x, 'propiid')
  
  # splice together with left join
  p <- join(p.1, p.2, by='evaluation', type='left')
  return(unique(p))
}


## TODO: add critical points
plotEvaluation <- function(x, xlim=NULL, resolution=100, ...) {
  
  ## TODO: need higher-level checking: crisp expressions require a very different interface
  res <- extractEvalCurve(x)
  
  # default sequence attempts to use min/max range from eval
  # this isn't always useful, as min/max might be way too wide
  if(is.null(xlim)) {
    s <- seq(x$propmin, x$propmax, length.out = resolution)
    s.range <- range(s)
    xlim <- s.range
  } else {
    s <- seq(xlim[1], xlim[2], length.out = resolution)
    s.range <- range(s)
  }
    
  
  x.lab <- paste0(x$propname, ' (', x$propuom, ')')
  plot(0,0, type='n', xlab=x.lab, cex.lab=0.85, ylab='fuzzy rating', main=x$evalname, sub=x$evaluationtype, cex.sub=0.85, las=1, ylim=c(0, 1), xlim=xlim, ...)
  grid()
  abline(h=c(0,1), lty=2, col='red')
  lines(s, res(s))
  
}


# soilDB::uncode() used to convert coded -> uncoded values
getAndCacheData <- function() {
  # init connection
  channel <- odbcDriverConnect(connection = "DSN=nasis_local;UID=NasisSqlRO;PWD=nasisRe@d0n1y365")
  
  # get rules, note that "rule" is a reserved word, use [] to protect
  # load ALL rules, even those not ready for use
  rules <- sqlQuery(channel, "SELECT rulename, ruledesign, primaryinterp, notratedphrase, ruledbiidref, ruleiid, [rule]
FROM rule_View_0 ;", stringsAsFactors=FALSE)
  
  # get all evaluation curves
  evals <- sqlQuery(channel, "SELECT evaliid, evalname, evaldesc, eval, evaluationtype, invertevaluationresults, propiidref AS propiid
FROM evaluation_View_0 ;", stringsAsFactors=FALSE)
  
  # get basic property parameters, but not the property definition
  properties <- sqlQuery(channel, "SELECT propiid, propuom, propmin, propmax, propmod, propdefval, propname FROM property_View_0", stringsAsFactors=FALSE)
  
  # property descriptions and CVIR code
  property_def <- sqlQuery(channel, "SELECT propiid, propdesc, prop FROM property_View_0", stringsAsFactors=FALSE)
  
  # uncode
  rules <- soilDB::uncode(rules, stringsAsFactors = FALSE)
  evals <- soilDB::uncode(evals, stringsAsFactors = FALSE)
  properties <- soilDB::uncode(properties, stringsAsFactors = FALSE)
  
  # treat property IDs as characters
  evals$propiid <- as.character(evals$propiid)
  properties$propiid <- as.character(properties$propiid)
  property_def$propiid <- as.character(property_def$propiid)
  
  ## TODO: maybe useful to keep the split?
  # there is onle 1 property / evaluation, so join them
  evals <- join(evals, properties, by='propiid')
  
  # save tables for offline testing
  save(rules, evals, properties, property_def, file='cached-NASIS-data.Rda')
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


## TODO: return function and critical points as a list
# dispatch specialized functions based on eval type
# x: evalulation record
# res: number of intermediate points
extractEvalCurve <- function(x, resolution=25) {
  
  # type
  et <- x$evaluationtype
  # invert
  invert.eval <- x$invertevaluationresults
  
  
  ## TODO: this isn't finished, currently using linear interpolation
  # shoudl be some kind of spline interpolation, splinefun() isn't working
  if(et  == 'ArbitraryCurve') {
    res <- extractArbitraryCurveEval(x$eval, invert=invert.eval)
    return(res)
  }
  
  # linear interpolation
  if(et  == 'ArbitraryLinear') {
    res <- extractArbitraryLinearCurveEval(x$eval, invert=invert.eval)
    return(res)
  }
  
  if(et == 'Sigmoid') {
    res <- extractSigmoidCurveEval(x$eval, invert=invert.eval, resolution)
    return(res)
  }
    
  if(et == 'Crisp') {
    
    ## need a reliable characteristic to use another approach
    # some crisp evaluations are logical expressions that don't utilize thresholds
    if(is.na(x$propmin) & is.na(x$propmax)) {
      warning("curve type not yet supported", call. = FALSE)
      return(function(x) {return(NULL)})
    }
    
    # use the defined min / max values
    domain.min <- x$propmin
    domain.max <- x$propmax
    
    res <- extractCrispCurveEval(x$eval, invert=invert.eval, resolution, dmin=domain.min, dmax=domain.max)
    return(res)
  }
  
  if(et == 'Linear') {
    res <- extractLinearCurveEval(x$eval, invert=invert.eval, resolution)
    return(res)
  }
  
  if(et == 'Trapezoid') {
    res <- extractTrapezoidEval(x$eval, invert=invert.eval)
    return(res)
  }
  
  ## ... there are many others
#   Beta
#   IsNull
#   Gauss
#   Triangle
#   PI
  warning("curve type not yet supported", call. = FALSE)
  return(function(x) {return(NULL)})
}


# x: evalulation curve XML text
extractTrapezoidEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  # rating is fixed at 0 -> 1 -> 1 -> 0 along trapezoid from left to right
  rating <- c(0, 1, 1, 0)
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}


# x: evalulation curve XML text
extractArbitraryCurveEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  ## TODO: this should be a spline-based interpolator (?)
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

# x: evalulation curve XML text
extractArbitraryLinearCurveEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

# x: evalulation curve XML text
# res: number of intermediate points
extractSigmoidCurveEval <- function(x, invert, res) {
  l <- xmlChunkParse(x)
  # get the lower and upper asymptotes
  dp <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
  # generate a sequence along domain
  domain <- seq(from=dp[1], to=dp[2], length.out=res)
  # create sigmoid curve
  sig.loc <- (dp[1] + dp[2])/2 # location parameter is center of range
  sig.scale <- 1
  rating <- plogis(domain, location=sig.loc, scale=sig.scale)
  
  ## not sure about this, can it happen?
#   # if the first value is > second, then swap direction
#   if(dp[2] < dp[1])
#     rating <- 1 - rating
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

# x: evalulation curve XML text
# res: number of intermediate points
extractLinearCurveEval <- function(x, invert, res) {
  l <- xmlChunkParse(x)
  # get the lower and upper end points
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  # rating is implied: {0,1}
  rating <- c(0,1)
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

## TODO: breaks on eval "GRL-Frost Action = moderate"
## TODO: parsing expression must be generalized
## TODO: this doesn't work with expressions like this "!= \"oxisols\" or \"gelisols\""
# x: evalulation curve XML text
# res: number of intermediate points
extractCrispCurveEval <- function(x, invert, res, dmin, dmax) {
  l <- xmlChunkParse(x)
  # get expression
  crisp.expression <- l$CrispExpression
  
  # insert domain vector at begining
  crisp.expression <- paste0('domain ', crisp.expression)
  
  # replace logical operators, and add domain vector
  crisp.expression <- gsub('and', '& domain', crisp.expression)
  crisp.expression <- gsub('or', '| domain', crisp.expression)
  
  ## TODO: check for valid min/max
  # generate domain range using supplied range
  domain <- seq(from=dmin, to=dmax, length.out = res)
  
  # apply evaluation, implicitly converts TRUE/FALSE -> 1/0
  rating <- as.numeric(eval(parse(text=crisp.expression)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
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



## TODO: splice/prune issues
linkSubRules <- function(node) {
  # if this is a sub-rule
  if(!is.null(node$rule_refid)) {
    # get sub-rule
    sr <- rules[rules$ruleiid == node$rule_refid, ]
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
    for(i in seq_along(sr.node$count)) node$AddChildNode(sr.node$children[[i]])
  }
}

# this will break if there are errors in extractEvalCurve
linkEvaluationFunctions <- function(node) {
  # only operate on evaluations
  if(!is.null(node$eval_refid)) {
    # get eval record
    ev <- evals[evals$evaliid == node$eval_refid, ]
    
    # assign eval metadata
    node$evalType <- ev$evaluationtype
    node$propname <- ev$propname
    node$propiid  <- as.character(ev$propiid)
    node$propuom  <- ev$propuom
    
    # get evaluation function
    # trap errors when an eval function fails
    f <- try(extractEvalCurve(ev), silent = TRUE)
    if(class(f) != 'try-error') {
      node$evalFunction <- f
    }
    
    ## come back and figure out what is wrong in evalXXX function
    else
      node$evalFunction <- function(x) return(NULL)
  }
}
