### 0 load packages, workspace, functions, and data ####
library(tidyverse)
library(rasterVis)
library(parallel)
library(foreach)
library(data.tree)

# set working directory to folder where this is saved
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load data.tree engine functions
load("datatree_hsg.rdata") # loads tr.hsg
load("datatree_svi.rdata") # loads tr.svi
source("../tree_eval.r")

# view interp trees
# logical holds the precise logical statement defining each node
print(tr.hsg, "logical")
print(tr.svi, "logical")

# var is the name of the variable used by that node -- required for how tree_eval is written currently
# "classification" is assigned to leaf nodes. It isn't actually required, or ever referred to. Could be any name, or NA
print(tr.hsg, "var")
print(tr.svi, "var")

# load raster brick, all preprocessed already
load("Duchesne100100_treecalcBrick_InData.rdata")

# names have to be these, exactly. Order doesn't matter. Extra layers in the brick are fine
names(brk.in) <- c("wt", "rl", "kw", "ksat", "slope")

### 1 run the tree evaluation ####
### 1.1 - HSG

### currently this works fastest when taking a dataframe as input -- conversion from brick is easy though
df.in <- as.data.frame(brk.in)
df.out <- df.in

# # run sequentially
# t1 <- Sys.time()
# df.out$hsg <-
#   tree_eval(tree = tr.hsg,
#             indata = df.in,
#             ncores = 1)
# t2 <- Sys.time()
# print(t2 - t1)

# run parallel
t3 <- Sys.time()
df.out$hsg <-
  tree_eval(tree = tr.hsg,
            indata = df.in,
            ncores = "auto") 
t4 <- Sys.time()

# back to raster
brk.out <- brk.in

brk.out$hsg <- 
  brk.out$wt %>%
  setValues(factor(df.out$hsg,
                   levels = rev(c("A", "A/D", "B", "B/D", "C", "C/D", "D"))))

# plot
levelplot(brk.out$hsg, 
          col.regions=terrain.colors(7), 
          xlab="Easting", 
          ylab="Northing")


### 1.2 SVI
# need to get the primary HSG for SVI calculation -- string split by "/" to go from A/D to A
df.out$shorthsg <- 
  sapply(df.out$hsg,
         function(h){
           strsplit(h, 
                    "/")[[1]][1]
         })

# run parallel
t7 <- Sys.time()
df.out$svi <-
  tree_eval(tree = tr.svi,
            indata = df.out,
            ncores = "auto") 
t8 <- Sys.time()
print(t8 - t7)

# back to raster
brk.out$svi <- 
  brk.out$wt %>%
  setValues(factor(df.out$svi,
                   levels = rev(c("1 - Low", "2 - Moderately Low", "3 - Moderately High", "4 - High"))))

#plot
levelplot(brk.out$svi, 
          col.regions=terrain.colors(4), 
          xlab="Easting", 
          ylab="Northing")

