# hedge and operator functions

# NULL hedge: if NULL data in `x` then `null.value`, else `0`
#' @importFrom stats na.omit
.NULL_HEDGE <- function(x, null.value = NULL, not.null.value = 0, na.rm = FALSE) {
  if (na.rm) x <- na.omit(x)
  if (!is.list(x)) {
    x <- ifelse(is.null(x) | (is.na(x) & !is.nan(x)), null.value, not.null.value)
  }
  x
}
 
.NULL_NOT_RATED <- function(x, na.rm = FALSE) {
  # NULL NOT RATED hedge: if NULL data in `x` then `NaN`, else `0`
  .NULL_HEDGE(x, null.value = NaN, na.rm = na.rm)
}

.NULL_NA <- function(x, na.rm = FALSE) {
  # NULL NA hedge: if NULL data in `x` then `NA`, else `0`
  # does not exist in NASIS
  .NULL_HEDGE(x, null.value = NA, na.rm = na.rm)
}

.NOT_NULL_AND <- function(x, na.rm = FALSE) {
  # NOT NULL AND hedge: if NULL data in `x` then `0`, else `1`
  .NULL_HEDGE(x, null.value = 0L, not.null.value = 1L, na.rm = na.rm)
}

.NULL_OR <- function(x, na.rm = FALSE) {
  # NULL OR hedge: if NULL data in `x` then `1`, else `0`
  .NULL_HEDGE(x, null.value = 1L, na.rm = na.rm)
}

.MULT <- function(x, a, na.rm = FALSE) {
  matrix(as.numeric(x), ncol = ncol(x)) * a
}

.POWER <- function(x, a, na.rm = FALSE) {
  matrix(as.numeric(x), ncol = ncol(x)) ^ a
}

.NOT <- function(x, a, na.rm = FALSE) {
  if (!is.matrix(x)) {
    nc <- 1
  } else {
    nc <- ncol(x)
  }
  1 - matrix(as.numeric(x), ncol = nc)
}

.PROD <- function(x, na.rm = FALSE) {
  if (!is.matrix(x)) {
    if (!is.list(x)) {
      x <- list(x)
    }
    x <- do.call('cbind', x)
  }
  if (ncol(x) == 1) { 
    x <- t(x)
  }
  nc <- ncol(x)
  m <- matrix(as.numeric(x), ncol = nc)
  res <- m[, 1]
  for (i in 2:ncol(m)) {
    res <- res * m[, i]
  }
  res
  # matrixStats::rowProds(matrix(as.numeric(x), ncol = ncol(x)), na.rm = na.rm)
  # apply(matrix(as.numeric(x), ncol = ncol(x)), 1, prod, na.rm = na.rm)
}

#' @importFrom matrixStats rowMaxs
.OR_MAX <- function(x, na.rm = FALSE) {
  if (!is.matrix(x)) {
    if (!is.list(x)) {
      x <- list(x)
    }
    x <- do.call('cbind', x)
  }
  if (ncol(x) == 1) { 
    x <- t(x)
  }
  nc <- ncol(x)
  matrixStats::rowMaxs(matrix(as.numeric(x), ncol = nc), na.rm = na.rm)
  # apply(matrix(as.numeric(x), ncol = ncol(x)), 1, max, na.rm = na.rm)
}

#' @importFrom matrixStats rowMins
.AND_MIN <- function(x, na.rm = FALSE) {
  if (!is.matrix(x)) {
    if (!is.list(x)) {
      x <- list(x)
    }
    x <- do.call('cbind', x)
  }
  if (ncol(x) == 1) { 
    x <- t(x)
  }
  nc <- ncol(x)
  matrixStats::rowMins(matrix(as.numeric(x), ncol = ncol(x)), na.rm = na.rm)
  # apply(matrix(as.numeric(x), ncol = ncol(x)), 1, min, na.rm = na.rm)
}

#' @importFrom matrixStats rowSums2
.SUM <- function(x, na.rm = FALSE) {
  if (!is.matrix(x)) {
    if (!is.list(x)) {
      x <- list(x)
    }
    x <- do.call('cbind', x)
  }
  if (ncol(x) == 1) { 
    x <- t(x)
  }
  nc <- ncol(x)
  matrixStats::rowSums2(matrix(as.numeric(x), ncol = ncol(x)), na.rm = na.rm)
  # apply(matrix(as.numeric(x), ncol = ncol(x)), 1, sum, na.rm = na.rm)
}

.LIMIT <- function(x, val, na.rm = FALSE) {
  pmin(x, val, na.rm = na.rm)
}

# return a function to apply hedge_type to the values in x
functionHedgeOp <- function(hedge_type) {
  switch(toupper(gsub(" ", "_", hedge_type)),
         "NULL_NOT_RATED" = .NULL_NOT_RATED,
         "NULL_NA" = .NULL_NA, # does not exist in NASIS
         "NOT_NULL_AND" = .NOT_NULL_AND,
         "NULL_OR" = .NULL_OR,
         "MULTIPLY" = .MULT,
         "WEIGHT" = .MULT,
         "PRODUCT" = .PROD,
         "NOT" = .NOT,
         "OR" = .OR_MAX,
         "AND" = .AND_MIN,
         "SUM" = .SUM,
         "POWER" = .POWER,
         "LIMIT" = .LIMIT)
}
