# This file contains functions for extracting interpolation functions for different Evaluation curves

## TODO: return function and critical points as a list

# Extracting evaluation curves ----

#' Extract an evaluation curve
#'
#' @param evalrec Evaluation record
#' @param resolution not used
#' @param sig.scale not used
#' 
#' @return evaluation curve values
#' @export
extractEvalCurve <- function(evalrec, resolution = NULL, sig.scale = NULL) {
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
  
  # TODO: should be some kind of spline interpolation, splinefun() isn't working
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

#' Function Generators for Interpolating Evaluation Curves
#' 
#' @param x evaluation XML content
#' @param xlim domain points (see details)
#' @param invert invert rating values? Default: `FALSE`
#' 
#' @details Generally the `xlim` argument is a numeric vector of length two that refers to the upper and lower boundaries of the domain (property value range) of interest. In the case of `extractTrapezoidEval()` `xlim` is a vector of length 4 used to specify the x-axis position of left base, two upper "plateau" boundaries, and right base. For arbitrary curves, the `xlim` vector may be any length.
#' 
#' @export
#' @rdname EvaluationCurveInterpolators
extractTrapezoidEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRTrapezoid, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractArbitraryCurveEval <- function(x, xlim = NULL, invert = FALSE) {
  .linearInterpolator(x, xlim = NULL, FUN = NULL, invert = invert)
  # TODO: .linearInterpolator is linear but this should be a spline-based interpolator 
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractArbitraryLinearCurveEval <- function(x, xlim = NULL, invert = FALSE) {
  .linearInterpolator(x, xlim = NULL, FUN = NULL, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractSigmoidCurveEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRSigmoid, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractLinearCurveEval <- function(x, xlim = NULL, invert = FALSE) {
  .linearInterpolator(x, xlim = NULL, FUN = CVIRLinear, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractCrispCurveEval <- function(x, xlim, invert = FALSE) {
  # this supports crispexpressions involving "domain"
  .linearInterpolator(x, xlim = xlim, FUN = NULL, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractBetaCurveEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRBeta, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractGaussCurveEval <- function(x, xlim,  invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRGauss, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractTriangleCurveEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRTriangle, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractPICurveEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRPI, invert = invert)
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
extractCrispExpression <- function(x, invert = FALSE, asString = FALSE) {
  # this supports arbitrary crisp expressions (i.e. expressions not about domain)
  l <- xmlChunkParse(x)
  expr <- l$CrispExpression
  if (length(expr) == 0) expr <- ""
  .crispFunctionGenerator(expr, invert = invert, asString = asString)
}


# INTERNAL METHODS ----

# internal method for approxfun() linear interpolation
#' @importFrom stats approxfun 
.linearInterpolator <- function(x, xlim = NULL, FUN = NULL, invert = FALSE) {
  
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

.CVIRSplineInterpolator <- function() {
  # emulates non-linear interpolator used for 'arbitrary' curves in NASIS CVIR
  # TODO
}

# regex based property crispexpression parser (naive but it works)
.crispFunctionGenerator <- function(x, invert = FALSE, asString = FALSE) {
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
