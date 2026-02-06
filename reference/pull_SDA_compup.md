# Quick SDA data acquisition (component up)

This function is a shortcut for loading in a broad set of SDA data,
filtered to area symbols specified by an input character vector.

## Usage

``` r
pull_SDA_compup(asym, fun = "in")
```

## Arguments

- asym:

  character. Area symbol

- fun:

  Default: "in" uses SQL "IN" operator. Alternately: "like".

## Value

list object containing SDA table information for legend, mapunit,
component

## Details

The following tables are returned:

- `legend`

- `mapunit`

- `component`

## Author

Joseph Brehm
