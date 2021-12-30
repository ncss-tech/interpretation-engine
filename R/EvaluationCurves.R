# This file contains functions for extracting interpolation functions for different Evaluation curves
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
extractEvalCurve <- function(evalrec, resolution=250, sig.scale = 1) {
  if (!missing(resolution))
    .Deprecated(msg = "extractEvalCurve resolution argument is no longer used") 
  
  if (!missing(sig.scale))
    .Deprecated(msg = "extractEvalCurve sig.scale argument is no longer used")
  
  # type
  et <- evalrec$evaluationtype
  
  # invert
  invert.eval <- evalrec$invertevaluationresults
  
  # use the defined min / max values (if any)
  domain.min <- evalrec$propmin
  domain.max <- evalrec$propmax
  
  # should be some kind of spline interpolation, splinefun() isn't working
  # 
  # AGB 2021/12/30: now uses the same spline functions defined in NASIS
  if (et  == 'ArbitraryCurve') {
    res <- extractArbitraryCurveEval(evalrec$eval, invert=invert.eval)
    return(res)
  }
  
  # linear interpolation
  if (et  == 'ArbitraryLinear') {
    res <- extractArbitraryLinearCurveEval(evalrec$eval, invert = invert.eval)
    return(res)
  }
  
  if (et == 'Sigmoid') {
    # sig.scale is deprecated, scaling can be determined from width of interval
    res <- extractSigmoidCurveEval(evalrec$eval, 
                                   xlim = c(domain.min, domain.max),
                                   invert = invert.eval)
    return(res)
  }
  
  if (et == 'Crisp') {
    
    # some crisp are logical expressions that don't utilize thresholds of domain
    if(is.na(domain.min) & is.na(domain.max)) {
      res <- extractCrispExpression(evalrec$eval, invert = invert.eval)
      
      warning("Evaluating CrispExpression (", attr(res, "CrispExpression"),") has only experimental support", call. = FALSE)
      
      return(res)
    }
    
    res <- extractCrispCurveEval(
      evalrec$eval,
      xlim = c(domain.min, domain.max),
      invert = invert.eval
    )
    return(res)
  }
  
  if (et == 'Linear') {
    res <- extractLinearCurveEval(evalrec$eval, invert = invert.eval) 
    return(res)
  }
  
  if (et == 'Trapezoid') {
    res <- extractTrapezoidEval(evalrec$eval,
                                xlim = c(domain.min, domain.max),
                                invert = invert.eval)
    return(res)
  }
  
  if (et == "Beta") {
    res <- extractBetaCurveEval(
      evalrec$eval,
      xlim = c(domain.min, domain.max),
      invert = invert.eval
    )
    return(res)
  }
  
  if (et == "Gauss") {
    res <- extractGaussCurveEval(
      evalrec$eval,
      xlim = c(domain.min, domain.max),
      invert = invert.eval
    )
    return(res)
    
  }
  
  if (et == "Triangle") {
    res <- extractTriangleCurveEval(
      evalrec$eval,
      xlim = c(domain.min, domain.max),
      invert = invert.eval
    )
    return(res)
  }
  
  if (et == "PI") {
    res <- extractPICurveEval(
      evalrec$eval,
      xlim = c(domain.min, domain.max),
      invert = invert.eval
    )
    return(res)
  }
  
  ## ... there are others
  #   IsNull -- not needed? / not a curve?
  
  warning("extractEvalCurve: curve type not yet supported", call. = FALSE)
  return(function(evalrec) {return(NULL)})
}


#' Extract Trapezoidal Eval Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
#'
#' @importFrom stats approxfun
extractTrapezoidEval <- function(x, xlim, invert = FALSE) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRTrapezoid, invert = invert)
}

#' Extract Arbitrary Eval Curve
#'
#' @param x evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
#'
extractArbitraryCurveEval <- function(x, invert) {
  .genericInterpolator(x, xlim = NULL, FUN = NULL, invert = invert)
  # ## TODO: this should be a spline-based interpolator (?)
}

#' Extract Arbitrary Linear Eval Curve
#'
#' @param x  evaluation curve XML text
#' @param invert logical
#'
#' @return curve function
#' @export
extractArbitraryLinearCurveEval <- function(x, invert) {
  .genericInterpolator(x, xlim = NULL, FUN = NULL, invert = invert)
}

#' Extract Sigmoid Eval Curve
#'
#' @param x evaluation curve XML text
#' @param xlim domain range minimum/maximum
#' @param invert logical
#'
#' @return curve function
#' @export
extractSigmoidCurveEval <- function(x, xlim, invert) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRSigmoid, invert = invert)
}

extractLinearCurveEval <- function(x, invert) {
  .genericInterpolator(x, xlim = NULL, FUN = CVIRLinear, invert = invert)
}

extractCrispCurveEval <- function(x, xlim, invert = FALSE) {
  # this supports crispexpressions involving "domain"
  .genericInterpolator(x, xlim = xlim, FUN = NULL, invert = invert)
}

extractBetaCurveEval <- function(x, xlim, invert = FALSE) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRBeta, invert = invert)
}

extractGaussCurveEval <- function(x, xlim,  invert = FALSE) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRGauss, invert = invert)
}

extractTriangleCurveEval <- function(x, xlim, invert = FALSE) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRTriangle, invert = invert)
}

extractPICurveEval <- function(x, xlim, invert = FALSE) {
  .genericInterpolator(x, xlim = xlim, FUN = CVIRPI, invert = invert)
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
extractCrispExpression <- function(x, invert = FALSE, asString = FALSE) {
  # this supports arbitrary crisp expressions (i.e. expressions not about domain)
  l <- xmlChunkParse(x)
  expr <- l$CrispExpression
  if (length(expr) == 0) expr <- ""
  .crispExpressionGenerator(expr, invert = invert, asString = asString)
}

# internal method for approxfun() linear interopolation
.genericInterpolator <- function(x, xlim = NULL, FUN = NULL, invert = FALSE) {
  
  l <- xmlChunkParse(x)
  
  # get the lower and upper end points
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
  # get range points (if present)
  rp <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # get crisp expression (if present)
  crisp.expression <- l$CrispExpression
  
  if (!is.null(crisp.expression)) {
    # insert domain vector at beginning
    crisp.expression <- paste0('domain ', crisp.expression)
    
    # replace logical operators, and add domain vector
    crisp.expression <- gsub('and', '& domain', crisp.expression)
    crisp.expression <- gsub('or', '| domain', crisp.expression)
  }
  
  if (is.null(xlim)) {
    x1 <- domain
  } else {
    x1 <- seq(xlim[1], xlim[2], (xlim[2] - xlim[1]) / pmax(100, (xlim[2] - xlim[1]) * 10))
  }
  
  # if x limits not specified, use the domain as is
  if (length(domain) == 0) {
    domain <- x1
  }
  
  # "arbitrary" curves provide the rating values via RangePoints or CrispExpression
  if (!is.null(crisp.expression)) {
    # crisp curves where ratings are derived from logical expressions about the _domain_
    rating <- as.numeric(eval(parse(text = crisp.expression)))
  } else if (length(rp) > 0) {
    # other curves just give the values directly
    rating <- rp
    # note that the more general crisp case is not a curve and uses arbitrary property values for ratings -- see extractCrispExpression()
  } else {
    if (is.null(FUN)){
      stop("Curve function `FUN` must be specified when evaluation does not contain RangePoints", call. = FALSE)
    }
    rating <- FUN(x1, domain)
  }
  
  # invert?
  if (invert) {
    rating <- (1 - rating)
  }
  approxfun(x1, rating, method = 'linear', rule = 2)
}

# regex based property crispexpression parser (naive but it works)
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
