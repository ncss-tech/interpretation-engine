
### ~11/15 jrb
### Added yleft and yright arguments to the approxfun calls, in the extract[type]curve functions
### this should fix the min & max responses not being 0 and 1

### 2/18 jrb
### sigmoid scale defaulting to 1 creates poor fits with many evaluations, 
#### added sig.scale as a parameter passed from evalbyeid > extractevalcurve > extractSigmoidCurveEval
### added evalbyeid function

### 3/19/21 jrb
## added vf, dwb, svi, and hsg code
# 
# require(plyr)
# require(tidyverse) 
# require(data.tree)
# require(XML)
# require(soilDB)
# require(digest)
# require(raster)



#' Evaluation by the eid code
#'
#' @param eid Evaluation ID -- NB: not rule id or property id. Evaluation only. 
#' @param d data to pass through evaluation curve?
#' @param sig.scale default 1
#'
#' @return result of evaluation made with the specified evaluation curve
#' @export
#'
evalbyeid <- function(eid, 
                      d,
                      sig.scale = 1) {
  
    evals <- InterpretationEngine::NASIS_evaluations
    
    e = evals[evals$evaliid == eid,]
    f = extractEvalCurve(e, sig.scale = sig.scale)
    outdata = f(d)
    return(outdata)
  }


#' Initialize a ruleset
#'
#' @param rulename Rule name charatcer
#'
#' @return ruleset
#' @export
initRuleset <- function(rulename) {
  
  rules <- InterpretationEngine::NASIS_rules
  
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
#' Lookup Properties using NASIS Web Report
#' 
#' This function uses `WEB-PROPERY-COMPONENT_property` NASIS Web Report to lookup property data
#'
#' @param coiid Vector of component IDs (`coiid`)
#' @param propIDs Vector of property IDs 
#'
#' @return properties?
#' @export
#'
#' @importFrom soilDB parseWebReport
#' @importFrom plyr ldply
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

#' Get Attribute By Evaluation
#'
#' @param x a data.tree
#' @param a attribute
#'
#' @return attribute
#' @export
#'
#' @importFrom plyr ldply
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
#' Get unique properties for all evaluations
#'
#' @param x vector of evaluations
#'
#' @return a set of properties
#' @export
#'
#' @importFrom plyr join
getPropertySet <- function(x) {
  p.1 <- getAttributeByEval(x, 'propname')
  p.2 <- getAttributeByEval(x, 'propiid')
  
  # splice together with left join
  p <- join(p.1, p.2, by='evaluation', type='left')
  return(unique(p))
}


## TODO: add critical points
#' Plot Evaluation Curve
#'
#' @param x data
#' @param xlim `plot` xlim default `NULL`
#' @param resolution number of points (default 100)
#' @param ... additional arguments passed to plot
#'
#' @return a plot
#' @export
#' @importFrom graphics grid abline lines
plotEvaluation <- function(x, xlim=NULL, resolution=100, ...) {
  
  # most evaluation curves return an approxfun() function
  res <- extractEvalCurve(x)
  
  # crisp expressions return a function of x that can return a logical vector
  if (!is.null(attr(res, 'CrispExpression'))) {
    stop("Cannot plot CrispExpression: ", attr(res, 'CrispExpression'), call. = FALSE)
  }
  
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
#' Cache dataset containing important NASIS data
#' soilDB::uncode() used to convert coded -> uncoded values
#' @return cached data
#' @export
#' 
#' @importFrom soilDB uncode dbQueryNASIS NASIS
#' @importFrom plyr join
getAndCacheData <- function() {
  
  # get rules, note that "rule" is a reserved word, use [] to protect
  # load ALL rules, even those not ready for use
  rules <- soilDB::dbQueryNASIS(soilDB::NASIS(), "SELECT rulename, ruledesign, primaryinterp, notratedphrase, ruledbiidref, ruleiid, [rule]
FROM rule_View_0 ;")
  
  # get all evaluation curves
  evals <- soilDB::dbQueryNASIS(soilDB::NASIS(), "SELECT evaliid, evalname, evaldesc, CAST(eval AS text) AS eval, evaluationtype, invertevaluationresults, propiidref AS propiid
FROM evaluation_View_0 ;")
  
  # get basic property parameters, but not the property definition
  properties <- soilDB::dbQueryNASIS(soilDB::NASIS(), "SELECT propiid, propuom, propmin, propmax, propmod, propdefval, propname FROM property_View_0")
  
  # property descriptions and CVIR code
  property_def <- soilDB::dbQueryNASIS(soilDB::NASIS(), "SELECT propiid, propdesc, prop FROM property_View_0")
  
  # uncode
  rules <- soilDB::uncode(rules, stringsAsFactors = FALSE)
  evals <- soilDB::uncode(evals, stringsAsFactors = FALSE)
  properties <- soilDB::uncode(properties, stringsAsFactors = FALSE)
  
  # treat property IDs as characters
  evals$propiid <- as.character(evals$propiid)
  properties$propiid <- as.character(properties$propiid)
  property_def$propiid <- as.character(property_def$propiid)
  
  ## TODO: maybe useful to keep the split?
  # there is only 1 property / evaluation, so join them
  evals <- merge(evals, properties, by='propiid', all.x=TRUE, sort=FALSE)
  
  # save tables for offline testing
  save(rules, evals, properties, property_def, file='cached-NASIS-data.Rda')
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

### extract eval functions ####

## TODO: return function and critical points as a list

# dispatch specialized functions based on eval type
# x: evaluation record
# res: number of intermediate points
#' Extract an evaluaton curve
#'
#' @param evalrec Evaluation record
#' @param resolution Number of intermediate points
#' @param sig.scale default 1
#'
#' @return evaluation curve values
#' @export
extractEvalCurve <- function(evalrec, resolution=250, sig.scale = 1) { ### edited default resolution 12/11 ### added sig.scale param 2/18
  
  # type
  et <- evalrec$evaluationtype
  # invert
  invert.eval <- evalrec$invertevaluationresults
  
  
  ## TODO: this isn't finished, currently using linear interpolation
  # shoudl be some kind of spline interpolation, splinefun() isn't working
  if(et  == 'ArbitraryCurve') {
    res <- extractArbitraryCurveEval(evalrec$eval, invert=invert.eval)
    return(res)
  }
  
  # linear interpolation
  if(et  == 'ArbitraryLinear') {
    res <- extractArbitraryLinearCurveEval(evalrec$eval, invert=invert.eval)
    return(res)
  }
  
  if(et == 'Sigmoid') {
    res <- extractSigmoidCurveEval(evalrec$eval, invert=invert.eval, res = resolution, sig.scale = sig.scale)
    return(res)
  }
    
  if(et == 'Crisp') {
    
    ## need a reliable characteristic to use another approach
    # some crisp evaluations are logical expressions that don't utilize thresholds
    if(is.na(evalrec$propmin) & is.na(evalrec$propmax)) {
      res <- extractCrispExpression(evalrec$eval, invert=invert.eval)
      warning("Evaluating CrispExpression (", attr(res, "CrispExpression"),") has only experimental support", call. = FALSE)
      return(res)
      # return(function(evalrec) {return(NULL)})
    }
    
    # use the defined min / max values
    domain.min <- evalrec$propmin
    domain.max <- evalrec$propmax
    
    res <- extractCrispCurveEval(evalrec$eval, invert=invert.eval, resolution, dmin=domain.min, dmax=domain.max)
    return(res)
  }
  
  if(et == 'Linear') {
    res <- extractLinearCurveEval(evalrec$eval, invert=invert.eval, res = resolution)
    return(res)
  }
  
  if(et == 'Trapezoid') {
    res <- extractTrapezoidEval(evalrec$eval, invert=invert.eval)
    return(res)
  }
  
  ## ... there are many others
#   Beta
#   IsNull
#   Gauss
#   Triangle
#   PI
  warning("extractEvalCurve: curve type not yet supported", call. = FALSE)
  return(function(evalrec) {return(NULL)})
}


#' Extract Trapeziodal Eval Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
#'
#' @importFrom stats approxfun
extractTrapezoidEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  # rating is fixed at 0 -> 1 -> 1 -> 0 along trapezoid from left to right
  rating <- c(0, 1, 1, 0)
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
    yl = 1
    yr = 0
  } else {
    yl = 0
    yr = 1
  }
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2, yleft = yl, yright = yr)
  return(af)
}


#' Extract Arbitrary Eval Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
#'
#' @importFrom stats approxfun
extractArbitraryCurveEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
    yl = 1
    yr = 0
  } else {
    yl = 0
    yr = 1
  }
  
  ## TODO: this should be a spline-based interpolator (?)
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2, yleft = yl, yright = yr)
  return(af)
}

#' Extract Arbitrary Linear Eval Curve
#'
#' @param x  evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
#'
#' @importFrom stats approxfun
extractArbitraryLinearCurveEval <- function(x, invert) {
  l <- xmlChunkParse(x)
  # exract pieces
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
    yl = 1
    yr = 0
  } else {
    yl = 0
    yr = 1
  }
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2, yleft = yl, yright = yr)
  return(af)
}

#' Extract Sigmoid Eval Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#' @param res number of intermediate points
#' @param sig.scale default 1
#'
#' @return curve function
#' @export
#' @importFrom stats plogis
#' @importFrom stats approxfun
extractSigmoidCurveEval <- function(x, invert, res, sig.scale = NULL) {
  
  if (!missing(sig.scale))
    .Deprecated(msg = "sig.scale argument is now calculated from the width of the domain (difference of upper and lower asymptotes)")
  
  ### test in global params because bad programmer
  # if(1==0){
  #   evalxml <- t$evalrow$eval
  #   res <- 51
  #   invert <- t$evalrow$invertevaluationresults
  # }
  
  l <- xmlChunkParse(x)
  
  # get the lower and upper asymptotes
  dp <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
    # ### added jrb 2021-02-16 in response to sigmoid curves sometimes having weird breaks between the fuzz space and the fixed val space
  # # if the domain starts at a whole number, adjust it to start at a slightly wider range, that overlaps with hard space
  # if(dp[1]%%1 == 0){
  #   dp[1] <- dp[1] - 0.01
  # }
  # if(dp[2]%%1 == 0){
  #   dp[2] <- dp[2] + 0.01
  # }
  #### but it doesnt work
  
  # generate a sequence along domain
  domain <- seq(from = dp[1], to = dp[2], length.out = 1001)

  # create sigmoid curve
  sig.loc <- (dp[1] + dp[2]) / 2 # location parameter is center of range
  
  #sig.scale <- 1 #### THIS NEEDS TO VARY WITH THE FUNCTION, NOT DEFAULT TO 1!! 
  ## No idea how to fit this to so many difft eval functions, so now its an input param passed aaaallll the way up to evalbyeid
  
  # AGB 2021/12/29: the scale factor needs to vary with the width of the domain
  #                 at dp[1] curve value is 0 and dp[2] curve value is 1
  .scaleLogistic <- function(domain_width) { 
    # determined empirically by reading values off various width sigmoid curves
    # and finding optimal scale parameter for each width 
    # _after_ accounting for [0,1] rescaling of limits
    # after 3 sets of 5 X/Y pairs the pattern was evident
    0.14320552 * domain_width - 0.00254715 
  }
  
  rating <- plogis(domain, location = sig.loc, scale = .scaleLogistic(dp[2] - dp[1]))
  
  # rescale to [0,1]
  rating <- rating - min(rating) 
  rating <- rating / max(rating)
           
  ## not sure about this, can it happen?
  #   # if the first value is > second, then swap direction
  #   if(dp[2] < dp[1])
  #     rating <- 1 - rating

  # invert?
  if(invert == 1)
    rating <- (1 - rating) 
  
  if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
    yl = 1
    yr = 0
  } else {
    yl = 0
    yr = 1
  }
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2, yleft = yl, yright = yr)
  return(af)
}

#' Extract Linear Evaluation Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#' @param res number of intermediate points
#'
#' @return curve function
#' @export
#' 
#' @importFrom stats approxfun
extractLinearCurveEval <- function(x, invert, res) {
  l <- xmlChunkParse(x)
  # get the lower and upper end points
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
  # rating is implied: {0,1}
  rating <- c(0,1)
  ## changed 2/22 to get the range points out of 'l'
  # rating <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # invert?
  if(invert == 1)
    rating <- (1 - rating)
  
  ### this is never used????
  # if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
  #   yl = 1
  #   yr = 0
  # } else {
  #   yl = 0
  #   yr = 1
  # }
  
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2)
  return(af)
}

## TODO: breaks on eval "GRL-Frost Action = moderate"
## TODO: parsing expression must be generalized
## TODO: this doesn't work with expressions like this "!= \"oxisols\" or \"gelisols\""
#' Extract Crisp Evaluation Curve
#'
#' @param x evalulation curve XML text
#' @param invert logical
#' @param res number of intermediate points
#' @param dmin domain range minimum 
#' @param dmax domain range maximum
#'
#' @return curve function
#' @export
#'
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
  
  if (rating[1] > rating[length(rating)]){ # added this to hopefully fix errors where the left and right sides have the wrong vals
    yl = 1
    yr = 0
  } else {
    yl = 0
    yr = 1
  }
  # create interpolator
  af <- approxfun(domain, rating, method = 'linear', rule=2, yleft = yl, yright = yr)
  return(af)
}

#' Extract Crisp Expression Logic as R function
#'
#' @param x evaluation XML content containing a CrispExpression
#' @param invert invert logic with `!`? Default: `FALSE`
#' @param asString return un-parsed function (for debugging/inspection) Default: `FALSE`
#'
#' @return a generated function of an input variable `x` 
#' @details The generated function returns a logical value (converted to numeric) when the relevant property data are supplied.
#' @export
#'
#' @examples
extractCrispExpression <- function(x, invert = FALSE, asString = FALSE) {
  l <- xmlChunkParse(x)
  expr <- l$CrispExpression
  if (length(expr) == 0) expr <- ""
  .crispExpressionGenerator(expr, invert = invert, asString = asString)
}

.crispExpressionGenerator <- function(x, invert = FALSE, asString = FALSE) {
  # wildcards matches/imatches
  step1 <- gsub("i?matches \"([^\"]*)\"", "grepl(\"^\\1$\", x, ignore.case = TRUE)", 
                gsub("\" or i?matches \"", "$|^", x, ignore.case = TRUE), ignore.case = TRUE)
  step2 <- gsub("*", ".*", step1, fixed = TRUE)
  
  # (in)equality  
  step3 <- gsub(" x  grepl", "grepl", gsub("^([><=]*) ?(\")?|(and|or) ([><=]*)? ?(\")?", "\\3 x \\1\\4 \\2\\5", step2))
  
  # convert = to ==
  step4 <- gsub("x =? ", "x == ", gsub("\" ?(, ?| or ?)\"", "\" | x == \"", step3, ignore.case = TRUE))
  
  # convert and/or to &/|
  expr <- trimws(gsub(" or ", " | ", gsub(" and ", " & ", step4)))
  
  # various !=
  expr <- gsub("== != \"|== not \"", "!= \"", expr, ignore.case = TRUE)
  expr <- gsub("== \"any class other than ", "!= \"", expr)
  
  # final matches
  expr <- gsub("== MATCHES ", "== ", expr, ignore.case = TRUE)
  
  # many evals just return the property
  expr[expr == "x =="] <- "x"
  
  # logical expression, possibly inverted, then converted to numeric (0/1)
  # TODO: handle NA via na.rm/na.omit, returning attribute of offending indices
  res <- sprintf("function(x) { as.numeric(%s(%s)) }", 
                           ifelse(invert, "!", ""), expr)
  if (asString) return(res)
  res <- eval(parse(text = res))
  attr(res, 'CrispExpression') <- x
  res
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
  n <- FromListExplicit(l$RuleStart, nameName=NULL, childrenName='Children')
  
  # copy interp name to top of tree
  n$name <- x$rulename
  
  return(n)
}



## TODO: splice/prune issues
#' Link Subrules
#'
#' @param node a data.tree node
#'
#' @return a (modified) data.tree?
#' @export
#'
linkSubRules <- function(node) {
  
  rules <- InterpretationEngine::NASIS_rules
  
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
#' Link Evaluation Functions
#'
#' @param node a data.tree node
#'
#' @return a (modified) data.tree?
#' @export
#'
linkEvaluationFunctions <- function(node) {
  evals <- InterpretationEngine::NASIS_evaluations  
  
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
    f <- try(extractEvalCurve(ev), silent = FALSE)
    if(class(f) != 'try-error') {
      node$evalFunction <- f
    }
    
    ## come back and figure out what is wrong in evalXXX function
    else
      node$evalFunction <- function(x) return(NULL)
  }
}



#### adding hsg, svi, vf, and dwb functions ## jrb 03-19-21 ####

# require(parallel)
# require(data.tree)
# require(foreach)
# require(doParallel)

#' Evaluate a tree
#'
#' @param tree tree is a data tree object structured with classifications as leaves above those, all nodes must contain these attributes: "var", specifying the variable name to evaluate, "logical", specifying the logical evaluation at that step. MUST INCLUDE THE SAME VARIABLE "VAR"
#' @param indata data must be a data frame containing columns with names matching all the values of "var" used in the tree object
#' @param ncores number of cores to parallelize over. if set to 1 (default), runs sequentially. Also accepts "auto" as input. Will run with ncores on computer - 2.
#'
#' @author Joseph Brehm
#' @return eval result TODO
#' 
#' @export
#' @aliases hsg_calc svi_calc
#' @importFrom raster as.data.frame
#' @importFrom data.tree isLeaf
#' @importFrom parallel detectCores stopCluster
#' @importFrom foreach foreach registerDoSEQ %dopar%
#' @importFrom doParallel registerDoParallel 
tree_eval <- function(
  tree,
  indata,
  ncores = 1
){
  ### data pre-processing 
  
  # if class is raster brick, convert it to a dataframe. Calc may be faster though???
  ## does this work with stacks?
  inclass <- class(indata)[1]
  
  # remove the all-na rows
  ## this might need to go away, check what it does to raster data
  
  if (inclass %in% c("RasterBrick", "RasterStack")) {
    prepdata <- raster::as.data.frame(indata)
    prepdata <- prepdata[rowSums(is.na(prepdata)) != ncol(prepdata), ]
    
  } else {
    prepdata <- indata[rowSums(is.na(indata)) != ncol(indata), ]
  }
  #### last minute patch 3/19. Fix the above lines, something is very wrong there
  prepdata <- indata
  ###
  
  ### set up paralellization
  # auto core counting: use n cores in computer, minus 2
  if(ncores == "auto") {
    if(parallel::detectCores() == 2) { # just in case there's a dual core machine out there
      ncores = 1
    } else {
      ncores <- parallel::detectCores() - 2
    }
  }
  
  # check if user requested too many cores for the machine
  if(ncores > parallel::detectCores()){
    stop(cat("Cannot run with", ncores, "cores as your computer only has", parallel::detectCores()))
  } 
  
  # register sequential or parallel backend, depending on ncores 
  if (ncores > 1) {
    cat("Running parallel with", ncores, "cores")
    cl <- parallel::makeCluster(ncores)
    doParallel::registerDoParallel()
  } else {
    cat("Running sequentially")
    foreach::registerDoSEQ()
  }
  
  
  ### do the thing!
  
  outlist <- foreach(
    row = 1:nrow(prepdata),
    .packages = "data.tree"
  ) %dopar% {    
    
    # start at the root node
    node = tree$root
    
    # descend through the tree until arriving at an end node
    while(!isLeaf(node))  {
      
      # extract the name of the variable to evaluate
      varname = node$nextvar
      
      # check to see if its in the input data
      if(!(varname %in% colnames(prepdata))) {
        stop(paste(varname, "must be a column name in input data"))
      }
      
      # extract the value
      value = prepdata[row,varname]
      
      # if the value is na, this point can't be evaluated due to missing data unless there is a check for NA's in the logic set
      if(is.na(value) & !grepl("is.na", node$nextlogical)) return(NA)
      
      # change the logical string to use the generic 'value' instead of the specified variable name
      # specific variable names are used in the tree objects for readability
      lstr = gsub(varname, "value", node$nextlogical)
      
      # go from the semicolon delimited list of logicals to a vector
      v.lstr <- unlist(strsplit(lstr, split = ";"))
      
      # evaluate them all
      v.bool <- sapply(v.lstr, function(l){eval(parse(text = l))})
      
      # which is true?
      pathno <- which(v.bool)
      
      # if 0 or >1 paths are true, there is an error in the tree
      if(length(pathno) != 1){
        stop(paste0(
          "Node '", node$pathString, "' has ", sum(v.bool), " solutions, should be 1"
        ))
      }
      
      # if there are more logicals to evaluate than there are children, there is an error in the tree
      if(length(v.bool) > length(node$children)) {
        stop(paste0(
          "Node '", node$pathString, "' has ", length(v.bool), " logical statements but ", length(node$children), " children"
        ))
      }
      
      # otherwise, take that path
      node = node$children[[pathno]]
    } # loop back to evaluate the new node now -- or exit, if its a leaf
    
    return(node$result)
  }
  
  if(ncores > 1) parallel::stopCluster(cl)
  
  out <- unlist(outlist)
  
  if(inclass %in% c("RasterBrick", "RasterStack")) {
    
    if(class(out) == "character") out <- factor(out)
    
    r.out <- indata[[1]]
    r.out[!is.na(r.out)] <- out
    
    return(r.out)
  } else {
    return(out)
  }
  
  
}

#' @export
hsg_calc <- function(indata, ncores = 1) {
  
  tree_eval(tree = InterpretationEngine::datatree_hsg,
            indata = indata,
            ncores = ncores)
}

#' @export
svi_calc <- function(indata, ncores = 1) {
  
  tree_eval(tree = InterpretationEngine::datatree_svi,
            indata = indata,
            ncores = ncores)
}

### vf
# require(tidyverse)
# require(soilDB)
# require(XML)
# require(digest)

#' Valley Fever 
#'
#' @param indata input data
#' @param doxeric force xeric or nonxeric function, or let it choose for each data row/pixel depending on an input raster (accepts "auto" / "xeric" / "nonxeric")
#' @author Joseph Brehm
#' @return evaluation result
#' @export
#' @importFrom dplyr select `%>%` if_else
#' @importFrom raster setValues brick
#' @importFrom tidyr replace_na
vf_calc <- function(indata, 
                    doxeric = "auto" # 
){ 
  if(!(doxeric %in% c("auto", F, T))){
    print("Unknown input for xeric parameter, which determines whether to process data as xeric or nonxeric conditions")
    print("Accepted input is 'auto', 'T' (process all as xeric), or 'F' (process all as nonxeric).")
    print("Defaulting to auto. This requires data specifying conditions by data point, and will error if not provided")
    doxeric <- "auto"
  }
  
  # if a raster stack or brick is provided as input, the output will be a raster brick
  rasterinput <- class(indata)[1] %in% c("RasterStack", "RasterBrick")
  
  if(rasterinput) {
    # require(raster)
    r.template <- indata[[1]] # save the first raster in the obj as a template to create an out raster later
    indata <- as.data.frame(indata)
  }
  
  outdata <- indata[,'xeric',drop=FALSE]
  
  ## 1 - chemical subrule
  
  outdata$fuzzsar <- evalbyeid(42999, indata$sar, sig.scale = 5) %>% replace_na(0)
  outdata$fuzzgypsumcontent <- evalbyeid(42991, indata$gypsumcontent) ^ (0.5) %>% replace_na(0)
  
  
  outdata$fuzzec <- evalbyeid(43000, indata$ec) %>% replace_na(0)
  outdata$fuzzph <- evalbyeid(42985, indata$ph, sig.scale = 0.125) %>% replace_na(0)
  
  outdata$fuzzchem <- 
    do.call(pmax, c(outdata[,c('fuzzsar', 'fuzzec', 'fuzzgypsumcontent', 'fuzzph')], na.rm = T))
  
  ## 2 - climatic subrule
  if(!("xeric"  %in% colnames(indata))) indata$xeric <- NA
  if(doxeric != "auto"){
    if(doxeric) {indata$xeric <- 1}
    if(!doxeric) {indata$xeric <- 0}
  }
  
  outdata$fuzzprecipX <- evalbyeid(42997, indata$map)
  outdata$fuzzprecipNX <- evalbyeid(42998, indata$map)
  
  outdata$fuzzalbedo <- evalbyeid(43047, 1 - indata$albedo)
  
  indata$aspectfactor = if_else( ## this is translated from cvir "VALLEY FEVER ASPECT FACTOR", property 35987
    is.na(indata$aspect), 0,
    if_else(
      indata$aspect >= 0 & indata$aspect < 0, 0,
      if_else(
        indata$aspect >= 80 & indata$aspect < 280, -((indata$aspect-180)**2)/9000+1,
        0 # if all false
      )
    )
  )
  
  outdata$fuzzslopeheatload <- evalbyeid(43048, indata$slope)
  outdata$fuzzaspect <- evalbyeid(43049, indata$aspectfactor)
  outdata$fuzzheatingfactor <- 
    outdata$fuzzalbedo *
    outdata$fuzzslopeheatload *
    outdata$fuzzaspect
  
  
  outdata$airtempchopperX <- indata$airtemp / 16
  outdata$airtempchopperNX <- indata$airtemp / 18.5
  
  outdata$fuzzsurftempX <- evalbyeid(43050, outdata$airtempchopperX)
  outdata$fuzzsurftempNX <- evalbyeid(43051, outdata$airtempchopperNX) 
  
  outdata$fuzzairtempX <- evalbyeid(42995, indata$airtemp)
  outdata$fuzzairtempNX <- evalbyeid(42996, indata$airtemp)
  
  ### combine all the x/nx rows together
  outdata$fuzzprecip <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzprecipX,
      outdata$fuzzprecipNX
    )
  
  outdata$fuzzsurftemp <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzsurftempX,
      outdata$fuzzsurftempNX
    )
  
  outdata$fuzzairtemp <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzairtempX,
      outdata$fuzzairtempNX
    )
  
  outdata$fuzzclimate <- 
    (outdata$fuzzheatingfactor * outdata$fuzzsurftemp + outdata$fuzzairtemp) * outdata$fuzzprecip
  
  ## 3 others 
  outdata$fuzzwrd <- evalbyeid(42987, indata$wrd, sig.scale = 2)
  outdata$fuzzwatergatheringsurface <- evalbyeid(42988, sqrt(indata$watergatheringsurface))
  outdata$fuzzom <- evalbyeid(42990, indata$om)
  
  outdata$fuzzsaturation <- evalbyeid(63800, indata$saturationmonths)
  outdata$fuzzflood <- evalbyeid(63801, indata$floodmonths) #### this is not used?
  outdata$fuzzsurfsat <- 
    do.call(pmin, c(outdata[,c('fuzzsaturation', 'fuzzflood')], na.rm = T))
  
  ## 4 combine all the subrules
  outdata$fuzzvf <- 
    sqrt(
      sqrt(outdata$fuzzwrd) * 
        sqrt(outdata$fuzzwatergatheringsurface) * 
        sqrt(outdata$fuzzom) * 
        sqrt(outdata$fuzzsurfsat) *
        outdata$fuzzclimate * 
        outdata$fuzzchem) /
    0.95
  
  # in rare cases, this can be more than 1 (highest val seen in testing was 1.026)
  # clamp it, for data quality & appearance (this should not have meaningful changes. If it does, there is an error here somewhere)
  outdata[outdata$fuzzvf > 1 & !is.na(outdata$fuzzvf), "fuzzvf"] <- 1
  
  classbreaks <- c(0, 0.1, 0.2, 0.5, 0.8, 1)
  classlabels <- c("Not suitable", "Somewhat suitable", "Moderately suitable", "Suitable", "Highly suitable")
  
  outdata$vf <- base::cut(outdata$fuzzvf, breaks = classbreaks, labels = classlabels, right = TRUE, include.lowest = T)
  
  # outdata <- 
  #   outdata %>%
  #   mutate(cokey = as.character(cokey),
  #          coiid = as.character(coiid),
  #          mukey = as.character(mukey))
  
  ## all fuzzy values are returned, as is the column for the maximum fuzzy score, and the final classification
  ## if the input was a raster stack or brick, the output will be a small 2 layer brick instead of the df
  if(rasterinput){
    vf <- r.template %>%
      setValues(factor(outdata$vf),
                levels = rev(classlabels))
    fuzzvf <- r.template %>%
      setValues(outdata$fuzzvf)
    
    outdatabrk <- brick(vf, fuzzvf)
    outdata <- outdatabrk
    names(outdata) <- c("vf", "fuzzvf")
    
  }
  
  return(outdata)
}

## dwb
#' Dwewllings Without Basements
#'
#' @param indata Input data
#'
#' @return evaluation result
#' @export
#' @importFrom dplyr select `%>%` if_else
#' @importFrom tidyr replace_na
#' @importFrom raster brick setValues
dwb_calc <- function(indata){
  
  # this works on a data frame. 
  # if a raster stack or brick is passed as input, it will convert to df
  
  rasterinput <- class(indata)[1] %in% c("RasterStack", "RasterBrick")
  #print(rasterinput)
  if(rasterinput) {
    r.template <- indata[[1]] # save the first one as a template to create an out raster later
    indata <- as.data.frame(indata)
  }
  
  outdata <- indata[,0] # this makes an empty data frame with the correct num of rows
  
  # 1 - depth to permafrost
  outdata$fuzzpermdepth <-
    pmax(
      evalbyeid(10356, indata$permdepth) %>% replace_na(0), ### case 1: fuzzy logic eval
      indata$pftex %>% as.integer() %>% replace_na(0) # T when there is a pf code in either texinlieu or texmod      
    )
  
  # 2 - ponding duration
  outdata$fuzzpond <- 
    indata$ponding %>% as.integer() %>% replace_na(0)
  
  # 3 - slope
  outdata$fuzzslope <- evalbyeid(10125, indata$slope_r) #%>% replace_na(0) # null goes to NR
  
  # 4 - subsidence(cm)
  # this is secretly a crisp eval
  outdata$fuzzsubsidence <- as.numeric(as.numeric(indata$totalsub_r) >= 30) %>% replace_na(0)
  
  # 5 - flooding frequency
  outdata$fuzzfloodlim <- 
    indata$flooding %>% as.integer() %>% replace_na(0)
  
  # 6 - depth to water table
  outdata$fuzzwt <- evalbyeid(299, indata$wt) %>% replace_na(0)
  
  # 7 - shrink-swell
  outdata$fuzzshrinkswell <- evalbyeid(18502, indata$lep) %>% replace_na(0)
  
  # 8 - om content class of the last layer above bedrock / deepest layer
  outdata$fuzzomlim <- 
    indata$organicsoil %>% as.integer() %>% replace_na(0)
  
  # 9 - depth to bedrock (hard)
  outdata$fuzzdepbrockhard <- evalbyeid(18503, indata$depbrockhard) %>% replace_na(0)
  
  # 10 - depth to bedrock (soft)
  outdata$fuzzdepbrocksoft <- evalbyeid(18504, indata$depbrocksoft) %>% replace_na(0)
  
  # 11 - large stone content
  outdata$fuzzlgstone <- evalbyeid(267, indata$fragvol_wmn) # %>% replace_na(0) #### null goes to not rated
  
  # 12 - depth to cemented pan (thick)
  outdata$fuzzdepcementthick <- evalbyeid(18505, indata$depcementthick) %>% replace_na(0) ### the fuzzy space here is not whats in the notes
  #outdata$fuzzdepcementthick[indata$noncemented] <- 0
  
  # 13 - depth to cemented pan (thin)
  outdata$fuzzdepcementthin <- evalbyeid(18501, indata$depcementthin) %>% replace_na(0)
  #outdata$fuzzdepcementthin[indata$noncemented] <- 0
  
  # 14 - unstable fill
  outdata$fuzzunstable <- 
    indata$unstablefill %>% as.integer() %>% replace_na(0)
  
  # 15 - subsidence due to gypsum
  outdata$fuzzgypsum <- evalbyeid(16254, indata$gypsum) # %>% replace_na(0) ## null to not rated
  
  # 16 impaction
  outdata$fuzzimpaction <- 
    indata$impaction %>% as.integer() %>% replace_na(0)
  
  # 17 drainage class
  outdata$fuzzdrainage <- (indata$drainageclass != 1) %>% as.integer() %>% replace_na(0)
  
  ### aggregate, returning the highest fuzzy value (ie, most limiting variable) and classifying based on it
  firstcol <- which(colnames(outdata) == "fuzzpermdepth")
  lastcol <- which(colnames(outdata) == "fuzzdrainage")
  
  outdata$maxfuzz <- do.call(pmax, c(outdata[,firstcol:lastcol], na.rm = T))
  
  outdata$dwb <- 
    if_else(outdata$maxfuzz == 1, 
            "Very limited",
            if_else(outdata$maxfuzz == 0, 
                    "Not limited",
                    "Somewhat limited"))
  
  ## all fuzzy values are returned, as is the column for the maximum fuzzy score, and the final DWB classification
  
  ## if the input was a raster stack or brick, the output will be a small 2 layer brick instead of the df
  if(rasterinput){
    
    ## this used to work. now it doesnt. export
    dwb <- r.template %>%
      setValues(factor(outdata$dwb),
                levels = rev(c("Not limited", "Somewhat limited", "Very limited")))

    # dwb <- r.template %>% 
    #   setValues(outdata$dwb)
    
    
    
    fuzzdwb <- r.template %>%
      setValues(outdata$maxfuzz)
    
    outdata <- brick(dwb, fuzzdwb)
    names(outdata) <- c("dwb", "maxfuzz")
  }
  
  
  return(outdata)
}


