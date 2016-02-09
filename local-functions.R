

# parse evaluation chunk XML and return as list
xmlChunkParse <- function(x) {
  # replace bogus encoding
  x <- gsub('utf-16', 'utf-8', x)
  # parse and convert to list
  x.doc <- xmlParse(x)
  l <- xmlToList(x.doc)
  return(l)
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
extractSigmoidCurveEval <- function(x, res=25) {
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
extractCrispCurveEval <- function(x, res=25) {
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

# seems to work
fixNodeNames <- function(l) {
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
        l$Children[[idx[this.element]]] <- fixNodeNames(l.sub)
      }
    }
  }

  return(l)
}


# attempt to convert interpretation rule into data.tree representation
parseRule <- function(x) {
  
  # parse XML block into list
  l <- xmlChunkParse(x$rule)
  
  # node names must be made unique before data.tree object/methods are useful
  l$RuleStart$Children$RuleOperator <- fixNodeNames(l$RuleStart$Children$RuleOperator)
  
  # convert XML list into data.tree object
  n <- FromListExplicit(l$RuleStart, nameName=NULL, childrenName='Children')
  
  # copy interp name to top of tree
  n$name <- x$rulename
  
  # ideas: https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html#introduction
  
  # enumerate duplicate elements
  # http://stackoverflow.com/questions/33460954/adding-numbers-to-each-node-in-data-tree
  # n$Set(name = paste0(n$Get("name"), "_", 1:n$totalCount))
  
  
  # asked here: http://stackoverflow.com/questions/35278342/recursively-assign-unique-names-to-nodes-in-a-data-tree-object
  
#   # single operator, get type
#   n$RuleOperator$Type
#   
#   # rule hedges
#   n$RuleHedge$Type
#   n$RuleHedge$Value
  
  # sub-rules aren't uniquely named, so they must be iterated over numerically
  # print(sapply(n$RuleOperator$Children, function(i) i$RefId))
  
  return(n)
}

