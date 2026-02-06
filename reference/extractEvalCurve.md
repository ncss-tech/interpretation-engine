# Extract an Evaluation Function

Extract an R function from a NASIS evaluation for to evaluate curves and
expressions.

## Usage

``` r
extractEvalCurve(evalrec, xlim = NULL, as.list = FALSE)
```

## Arguments

- evalrec:

  *data.frame*. A single evaluation record from `NASIS_evaluations` data
  set.

- xlim:

  *numeric*. Length 2. Minimum and maximum values to override internal
  domain range.

- as.list:

  *logical*. Return a *list* with function and domain limits? Default
  `FALSE` returns just the function.

## Value

An R function that takes arbitrary input data and returns evaluation
values. When `as.list=TRUE` a list object containing elements `FUN` (the
function) and `domain` (a numeric vector containing domain minimum and
maximum)
