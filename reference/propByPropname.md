# Property by Property Name

Property by Property Name

## Usage

``` r
propByPropname(propname)
```

## Arguments

- propname:

  Character. Property Name

## Value

a row from the `NASIS_properties` data.frame

## Examples

``` r
propByPropname("SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)")
#> [[1]]
#>     propiid propuom propmin propmax                         propmod propdefval
#> 442   10195      pH     1.8      11 high, low, representative value       <NA>
#>                                           propname dataafuse
#> 442 SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)      TRUE
#> 
```
