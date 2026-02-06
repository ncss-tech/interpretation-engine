# Extract Crisp Expression Logic as R function

Extract Crisp Expression Logic as R function

## Usage

``` r
extractCrispExpression(x, invert = FALSE, asString = FALSE)
```

## Arguments

- x:

  *character*. Evaluation XML content containing a CrispExpression

- invert:

  *logical*. Invert logic with `!`? Default: `FALSE`

- asString:

  *logical*. Return un-parsed function (for debugging/inspection)
  Default: `FALSE`

## Value

*function*. A generated function of an input variable `x`

## Details

The generated function returns a logical value (converted to numeric)
when the relevant property data are supplied.
