# Lookup Properties using NASIS Web Report

This function uses `WEB-PROPERY-COMPONENT_property` NASIS Web Report to
look up component property data

## Usage

``` r
lookupProperties(coiid, propIDs)
```

## Arguments

- coiid:

  Vector of component IDs (`coiid`)

- propIDs:

  Vector of property IDs

## Value

A data.frame containing `propiid`, `coiid`, `comp_name`, `comp_pct` and
the representative value for the property (`rv`).
