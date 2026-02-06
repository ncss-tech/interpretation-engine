# Property Definition by Property Name

Property Definition by Property Name

## Usage

``` r
propdefByPropname(propname)
```

## Arguments

- propname:

  Character. Property Name

## Value

a row from the `NASIS_property_def` data.frame

## Examples

``` r
propdefByPropname("SOIL REACTION 1-1 WATER IN DEPTH 0-100cm (min)")
#> [[1]]
#>     propiid
#> 442   10195
#>                                                                                                                                                                                                                                                                         propdesc
#> 442 Finds the minimum value of soil reaction (pH) for the horizon that has any portion in a depths less than 40" (100 cm).\r\nPortions outside the depth range are not considered in the horizon thickness.\r\n\r\nReturns values for low, high and rv: each has a single value.
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         prop
#> 442 base table component.\r\n \r\n# Finds the minimum value of soil reaction (pH) for the horizon that has any portion in a depths less than 40" (100 cm).\r\n \r\nexec sql select hzdept_r, hzdepb_r, ph1to1h2o_l, ph1to1h2o_h, ph1to1h2o_r, ph01mcacl2_l, ph01mcacl2_h, ph01mcacl2_r\r\n    from  component, chorizon\r\n    where join component to chorizon and (hzdept_r < 100 or hzdept_r=100);\r\n    sort by hzdept_r, hzdepb_r\r\n    aggregate column  ph1to1h2o_l min, ph1to1h2o_h min, ph1to1h2o_r min, ph01mcacl2_l min, ph01mcacl2_h min, ph01mcacl2_r min.\r\n    \r\n    define rv NOT ISNULL (ph1to1h2o_r) ? ph1to1h2o_r : ph01mcacl2_r.\r\n    define low NOT ISNULL (ph1to1h2o_l) ? ph1to1h2o_l : ph01mcacl2_l.\r\n    define high NOT ISNULL (ph1to1h2o_h) ? ph1to1h2o_h : ph01mcacl2_h.
#> 
```
