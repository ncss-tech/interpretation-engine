# Function Generators for Interpolating Evaluation Curves

Function Generators for Interpolating Evaluation Curves

## Usage

``` r
extractTrapezoidEval(x, xlim, invert = FALSE)

extractArbitraryCurveEval(
  x,
  resolution = 1000,
  method = "natural",
  invert = FALSE,
  bounded = TRUE
)

extractArbitraryLinearCurveEval(x, xlim = NULL, invert = FALSE)

extractSigmoidCurveEval(x, xlim, invert = FALSE)

extractLinearCurveEval(x, xlim = NULL, invert = FALSE)

extractCrispCurveEval(x, xlim, invert = FALSE)

extractBetaCurveEval(x, xlim, invert = FALSE)

extractGaussCurveEval(x, xlim, invert = FALSE)

extractTriangleCurveEval(x, xlim, invert = FALSE)

extractPICurveEval(x, xlim, invert = FALSE)
```

## Arguments

- x:

  evaluation XML content

- xlim:

  domain points (see details)

- invert:

  invert rating values? Default: `FALSE`

- resolution:

  Number of segments to calculate spline points for, which are then
  interpolated with
  [`splinefun()`](https://rdrr.io/r/stats/splinefun.html). Used only for
  `extractArbitraryCurveEval()`. Default `1000`

- method:

  Passed to [`splinefun()`](https://rdrr.io/r/stats/splinefun.html).
  Used only for `extractArbitraryCurveEval()`. Default `"natural"`

- bounded:

  Used only for `extractArbitraryCurveEval()`. Used to constrain spline
  results to `[0,1]`. Default `TRUE`

## Details

Generally the `xlim` argument is a numeric vector of length two that
refers to the upper and lower boundaries of the domain (property value
range) of interest. In the case of `extractTrapezoidEval()` `xlim` is a
vector of length 4 used to specify the x-axis position of left base, two
upper "plateau" boundaries, and right base. For arbitrary linear curves,
the `xlim` vector may be any length.
