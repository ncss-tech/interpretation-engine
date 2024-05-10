# This file contains R versions of the NASIS CVIR functions for generating rating curves

# internal static double ComputeSCurve(double min, double max, bool ascending, double x)
# {
#   double num;
#   double num2 = (max + min) / 2.0;
#   if (x < min)
#   {
#     num = 0.0;
#   }
#   else if (x > max)
#   {
#     num = 1.0;
#   }
#   else
#   {
#     double num3;
#     if (x < num2)
#     {
#       num3 = (x - min) / (max - min);
#       num = (2.0 * num3) * num3;
#     }
#     else
#     {
#       num3 = (x - max) / (max - min);
#       num = 1.0 - ((2.0 * num3) * num3);
#     }
#   }
#   if (!ascending)
#   {
#     num = 1.0 - num;
#   }
#   return num;
# }
# 

# vectorized version of CVIR ComputeSCurve from GOV.USDA.NRCS.NASIS.Cvir.Runtime.Interpret

#' CVIR Evaluation Curves
#'
#' @param x a vector of property values
#' @param xlim x-axis limits (see details)
#' @param ascending should S-curve be drawn in ascending or descending order? Default: `TRUE`
#'
#' @return a vector of fuzzy rating values derived from specified curve equation
#' @details describe the number of xlim parameters needed for each curve type here
#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 4, 0.01)
#' 
#' y <- CVIRSigmoid(x, c(0.5, 3))
#' plot(y ~ x)
#' 
CVIRSigmoid <- function(x, xlim, ascending = TRUE) {
  num2 = sum(xlim) / 2
  num = vector("numeric", length(x))
  num[x < num2] <- (2 * ((x[x < num2] - xlim[1]) / (xlim[2] - xlim[1]))^2)
  num[x >= num2] <- 1 - (2 * ((x[x >= num2] - xlim[2]) / (xlim[2] - xlim[1]))^2)
  num[x < xlim[1]] <- 0
  num[x > xlim[2]] <- 1
  if (!ascending) 
    return(1 - num)
  num
}

#' @export
#' @aliases CVIRSigmoid
#' @rdname CVIRCurve
CVIRComputeSCurve <- CVIRSigmoid

##Trapezoid
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (double) propData;
#   double num3 = base.DomainValues[0];
#   double num4 = base.DomainValues[1];
#   double num5 = base.DomainValues[2];
#   double num6 = base.DomainValues[3];
#   return ((num >= num3) ? ((num <= num6) ? (((num < num4) || (num > num5)) ? ((num >= num4) ? ((num6 - num) / (num6 - num5)) : ((num - num3) / (num4 - num3))) : 1.0) : 0.0) : 0.0);
# }

#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 10, 0.01)
#' 
#' y <- CVIRTrapezoid(x, 2:5)
#' plot(y ~ x)
#' 
CVIRTrapezoid <- function(x, xlim) {
  ifelse(x > xlim[1],
         ifelse(x <= xlim[4],
                ifelse(x < xlim[2] | x > xlim[3],
                       ifelse(x > xlim[2], ((xlim[4] - x) / (xlim[4] - xlim[3])), ((x - xlim[1]) / (xlim[2] - xlim[1])) ), 1), 0), 0)
}

## Beta
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (((double) propData) - base.DomainValues[0]) / base.DomainValues[1];
#   return (1.0 / (1.0 + (num * num)));
# }

#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 10, 0.01)
#' 
#' y <- CVIRBeta(x, c(2,2))
#' plot(y ~ x)
#' 
CVIRBeta <- function(x, xlim) {
  num <- (x - xlim[1]) / xlim[2]
  1 / (1 + num^2)
}

## Gauss
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (double) propData;
#   return Math.Exp(-base.DomainValues[1] * Math.Pow(base.DomainValues[0] - num, 2.0));
# }

#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 10, 0.01)
#' 
#' y <- CVIRGauss(x, c(2,2))
#' plot(y ~ x)
#' 
CVIRGauss <- function(x, xlim) {
  exp(-xlim[2]*(xlim[1] - x)^2)
}


## Triangle
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double num = (double) propData;
#   double num3 = base.DomainValues[0];
#   double num4 = base.DomainValues[1];
#   double num5 = (num3 + num4) / 2.0;
#   return ((num >= num3) ? ((num <= num4) ? ((num != num5) ? ((num >= num5) ? ((num4 - num) / (num4 - num5)) : ((num - num3) / (num5 - num3))) : 1.0) : 0.0) : 0.0);
# }

#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 10, 0.01)
#' 
#' y <- CVIRTriangle(x, c(1,3))
#' plot(y ~ x)
#' 
CVIRTriangle <- function(x, xlim) {
  num2 <- (xlim[2] + xlim[1]) / 2
  ifelse(x >= xlim[1],
         ifelse(x <= xlim[2],
                ifelse(x != num2,
                       ifelse(x >= num2, (xlim[2] - x) / (xlim[2] - num2), (x - xlim[1]) / (num2 - xlim[1])), 1), 0), 0)
}

## PI
# public override double GetFuzzyValue(object propData)
# {
#   if (!this.IsValid())
#   {
#     return -1.0;
#   }
#   double x = (double) propData;
#   double min = base.DomainValues[0];
#   double num4 = base.DomainValues[1];
#   return ((x >= min) ? EvaluationSigmoid.ComputeSCurve(min, min + num4, false, x) : EvaluationSigmoid.ComputeSCurve(min - num4, min, true, x));
# }

#' @export
#' @rdname CVIRCurve
#' @examples
#' 
#' x <- seq(0, 10, 0.01)
#' 
#' y <- CVIRPI(x, c(4, 1))
#' plot(y ~ x)
#' 
CVIRPI <- function(x, xlim) {
  num <- vector("numeric", length(x))
  xlim1 <- xlim2 <- xlim
  xlim1[2] <- xlim1[2] + xlim1[1]
  xlim2[1] <- xlim2[1] - xlim2[2]
  xlim2[2] <- xlim1[1]
  num[x >= xlim[1]] <- CVIRComputeSCurve(x[x >= xlim[1]], xlim1, FALSE)
  num[x < xlim[1]] <- CVIRComputeSCurve(x[x < xlim[1]], xlim2, TRUE)
  num
}

# x <- seq(0,10,0.1)
# y <- CVIRPI(x, c(4,1))
# plot(y~x, type="l")
# 
# # compare PI to gauss and beta
# y2 <- CVIRGauss(x, c(4,1))
# y3 <- CVIRBeta(x, c(4,1))
# lines(y2~x, lty=2)
# lines(y3~x, lty=3)

#' @export
#' @rdname CVIRCurve
#' @examples
#' x <- seq(0, 10, 0.01) 
#' y <- CVIRLinear(x, c(4, 1))
#' plot(y ~ x)
CVIRLinear <- function(x, xlim=NULL) {
  if (!is.null(xlim) && length(xlim) == 2 && (xlim[1] != x[1] || xlim[2] != x[length(x)]))
    warning('CVIRLinear xlim argument is ignored', call. = FALSE)
  y <- seq(min(x), max(x), (max(x) - min(x)) / (length(x) - 1))
  (y - min(y)) / max(y)
}
