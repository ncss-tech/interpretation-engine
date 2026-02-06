# Evaluate a tree

Evaluate a tree

## Usage

``` r
tree_eval(tree, indata, ncores = 1)
```

## Arguments

- tree:

  tree is a data tree object structured with classifications as leaves
  above those, all nodes must contain these attributes: "var",
  specifying the variable name to evaluate, "logical", specifying the
  logical evaluation at that step. MUST INCLUDE THE SAME VARIABLE "VAR"

- indata:

  data must be a data frame containing columns with names matching all
  the values of "var" used in the tree object

- ncores:

  number of cores to parallelize over. if set to 1 (default), runs
  sequentially. Also accepts "auto" as input. Will run with ncores on
  computer - 2.

## Value

eval result TODO

## Author

Joseph Brehm
