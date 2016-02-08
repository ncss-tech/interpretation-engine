library(soilDB)
library(RODBC)
library(XML)
library(plyr)
library(data.tree)
library(igraph)

## TODO: add support for inverted results

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

## too messy
# fixNodeNames <- function(l) {
#   l.names <- names(l$Children)
#   if(length(l.names) > 1) {
#     for(i in seq_along(l.names))
#       l.i <- l$Children[i]
#       # tabulate objects
#       tab <- table(l.names) 
#     
#   }
# }

# TOOD: this function will need to traverse arbitrarily complex rule trees
parseRule <- function(x) {
  # parse XML block into list
  l <- xmlChunkParse(x)
  
  # convert XML list into data.tree object
  n <- FromListExplicit(l$RuleStart, nameName=NULL, childrenName='Children')
  
  # ideas: https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html#introduction
  
  # enumerate duplicate elements
  # http://stackoverflow.com/questions/33460954/adding-numbers-to-each-node-in-data-tree
  # n$Set(name = paste0(n$Get("name"), "_", 1:n$totalCount))
  
  
  # asked here: http://stackoverflow.com/questions/35278342/recursively-assign-unique-names-to-nodes-in-a-data-tree-object
  
  # single operator, get type
  n$RuleOperator$Type
  
  # rule hedges
  n$RuleHedge$Type
  n$RuleHedge$Value
  
  # sub-rules aren't uniquely named, so they must be iterated over numerically
  print(sapply(n$RuleOperator$Children, function(i) i$RefId))
  
  return(n)
}



# init connection
channel <- odbcDriverConnect(connection = "DSN=nasis_local;UID=NasisSqlRO;PWD=nasisRe@d0n1y")

### 
### get rules
###
rules <- sqlQuery(channel, "SELECT * from rule_View_0 WHERE dataafuse = 1", stringsAsFactors=FALSE)


# check some
y <- rules[rules$rulename == 'AGR - California Revised Storie Index (CA)', ]
parseRule(y$rule)

y <- rules[rules$rulename == 'Clay %, in surface - MO2', ]
parseRule(y$rule)

y <- rules[rules$rulename == 'DHS - Catastrophic Mortality, Large Animal Disposal, Pit', ]
parseRule(y$rule)





# ruleRatingClass <- sqlQuery(channel, "SELECT * from ruleratingclass_View_0", stringsAsFactors=FALSE)




###
### get evaluation curves, need to join in metadata to convert most columns from codes -> values
###


# this table has the evaluation curve data
sqlColumns(channel, 'evaluation_View_0')


# rule -> rule -> evalution(property)

## ideally, the parsing of a rule would return a function or list of functions for converting domain values into fuzzy values and classes

# get all evaluation curves
evals <- sqlQuery(channel, "SELECT evalname, evaldesc, eval, et.ChoiceName as evaluationtype, invertevaluationresults
FROM evaluation_View_0 
LEFT OUTER JOIN (SELECT * FROM MetadataDomainDetail WHERE DomainID = 4884) AS et ON evaluationtype = et.ChoiceValue", stringsAsFactors=FALSE)

## arbitrary curve: example: Storie Index C factor 
idx <- grep('storie factor c', evals$evalname, ignore.case = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractArbitraryCurveEval(y$eval)
plot(0:200, res(0:200), type='l', xlab='domain', ylab='fuzzy rating', main='Arbitrary Curve')

## sigmoid: "SAR, <.5, 0-100cm (0 to 40")"
idx <- grep('SAR, <.5, 0-100cm (0 to 40")', evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractSigmoidCurveEval(y$eval)
plot(0:13, res(0:13), type='l', xlab='domain', ylab='fuzzy rating', main='Sigmoid Curve')

## arbitrary linear
idx <- grep("GRL - EC maximum in depth 25 to 50 cm (NV)", evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractArbitraryCurveEval(y$eval)
plot(0:25, res(0:25), type='l', xlab='domain', ylab='fuzzy rating', main='Arbitrary Linear Curve')

## crisp: "Soil pH (water) >= 4.5 and <= 8.4, 0-100cm"
idx <- grep('Soil pH (water) >= 4.5 and <= 8.4, 0-100cm', evals$evalname, fixed = TRUE)
y <- evals[idx, ]
# extract arbitrary curve type and plot
res <- extractCrispCurveEval(y$eval)
plot(0:14, res(0:14), type='l', xlab='domain', ylab='fuzzy rating', main='Crisp Curve')





