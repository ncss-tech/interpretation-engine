# This file contains functions for extracting interpolation functions for different Evaluation curves

## TODO: return function and critical points as a list

# Extracting evaluation curves ----

#' Extract an evaluation curve
#'
#' @param evalrec Evaluation record
#' @param xlim numeric vector, min and max values of fuzzy space
#' @param resolution not used
#' @param sig.scale not used
#' 
#' @return evaluation curve values
#' @export
extractEvalCurve <- function(evalrec, xlim = NULL, resolution = NULL, sig.scale = NULL) {
  if (!missing(resolution))
    .Deprecated(msg = "extractEvalCurve `resolution` argument is no longer used") 
  
  if (!missing(sig.scale))
    .Deprecated(msg = "extractEvalCurve `sig.scale` argument is no longer used")
  
  # type
  et <- evalrec$evaluationtype
  
  # invert
  invert.eval <- evalrec$invertevaluationresults
  
  
  # use the defined min / max values, if available
  if(is.null(xlim)) {
    # these are not always defined!
    domain.min <- evalrec$propmin
    domain.max <- evalrec$propmax
    
    # if missing, encode as NULL for .linearInterpolator()
    if(is.na(domain.min) || is.na(domain.max)) {
      domain.min <- NULL
      domain.max <- NULL
    }
  } else {
    # override fuzzy domain with xlim argument
    domain.min <- xlim[1]
    domain.max <- xlim[2]
  }
  
  # spline interpolation
  if (et  == 'ArbitraryCurve') {
    res <- extractArbitraryCurveEval(evalrec$eval, invert = invert.eval)
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
    if (is.null(domain.min) | is.null(domain.max)) {
      res <- extractCrispExpression(evalrec$eval, invert = invert.eval)
      
      # message("Evaluating CrispExpression (", attr(res, "CrispExpression"),") has only experimental support")
      
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
  
  if (et == "IsNull") {
    res <- extractIsNull(invert = invert.eval)
    return(res)
  }
  
  warning("extractEvalCurve: curve type (", et, ") not supported", call. = FALSE)
  
  return(function(evalrec) {
    return(NULL)
  })
}

#' Function Generators for Interpolating Evaluation Curves
#' 
#' @param x evaluation XML content
#' @param xlim domain points (see details)
#' @param invert invert rating values? Default: `FALSE`
#' @param resolution Number of segments to calculate spline points for, which are then interpolated with `splinefun()`. Used only for `extractArbitraryCurveEval()`. Default `1000`
#' @param method Passed to `splinefun()`. Used only for `extractArbitraryCurveEval()`. Default `"natural"`
#' @param bounded Used only for `extractArbitraryCurveEval()`. Used to constrain spline results to `[0,1]`. Default `TRUE`
#' 
#' @details Generally the `xlim` argument is a numeric vector of length two that refers to the upper and lower boundaries of the domain (property value range) of interest. In the case of `extractTrapezoidEval()` `xlim` is a vector of length 4 used to specify the x-axis position of left base, two upper "plateau" boundaries, and right base. For arbitrary linear curves, the `xlim` vector may be any length.
#' 
#' @export
#' @rdname EvaluationCurveInterpolators
extractTrapezoidEval <- function(x, xlim, invert = FALSE) {
  .linearInterpolator(x, xlim = xlim, FUN = CVIRTrapezoid, invert = invert)
}

#' @export
#' @rdname EvaluationCurveInterpolators
extractArbitraryCurveEval <- function(x,
                                      resolution = 1000,
                                      method = 'natural',
                                      invert = FALSE, 
                                      bounded = TRUE) {
  
  .CVIRSplineInterpolator(x,
                          resolution = resolution,
                          method = method,
                          invert = invert,
                          bounded = bounded) 
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


#' Extract IsNull Evaluation Logic as R function
#' 
#' Default behavior of IsNull evaluation returns value > `0` (1) if `NULL`, inverted behavior returns `0` if `NULL`
#' 
#' @param invert invert logic with `!`? Default: `FALSE`
#'
#' @return a generated function of an input variable `x` 
#' 
#' @details The generated function returns a logical value (converted to numeric) when the relevant property data are supplied.
#' 
#' @export
extractIsNull <- function(invert = FALSE) {
  if (invert) {
    function(x) .NULL_HEDGE(x, null.value = 0)
  } else {
    function(x) .NULL_HEDGE(x, null.value = 1)
  }
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
    crisp.expression <- gsub('and', '& domain', crisp.expression, ignore.case = TRUE)
    crisp.expression <- gsub('or', '| domain', crisp.expression, ignore.case = TRUE)
  }
  
  if (is.null(xlim)) {
      x1 <- domain
  } else {
    x1 <- seq(
      from = xlim[1], 
      to = xlim[2], 
      by = (xlim[2] - xlim[1]) / pmax(100, (xlim[2] - xlim[1]) * 10)
    )
  }
  
  if (length(domain) == 0 && length(rp) == 0) {
    return(extractCrispExpression(x, invert = invert))
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
  res <- approxfun(x1, rating, method = 'linear', rule = 2)
  attr(res, 'domain') <- domain
  attr(res, 'range') <- rp
  
  return(res)
}


# ArbitraryCurve

# spline interpolator for arbitrary curves
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double x = (double) propData;
#   double num2 = 0.0;
#   int count = base.DomainValues.Count;
#   if (x <= base.DomainValues[0])
#   {
#     num2 = base.RangeValues[0];
#   }
#   else if (x >= base.DomainValues[count - 1])
#   {
#     num2 = base.RangeValues[count - 1];
#   }
#   else
#   {
#     for (int i = 1; i < count; i++)
#     {
#       if (x < base.DomainValues[i])
#       {
#         num2 = this.CalculateSpline(i - 1, i, x);
#         break;
#       }
#     }
#   }
#   return num2;
# }
#
#' @importFrom stats splinefun
.CVIRSplineInterpolator <- function(x,
                                    resolution = 1000,
                                    method = "natural",
                                    invert = FALSE, 
                                    bounded = TRUE) {
    
  
  l <- xmlChunkParse(x)
  
  # get the lower and upper end points
  domain <- as.numeric(as.vector(unlist(l$DomainPoints)))
  
  # get range points (if present)
  ylim <- as.numeric(as.vector(unlist(l$RangePoints)))
  
  # emulates non-linear interpolator used for 'arbitrary' curves in NASIS CVIR
  #  divides domain into resolution segments, calculates many spline point locations
  #  then interpolates the resulting points using splinefun() natural splines
  #  
  #  the result is an accurate representation of the arbitrary curve that might be
  #  specified using only ~10 pairs of domain/rating values
  x1 <- seq(min(domain), max(domain), (max(domain) - min(domain)) / resolution)
  rating <- vector("numeric", length(x1))
  
  dydx <- .CVIRSplineDerivative(domain, ylim)
  
  for (j in seq_along(rating)) {
    if (x1[j] <= domain[1]) {
      rating[j] <- ylim[1]
    } else if (x1[j] >= domain[length(domain)]) {
      rating[j] <- ylim[length(ylim)]
    } else if (x1[j] %in% domain) {
      rating[j] <- ylim[which(domain %in% x1[j])]
    } else {
      # index of next largest domain point
      idx <- which(domain >= x1[j])[1]
      
      if (!is.na(idx) && idx > 1) {
        rating[j] <- .CVIRSplinePoint(domain, ylim, dydx, idx - 1, idx, x1[j])
      }
    }
  }
  
  # natural splines through the calculated spline points
  .f0 <- splinefun(x1, rating, method = method)
  
  if (bounded){
    # wrap the resulting function to ensure fuzzy ratings are never outside [0,1]
    #  NOTE: NASIS does not do this
    .f <- function(x, deriv = 0) {
      y <- .f0(x = x, deriv = deriv)
      if (deriv == 0) {
        y[y > 1] <- 1
        y[y < 0] <- 0
      }
      y
    }
  } else {
    .f <- .f0
  }
  attr(.f, 'domain') <- domain
  attr(.f, 'range') <- ylim
  attr(.f, 'bounded') <- bounded
  attr(.f, 'resolution') <- resolution
  attr(.f, 'method') <- method
  
  .f
}

# private double CalculateSpline(int i0, int i1, double x)
# {
#   double num = base.DomainValues[i0];
#   double num2 = base.RangeValues[i0];
#   double num3 = base.RangeValues[i1];
#   double local1 = base.DomainValues[i1];
#   double num4 = local1 - num;
#   double num5 = x - num;
#   double num6 = local1 - x;
#   double num7 = num5 / num4;
#   double num8 = num6 / num4;
#   double num9 = this.derivative[i1];
#   return ((((((this.derivative[i0] * ((num8 * num6) - num4)) * num6) + ((num9 * ((num7 * num5) - num4)) * num5)) / 6.0) + (num2 * num8)) + (num3 * num7));
# }
.CVIRSplinePoint <- function(domainx, rangey, dydx, i0, i1, x) {
  num = domainx[i0]
  num2 = rangey[i0]
  num3 = rangey[i1]
  local1 = domainx[i1]
  num4 = local1 - num
  num5 = x - num
  num6 = local1 - x
  num7 = num5 / num4
  num8 = num6 / num4
  num9 = dydx[i1]
  ((((((dydx[i0] * ((num8 * num6) - num4)) * num6) + ((num9 * ((num7 * num5) - num4)) * num5)) / 6.0) + (num2 * num8)) + (num3 * num7))
}  

# private void CalculateDerivatives()
# {
#   int count = base.DomainValues.Count;
#   this.derivative = new double[count];
#   double[] numArray = new double[] { 0.0 };
#   this.derivative[0] = 0.0;
#   this.derivative[count - 1] = 0.0;
#   for (int i = 1; i < (count - 1); i++)
#   {
#     double num3 = base.DomainValues[i - 1];
#     double num4 = base.DomainValues[i];
#     double num5 = base.RangeValues[i - 1];
#     double num6 = base.RangeValues[i];
#     double num7 = base.RangeValues[i + 1];
#     double num8 = num4 - num3;
#     double local1 = base.DomainValues[i + 1];
#     double num9 = local1 - num4;
#     double num10 = local1 - num3;
#     double num11 = num8 / num10;
#     double num12 = 2.0 + (num11 * this.derivative[i - 1]);
#     this.derivative[i] = (num11 - 1.0) / num12;
#     numArray[i] = ((num7 - num6) / num9) - ((num6 - num5) / num8);
#     numArray[i] = (((numArray[i] * 6.0) / num10) - (num11 * numArray[i - 1])) / num12;
#   }
#   for (int j = count - 2; j >= 0; j--)
#   {
#     this.derivative[j] = numArray[j] + (this.derivative[j] * this.derivative[j + 1]);
#   }
# }
.CVIRSplineDerivative <- function(x, y) {
  n <- length(x)
  deriv <- vector("numeric", n)
  numArray <- deriv
  for (i in 2:(n - 1)) {
    num3 = x[i - 1]
    num4 = x[i]
    num5 = y[i - 1]
    num6 = y[i]
    num7 = y[i + 1]
    num8 = num4 - num3
    local1 = x[i + 1]
    num9 = local1 - num4
    num10 = local1 - num3
    num11 = num8 / num10
    num12 = 2.0 + (num11 * deriv[i - 1])
    deriv[i] = (num11 - 1.0) / num12
    numArray[i] = ((num7 - num6) / num9) - ((num6 - num5) / num8)
    numArray[i] = (((numArray[i] * 6.0) / num10) - (num11 * numArray[i - 1])) / num12
  }
  for (j in rev(1:(n - 1))) {
    deriv[j] <- numArray[j] + (deriv[j] * deriv[j + 1])
  }
  deriv
}

# arbitrary linear
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (double) propData;
#   double num2 = 0.0;
#   int count = base.DomainValues.Count;
#   if (num <= base.DomainValues[0])
#   {
#     num2 = base.RangeValues[0];
#   }
#   else if (num >= base.DomainValues[count - 1])
#   {
#     num2 = base.RangeValues[count - 1];
#   }
#   else
#   {
#     for (int i = 1; i < count; i++)
#     {
#       if ((base.DomainValues[i - 1] <= num) && (num < base.DomainValues[i]))
#       {
#         double num5 = (base.RangeValues[i] - base.RangeValues[i - 1]) / (base.DomainValues[i] - base.DomainValues[i - 1]);
#         double num6 = base.RangeValues[i - 1] - (num5 * base.DomainValues[i - 1]);
#         num2 = (num5 * num) + num6;
#         break;
#       }
#     }
#   }
#   return num2;
# }

# linear
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (double) propData;
#   double num3 = base.DomainValues[0];
#   double num4 = base.DomainValues[1];
#   return ((num >= num3) ? ((num <= num4) ? ((num - num3) / (num4 - num3)) : 1.0) : 0.0);
# }

# regex based property crispexpression parser (naive but it works)
.crispFunctionGenerator <- function(x, invert = FALSE, asString = FALSE) {
  
  # numeric constants get a short circuit
  if (grepl("^\\d+$", x)) {
    res <- sprintf("function(x) { %s }", x)
    if (asString) return(res)
    res <- try(eval(parse(text = res)))
    return(res)
  }
  
  # remove empty quotations (some expressions have these trailing with no content)\
  step0 <- gsub("or +or", "or", gsub("\t", " ", gsub("\"\"", "", gsub("'", "\"", x))))
  
  if (grepl("[^(]*\\)$", step0)) {
    step0 <- gsub(")$", "", step0)
  }
  
  if (grepl(" TO ", step0, ignore.case = TRUE)) {
    step0 <- gsub("(.*) TO (.*)", "x >= \\1 & x <= \\2", step0, ignore.case = TRUE)
  }
  
  if (grepl("^i?matches", step0, ignore.case = TRUE)) {
    step0.5 <- gsub("\" *or *i?matches *\"|\" *or *\"|\", \"", "$|^", step0, ignore.case = TRUE)
  } else {
    step0.5 <- step0 #gsub("\" *or *i?matches *\"|\", \"", "$|^", step0, ignore.case = TRUE)
  }  
  
  # wildcards matches/imatches
  step1 <- gsub(
    "i?matches +\"([^\"]*)\"",
    "grepl(\"^\\1$\", x, ignore.case = TRUE)",
    step0.5,
    ignore.case = TRUE
  )
  step2 <- gsub("*", ".*", step1, fixed = TRUE)
  
  # (in)equality  
  step3 <- gsub(" x  grepl", "grepl", gsub("^([><=]*) ?(\")?|(and|or) ([><=]*)? ?(\")?", "\\3 x \\1\\4 \\2\\5", step2))
  step3 <- gsub("x +x", "x", step3)
  step3 <- gsub("x  \"", "x == \"", step3)
  
  # convert = to ==
  step4 <- gsub("x [^<>]=? ", "x == ", 
                gsub("\" ?(, ?| or ?)\"", "\" | x == \"", 
                     step3, ignore.case = TRUE))
  
  # convert partial matches to grepl
  step5 <- gsub("x == +(\"[^\"]*\\.\\*[^\"]*\")", "grepl(\\1, x)", step4, ignore.case = TRUE)
  
  # convert and/or to &/|
  expr <- trimws(gsub("([^no])or *x?", "\\1 | x ", gsub(" *and *x?", " & x ", step5, ignore.case = TRUE), ignore.case = TRUE))
  
  # various !=
  expr <- gsub("== != *\"|== not *\"", "!= \"", expr, ignore.case = TRUE)
  expr <- gsub("== !=", "!= ", expr, ignore.case = TRUE)
  expr <- gsub("== \"any class other than ", "!= \"", expr)
  
  # final matches
  expr <- gsub("== =", "==", gsub("== MATCHES ", "== ", expr, ignore.case = TRUE))
  
  # grepl
  expr <- gsub("x grepl", "grepl", expr, ignore.case = TRUE)
  
  # not grepl
  expr <- gsub("x =* *not grepl", "!grepl", expr, ignore.case = TRUE)
  
  # many evals just return the property
  expr[expr == "x =="] <- "x"
  
  expr <- gsub("x +NOT", "x !=", expr)
  
  # logical expression, possibly inverted, then converted to numeric (0/1)
  # TODO: handle NA via na.rm/na.omit, returning attribute of offending indices
  res <- sprintf("function(x) { 
                    y <- as.numeric(%s(%s)) 
                    y[is.na(y)] <- 0
                    y
                  }", 
                 ifelse(invert, "!", ""), expr)
  if (asString) return(res)
  res <- try(eval(parse(text = res)))
  # if (inherits(res, "try-error"))
  #   browser()
  attr(res, 'CrispExpression') <- x
  res
}
