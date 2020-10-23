# Decision tree evaluation for data.tree
# Joe Brehm
# Last edited 10/10/2020

# this function evaluates decision trees stored as data.tree type objects
# input requirements are fairly specific: see the associated tree creation files for how to create trees that can work here

## Update 9/24/2020:
### internal parallelization! set ncores = 1 for sequential; ncores = "auto" or ncores = [number] for parallel

## update 10/20/2020
### will try to as() the "data" input to a data frame, rather than requiring it to be a dataframe. (Will work for bricks now)

# TO DO:
## internal raster acceptance. Currently requires rasters be converted to a brick then to a data frame
## rewrite the NA checks so that it string searches the entire set of sibling evaluations -- so you don't need !is.na() everywhere
## better error reporting:
### "cannot solve" error to include where in the tree it is looking
## make it faster! calc?
### Rewrite each level to return "go to path 1/2/3/etc" rather than T (descend) or F (go sideways and do another logical)


require(parallel)
require(data.tree)
require(foreach)
require(doParallel)

tree_eval <- function(
  tree, 
  # tree is a data tree object structured with classifications as leaves
  # above those, all nodes must contain these attributes:
  # "var", specifying the variable name to evaluate,
  # "logical", specifying the logical evaluation at that step. MUST INCLUDE THE SAME VARIABLE "VAR"
  indata,
  # data must be a data frame containing columns with names matching all the values of "var" used in the tree object
  ncores = 1
  # number of cores to parallelize over. 
  # if set to 1 (default), runs sequentially
  # Also accepts "auto" as input. Will run with ncores on computer - 2
){
  
  # if class is raster brick, convert it to a dataframe. Calc may be faster
  ## if class is a stack, brick then df. 
  if (class(indata) != "data.frame") {
    indata <- as(indata, data.frame)
  }
  
  
  # auto core counting: use n cores in computer, minus 2
  if(ncores == "auto") {
    if(detectCores() == 2) { # just in case there's a dual core machine out there
      ncores = 1
    } else {
      ncores <- parallel::detectCores() - 2
    }
  }
  
  # check if user requested too many cores for the machine
  if(ncores > detectCores()){
    stop(cat("Cannot run with", ncores, "cores as your computer only has", detectCores()))
  } 
  
  # register sequential or parallel backend, depending on ncores 
  if (ncores > 1) {
    cat("Running parallel with", ncores, "cores")
    cl <- parallel::makeCluster(ncores)
    doParallel::registerDoParallel()
  } else {
    cat("Running sequentially")
    foreach::registerDoSEQ()
  }
  
  out <- foreach(row = 1:nrow(indata),
                   .packages = "data.tree"
                   ) %dopar% {    

      parent = tree$root # parent holds the set of nodes to be evaluated; start as the root.
      descend = F # when descend becomes true, the function has found the right path to follow and will look at the next set of siblings down
      i = 1 # each child node of the current parent will be evaluated in turn, referred to by index "i"
      
      node = parent$children[[i]] # node holds the exact logical node to be evaluated, the i'th node of parent
      
      while(!isLeaf(node))  { # when the node is a leaf (end node), the function is done
        
        # extract the name of the variable to evaluate
        varname = node$var
        
        # check to see if its in the input data
        if(!(varname %in% colnames(indata))) {
          stop(paste(varname, "must be a column name in input data"))
        }
        
        # extract the value
        value = indata[row,varname]
        
        # if the value is na, this point can't be evaluated due to missing data
        if(is.na(value) & !grepl("is.na", node$logical)) return(NA)
        
        # change the logical string to use the generic 'value' instead of the specified variable name
        # specific variable names are used in the tree objects for readability
        lstr = gsub(varname, "value", node$logical)
        
        # evaluate the logical string, storing T/F to 'descend'
        descend = eval(parse(text = lstr)) 
        
        # if descend is true, then this is the correct path. Set the current node as the parent, and start over!
        if(descend) {
          parent = node
          i = 1
          
          # if descend is false, check the next sibling node at this level  
        } else {
          i = i + 1
        }
        
        # if there are no more children to evaluate, then there is an error in the logical pathway of the tree. 
        if(i > length(parent$children)) stop("Error: cannot solve this data point. Check for errors in the tree")
        
        # otherwise, get the next node down and start evaluating again
        node = parent$children[[i]]
      }
      
      return(node$name)
    }
    
    if(ncores > 1) stopCluster(cl)
    
    return(unlist(out))
}



