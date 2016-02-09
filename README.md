# What
Create a stand-alone interpretation engine (using NASIS data) in R.

# Why
I think we all know why.

# How
The [data.tree](https://cran.r-project.org/web/packages/data.tree/vignettes/data.tree.html) package defines objects and methods that are well suited to the task of describing the hierachy of rules and evaluations. 

## Outline
1. load rules and evaluations in R via ODBC
2. select an interpretation
3. load rule and sub-rules into a `data.tree` object
4. load evaluation functions into each terminal node of `data.tree` object
5. create wrapper function to send properties to evaluation functions


## Things to Figure Out
1. [recursively re-naming list elements](http://stackoverflow.com/questions/35278342/recursively-assign-unique-names-to-nodes-in-a-data-tree-object)
2. 

## Ideas
1. http://stackoverflow.com/questions/32522068/order-of-siblings-and-their-kids-in-string/32725097
2. https://cran.r-project.org/web/packages/frbs/index.html
3. https://en.wikipedia.org/wiki/Fuzzy_control_system
