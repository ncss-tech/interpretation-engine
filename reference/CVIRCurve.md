# CVIR Evaluation Curves

CVIR Evaluation Curves

## Usage

``` r
CVIRSigmoid(x, xlim, ascending = TRUE)

CVIRComputeSCurve(x, xlim, ascending = TRUE)

CVIRTrapezoid(x, xlim)

CVIRBeta(x, xlim)

CVIRGauss(x, xlim)

CVIRTriangle(x, xlim)

CVIRPI(x, xlim)

CVIRLinear(x, xlim = NULL)
```

## Arguments

- x:

  a vector of property values

- xlim:

  x-axis limits (see details)

- ascending:

  should S-curve be drawn in ascending or descending order? Default:
  `TRUE`

## Value

a vector of fuzzy rating values derived from specified curve equation

## Details

describe the number of xlim parameters needed for each curve type here

## Examples

``` r
x <- seq(0, 4, 0.01)

y <- CVIRSigmoid(x, c(0.5, 3))
plot(y ~ x)



x <- seq(0, 10, 0.01)

y <- CVIRTrapezoid(x, 2:5)
plot(y ~ x)



x <- seq(0, 10, 0.01)

y <- CVIRBeta(x, c(2,2))
plot(y ~ x)



x <- seq(0, 10, 0.01)

y <- CVIRGauss(x, c(2,2))
plot(y ~ x)



x <- seq(0, 10, 0.01)

y <- CVIRTriangle(x, c(1,3))
plot(y ~ x)



x <- seq(0, 10, 0.01)

y <- CVIRPI(x, c(4, 1))
plot(y ~ x)


x <- seq(-1, 10, 0.01) 
y <- CVIRLinear(x, c(0.5, 3))
plot(y ~ x)
```
