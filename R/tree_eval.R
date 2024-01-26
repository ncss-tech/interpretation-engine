# tree_eval.R
#### adding hsg, svi, vf, and dwb functions ## jrb 03-19-21 ####

# require(parallel)
# require(data.tree)
# require(foreach)
# require(doParallel)

#' Evaluate a tree
#'
#' @param tree tree is a data tree object structured with classifications as leaves above those, all nodes must contain these attributes: "var", specifying the variable name to evaluate, "logical", specifying the logical evaluation at that step. MUST INCLUDE THE SAME VARIABLE "VAR"
#' @param indata data must be a data frame containing columns with names matching all the values of "var" used in the tree object
#' @param ncores number of cores to parallelize over. if set to 1 (default), runs sequentially. Also accepts "auto" as input. Will run with ncores on computer - 2.
#'
#' @author Joseph Brehm
#' @return eval result TODO
#' 
#' @export
#' @aliases hsg_calc svi_calc
#' @importFrom raster as.data.frame
#' @importFrom data.tree isLeaf
#' @importFrom parallel detectCores stopCluster
#' @importFrom foreach foreach registerDoSEQ %dopar%
#' @importFrom doParallel registerDoParallel 
tree_eval <- function(
  tree,
  indata,
  ncores = 1
){
  ### data pre-processing 
  
  # if class is raster brick, convert it to a dataframe. Calc may be faster though???
  ## does this work with stacks?
  inclass <- class(indata)[1]
  
  # remove the all-na rows
  ## this might need to go away, check what it does to raster data
  
  if (inclass %in% c("RasterBrick", "RasterStack")) {
    prepdata <- raster::as.data.frame(indata)
    prepdata <- prepdata[rowSums(is.na(prepdata)) != ncol(prepdata), ]
    
  } else {
    prepdata <- indata[rowSums(is.na(indata)) != ncol(indata), ]
  }
  #### last minute patch 3/19. Fix the above lines, something is very wrong there
  prepdata <- indata
  ###
  
  ### set up paralellization
  # auto core counting: use n cores in computer, minus 2
  if(ncores == "auto") {
    if(parallel::detectCores() == 2) { # just in case there's a dual core machine out there
      ncores = 1
    } else {
      ncores <- parallel::detectCores() - 2
    }
  }
  
  # check if user requested too many cores for the machine
  if(ncores > parallel::detectCores()){
    stop(cat("Cannot run with", ncores, "cores as your computer only has", parallel::detectCores()))
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
  
  
  ### do the thing!
  
  outlist <- foreach(
    row = 1:nrow(prepdata),
    .packages = "data.tree"
  ) %dopar% {    
    
    # start at the root node
    node = tree$root
    
    # descend through the tree until arriving at an end node
    while(!isLeaf(node))  {
      
      # extract the name of the variable to evaluate
      varname = node$nextvar
      
      # check to see if its in the input data
      if(!(varname %in% colnames(prepdata))) {
        stop(paste(varname, "must be a column name in input data"))
      }
      
      # extract the value
      value = prepdata[row,varname]
      
      # if the value is na, this point can't be evaluated due to missing data unless there is a check for NA's in the logic set
      if(is.na(value) & !grepl("is.na", node$nextlogical)) return(NA)
      
      # change the logical string to use the generic 'value' instead of the specified variable name
      # specific variable names are used in the tree objects for readability
      lstr = gsub(varname, "value", node$nextlogical)
      
      # go from the semicolon delimited list of logicals to a vector
      v.lstr <- unlist(strsplit(lstr, split = ";"))
      
      # evaluate them all
      v.bool <- sapply(v.lstr, function(l){eval(parse(text = l))})
      
      # which is true?
      pathno <- which(v.bool)
      
      # if 0 or >1 paths are true, there is an error in the tree
      if(length(pathno) != 1){
        stop(paste0(
          "Node '", node$pathString, "' has ", sum(v.bool), " solutions, should be 1"
        ))
      }
      
      # if there are more logicals to evaluate than there are children, there is an error in the tree
      if(length(v.bool) > length(node$children)) {
        stop(paste0(
          "Node '", node$pathString, "' has ", length(v.bool), " logical statements but ", length(node$children), " children"
        ))
      }
      
      # otherwise, take that path
      node = node$children[[pathno]]
    } # loop back to evaluate the new node now -- or exit, if its a leaf
    
    return(node$result)
  }
  
  if(ncores > 1) parallel::stopCluster(cl)
  
  out <- unlist(outlist)
  
  if (inclass %in% c("RasterBrick", "RasterStack")) {
    
    if (is.character(out)) 
      out <- factor(out)
    
    r.out <- indata[[1]]
    r.out[!is.na(r.out)] <- out
    
    return(r.out)
  } else {
    return(out)
  }
  
  
}

#' @export
hsg_calc <- function(indata, ncores = 1) {
  
  tree_eval(tree = InterpretationEngine::datatree_hsg,
            indata = indata,
            ncores = ncores)
}

#' @export
svi_calc <- function(indata, ncores = 1) {
  
  tree_eval(tree = InterpretationEngine::datatree_svi,
            indata = indata,
            ncores = ncores)
}

### vf
# require(tidyverse)
# require(soilDB)
# require(XML)
# require(digest)

#' Valley Fever 
#'
#' @param indata input data
#' @param doxeric force xeric or nonxeric function, or let it choose for each data row/pixel depending on an input raster (accepts "auto" / "xeric" / "nonxeric")
#' @author Joseph Brehm
#' @return evaluation result
#' @export
#' @importFrom dplyr select %>% if_else
#' @importFrom raster setValues brick
#' @importFrom tidyr replace_na
vf_calc <- function(indata, 
                    doxeric = "auto" # 
){ 
  if(!(doxeric %in% c("auto", F, T))){
    print("Unknown input for xeric parameter, which determines whether to process data as xeric or nonxeric conditions")
    print("Accepted input is 'auto', 'T' (process all as xeric), or 'F' (process all as nonxeric).")
    print("Defaulting to auto. This requires data specifying conditions by data point, and will error if not provided")
    doxeric <- "auto"
  }
  
  # if a raster stack or brick is provided as input, the output will be a raster brick
  rasterinput <- class(indata)[1] %in% c("RasterStack", "RasterBrick")
  
  if(rasterinput) {
    # require(raster)
    r.template <- indata[[1]] # save the first raster in the obj as a template to create an out raster later
    indata <- as.data.frame(indata)
  }
  
  outdata <- indata[,'xeric',drop=FALSE]
  
  ## 1 - chemical subrule
  
  outdata$fuzzsar <- evalbyeid(42999, indata$sar, sig.scale = 5) %>% replace_na(0)
  outdata$fuzzgypsumcontent <- evalbyeid(42991, indata$gypsumcontent) ^ (0.5) %>% replace_na(0)
  
  
  outdata$fuzzec <- evalbyeid(43000, indata$ec) %>% replace_na(0)
  outdata$fuzzph <- evalbyeid(42985, indata$ph, sig.scale = 0.125) %>% replace_na(0)
  
  outdata$fuzzchem <- 
    do.call(pmax, c(outdata[,c('fuzzsar', 'fuzzec', 'fuzzgypsumcontent', 'fuzzph')], na.rm = T))
  
  ## 2 - climatic subrule
  if(!("xeric"  %in% colnames(indata))) indata$xeric <- NA
  if(doxeric != "auto"){
    if(doxeric) {indata$xeric <- 1}
    if(!doxeric) {indata$xeric <- 0}
  }
  
  outdata$fuzzprecipX <- evalbyeid(42997, indata$map)
  outdata$fuzzprecipNX <- evalbyeid(42998, indata$map)
  
  outdata$fuzzalbedo <- evalbyeid(43047, 1 - indata$albedo)
  
  indata$aspectfactor = if_else( ## this is translated from cvir "VALLEY FEVER ASPECT FACTOR", property 35987
    is.na(indata$aspect), 0,
    if_else(
      indata$aspect >= 0 & indata$aspect < 0, 0,
      if_else(
        indata$aspect >= 80 & indata$aspect < 280, -((indata$aspect-180)**2)/9000+1,
        0 # if all false
      )
    )
  )
  
  outdata$fuzzslopeheatload <- evalbyeid(43048, indata$slope)
  outdata$fuzzaspect <- evalbyeid(43049, indata$aspectfactor)
  outdata$fuzzheatingfactor <- 
    outdata$fuzzalbedo *
    outdata$fuzzslopeheatload *
    outdata$fuzzaspect
  
  
  outdata$airtempchopperX <- indata$airtemp / 16
  outdata$airtempchopperNX <- indata$airtemp / 18.5
  
  outdata$fuzzsurftempX <- evalbyeid(43050, outdata$airtempchopperX)
  outdata$fuzzsurftempNX <- evalbyeid(43051, outdata$airtempchopperNX) 
  
  outdata$fuzzairtempX <- evalbyeid(42995, indata$airtemp)
  outdata$fuzzairtempNX <- evalbyeid(42996, indata$airtemp)
  
  ### combine all the x/nx rows together
  outdata$fuzzprecip <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzprecipX,
      outdata$fuzzprecipNX
    )
  
  outdata$fuzzsurftemp <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzsurftempX,
      outdata$fuzzsurftempNX
    )
  
  outdata$fuzzairtemp <-
    if_else(
      indata$xeric == 1,
      outdata$fuzzairtempX,
      outdata$fuzzairtempNX
    )
  
  outdata$fuzzclimate <- 
    (outdata$fuzzheatingfactor * outdata$fuzzsurftemp + outdata$fuzzairtemp) * outdata$fuzzprecip
  
  ## 3 others 
  outdata$fuzzwrd <- evalbyeid(42987, indata$wrd, sig.scale = 2)
  outdata$fuzzwatergatheringsurface <- evalbyeid(42988, sqrt(indata$watergatheringsurface))
  outdata$fuzzom <- evalbyeid(42990, indata$om)
  
  outdata$fuzzsaturation <- evalbyeid(63800, indata$saturationmonths)
  outdata$fuzzflood <- evalbyeid(63801, indata$floodmonths) #### this is not used?
  outdata$fuzzsurfsat <- 
    do.call(pmin, c(outdata[,c('fuzzsaturation', 'fuzzflood')], na.rm = T))
  
  ## 4 combine all the subrules
  outdata$fuzzvf <- 
    sqrt(
      sqrt(outdata$fuzzwrd) * 
        sqrt(outdata$fuzzwatergatheringsurface) * 
        sqrt(outdata$fuzzom) * 
        sqrt(outdata$fuzzsurfsat) *
        outdata$fuzzclimate * 
        outdata$fuzzchem) /
    0.95
  
  # in rare cases, this can be more than 1 (highest val seen in testing was 1.026)
  # clamp it, for data quality & appearance (this should not have meaningful changes. If it does, there is an error here somewhere)
  outdata[outdata$fuzzvf > 1 & !is.na(outdata$fuzzvf), "fuzzvf"] <- 1
  
  classbreaks <- c(0, 0.1, 0.2, 0.5, 0.8, 1)
  classlabels <- c("Not suitable", "Somewhat suitable", "Moderately suitable", "Suitable", "Highly suitable")
  
  outdata$vf <- base::cut(outdata$fuzzvf, breaks = classbreaks, labels = classlabels, right = TRUE, include.lowest = T)
  
  # outdata <- 
  #   outdata %>%
  #   mutate(cokey = as.character(cokey),
  #          coiid = as.character(coiid),
  #          mukey = as.character(mukey))
  
  ## all fuzzy values are returned, as is the column for the maximum fuzzy score, and the final classification
  ## if the input was a raster stack or brick, the output will be a small 2 layer brick instead of the df
  if(rasterinput){
    vf <- r.template %>%
      setValues(factor(outdata$vf),
                levels = rev(classlabels))
    fuzzvf <- r.template %>%
      setValues(outdata$fuzzvf)
    
    outdatabrk <- brick(vf, fuzzvf)
    outdata <- outdatabrk
    names(outdata) <- c("vf", "fuzzvf")
    
  }
  
  return(outdata)
}

## dwb
#' Dwewllings Without Basements
#'
#' @param indata Input data
#'
#' @return evaluation result
#' @export
#' @importFrom dplyr select %>% if_else
#' @importFrom tidyr replace_na
#' @importFrom raster brick setValues
dwb_calc <- function(indata){
  
  # this works on a data frame. 
  # if a raster stack or brick is passed as input, it will convert to df
  
  rasterinput <- class(indata)[1] %in% c("RasterStack", "RasterBrick")
  #print(rasterinput)
  if(rasterinput) {
    r.template <- indata[[1]] # save the first one as a template to create an out raster later
    indata <- as.data.frame(indata)
  }
  
  outdata <- indata[,0] # this makes an empty data frame with the correct num of rows
  
  # 1 - depth to permafrost
  outdata$fuzzpermdepth <-
    pmax(
      evalbyeid(10356, indata$permdepth) %>% replace_na(0), ### case 1: fuzzy logic eval
      indata$pftex %>% as.integer() %>% replace_na(0) # T when there is a pf code in either texinlieu or texmod      
    )
  
  # 2 - ponding duration
  outdata$fuzzpond <- 
    indata$ponding %>% as.integer() %>% replace_na(0)
  
  # 3 - slope
  outdata$fuzzslope <- evalbyeid(10125, indata$slope_r) #%>% replace_na(0) # null goes to NR
  
  # 4 - subsidence(cm)
  # this is secretly a crisp eval
  outdata$fuzzsubsidence <- as.numeric(as.numeric(indata$totalsub_r) >= 30) %>% replace_na(0)
  
  # 5 - flooding frequency
  outdata$fuzzfloodlim <- 
    indata$flooding %>% as.integer() %>% replace_na(0)
  
  # 6 - depth to water table
  outdata$fuzzwt <- evalbyeid(299, indata$wt) %>% replace_na(0)
  
  # 7 - shrink-swell
  outdata$fuzzshrinkswell <- evalbyeid(18502, indata$lep) %>% replace_na(0)
  
  # 8 - om content class of the last layer above bedrock / deepest layer
  outdata$fuzzomlim <- 
    indata$organicsoil %>% as.integer() %>% replace_na(0)
  
  # 9 - depth to bedrock (hard)
  outdata$fuzzdepbrockhard <- evalbyeid(18503, indata$depbrockhard) %>% replace_na(0)
  
  # 10 - depth to bedrock (soft)
  outdata$fuzzdepbrocksoft <- evalbyeid(18504, indata$depbrocksoft) %>% replace_na(0)
  
  # 11 - large stone content
  outdata$fuzzlgstone <- evalbyeid(267, indata$fragvol_wmn) # %>% replace_na(0) #### null goes to not rated
  
  # 12 - depth to cemented pan (thick)
  outdata$fuzzdepcementthick <- evalbyeid(18505, indata$depcementthick) %>% replace_na(0) ### the fuzzy space here is not whats in the notes
  #outdata$fuzzdepcementthick[indata$noncemented] <- 0
  
  # 13 - depth to cemented pan (thin)
  outdata$fuzzdepcementthin <- evalbyeid(18501, indata$depcementthin) %>% replace_na(0)
  #outdata$fuzzdepcementthin[indata$noncemented] <- 0
  
  # 14 - unstable fill
  outdata$fuzzunstable <- 
    indata$unstablefill %>% as.integer() %>% replace_na(0)
  
  # 15 - subsidence due to gypsum
  outdata$fuzzgypsum <- evalbyeid(16254, indata$gypsum) # %>% replace_na(0) ## null to not rated
  
  # 16 impaction
  outdata$fuzzimpaction <- 
    indata$impaction %>% as.integer() %>% replace_na(0)
  
  # 17 drainage class
  outdata$fuzzdrainage <- (indata$drainageclass != 1) %>% as.integer() %>% replace_na(0)
  
  ### aggregate, returning the highest fuzzy value (ie, most limiting variable) and classifying based on it
  firstcol <- which(colnames(outdata) == "fuzzpermdepth")
  lastcol <- which(colnames(outdata) == "fuzzdrainage")
  
  outdata$maxfuzz <- do.call(pmax, c(outdata[,firstcol:lastcol], na.rm = T))
  
  outdata$dwb <- 
    if_else(outdata$maxfuzz == 1, 
            "Very limited",
            if_else(outdata$maxfuzz == 0, 
                    "Not limited",
                    "Somewhat limited"))
  
  ## all fuzzy values are returned, as is the column for the maximum fuzzy score, and the final DWB classification
  
  ## if the input was a raster stack or brick, the output will be a small 2 layer brick instead of the df
  if(rasterinput){
    
    ## this used to work. now it doesnt. export
    dwb <- r.template %>%
      setValues(factor(outdata$dwb),
                levels = rev(c("Not limited", "Somewhat limited", "Very limited")))
    
    # dwb <- r.template %>% 
    #   setValues(outdata$dwb)
    
    
    
    fuzzdwb <- r.template %>%
      setValues(outdata$maxfuzz)
    
    outdata <- brick(dwb, fuzzdwb)
    names(outdata) <- c("dwb", "maxfuzz")
  }
  
  
  return(outdata)
}


