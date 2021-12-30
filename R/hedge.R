# hedge functions

# NULL hedge: if NULL data in `x` then `null.value`, else `x`
.NULL_HEDGE <- function(x, null.value = NULL, na.rm = FALSE) {
  if (na.rm) x <- na.omit(x)
  x[is.null(x) | is.na(x)] <- null.value
  x
}

.NULL_NOT_RATED <- function(x, na.rm = FALSE) {
  # NULL NOT RATED hedge: if NULL data in `x` then `"Not rated"`, else `x`
  .NULL_HEDGE(x, null.value = "Not rated", na.rm = FALSE)
}

.NOT_NULL_AND <- function(x, na.rm = FALSE) {
  # NOT NULL AND hedge: if NULL data in `x` then `"0"`, else `x`
  .NULL_HEDGE(x, null.value = "0", na.rm = FALSE)
}

.NULL_OR <- function(x, na.rm = FALSE) {
  # NULL OR hedge: if NULL data in `x` then `"1"`, else `x`
  .NULL_HEDGE(x, null.value = "1", na.rm = FALSE)
}

# apply hedge_type to the values in x
ruleHedge <- function(hedge_type, x, na.rm = FALSE) {
  switch(toupper(gsub(" ", "_", hedge_type)),
         "NULL_NOT_RATED" = .NULL_NOT_RATED(x, na.rm = na.rm),
         "NOT_NULL_AND" = .NOT_NULL_AND(x, na.rm = na.rm),
         "NULL_OR" = .NULL_OR(x, na.rm = na.rm),
         "MULTIPLY" = prod(as.numeric(x), na.rm = na.rm))
}

# operator functions

ruleOperator <- function(operator_type, x, na.rm = FALSE) {
  switch(toupper(operator_type), 
         "OR" = max(as.numeric(x), na.rm = na.rm),
         "SUM" = sum(as.numeric(x), na.rm = na.rm))
}
