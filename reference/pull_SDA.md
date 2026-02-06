# Quick SDA data acquisition This function is a shortcut for loading in a broad set of SDA data, filtered to area symbols specified by an input character vector.

The following tables are returned:

## Usage

``` r
pull_SDA(asym, fun = "in")
```

## Arguments

- asym:

  character. Area symbol

- fun:

  Default: "in" uses SQL "IN" operator. Alternately: "like".

## Value

SDA table result

## Details

- `legend`

- `mapunit`

- `component`

- `chorizon`

- `corestrictions`

- `cosurffrags`

- `cotaxfmmin`

- `codiagfeatures`

- `comonth`

- `chtexturegrp`

- `chfrags`

- `chtexture`

- `cosoilmoist`

- `muaggatt`

- `chunified`

- `cointerpENG` – "ENG" rules only though

## Author

Joseph Brehm
