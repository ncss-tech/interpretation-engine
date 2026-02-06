# Extract IsNull Evaluation Logic as R function

Default behavior of IsNull evaluation returns value \> `0` (1) if
`NULL`, inverted behavior returns `0` if `NULL`

## Usage

``` r
extractIsNull(invert = FALSE)
```

## Arguments

- invert:

  invert logic with `!`? Default: `FALSE`

## Value

a generated function of an input variable `x`

## Details

The generated function returns a logical value (converted to numeric)
when the relevant property data are supplied.
