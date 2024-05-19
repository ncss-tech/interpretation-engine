#' Run a Rule on Custom Property Data
#'
#' Allows for evaluation of a primary rule including subrules, operators, hedges, and evaluations. 
#' 
#' The user must supply a _data.frame_ object or SpatRaster object with property data as input. 
#' 
#'  
#' @param x A _data.tree_ object containing rule tree, or a _character_ giving the rule name to load with  [initRuleset()].
#' @param propdata _data.frame_ or _SpatRaster_ object with column names corresponding to input properties. The column names should be named using `make.names(propname)` where `propname` is the property name from [NASIS_properties] data object.
#' @param mode character. Either `"table"` or `"node"` (default) . Controls back-end rating calculation method using base R or data.tree, respectively.
#' @param cache logical. Store input `"data"` column in `x` along with evaluation `"rating"`. Default: `FALSE`. Only used when `propdata` is a _data.frame_.
#' @param ... Additional arguments
#'
#' @return _data.frame_ containing `"rating"`. When `mode="node"` the input object `x` is modified in place as a side effect with `"rating"` values. When `cache=TRUE` the input `"data"` values are also stored within each node.
#' 
#' @export
#' @rdname interpret
#'
#' @examples
#' 
#' r <- initRuleset("Erodibility Factor Maximum")
#' p <- getPropertySet(r)
#' 
#' my_data <- data.frame(Kmax = seq(0, 1, 0.01))
#' colnames(my_data) <- make.names(p$propname)
#' 
#' res <- interpret(r, my_data)
#' 
#' plot(res$rating ~ my_data[[1]],
#'      xlab = "K factor (input)",
#'      ylab = "Rating [0-1]")
#' 
#' 
setGeneric("interpret", function(x, propdata, ...) {
  standardGeneric("interpret")
})

#' @param cache logical. Save input property data in data.tree object? Default: `FALSE`
#' @export
#' @rdname interpret
setMethod("interpret", signature = c("Node", "data.frame"),
          function(x, propdata, mode = "node", cache = FALSE, ...) {
            .interpret(x, propdata, mode = mode, cache = cache, ...)
          })

#' @export
#' @rdname interpret
setMethod("interpret", signature = c("character", "data.frame"),
          function(x, propdata, mode = "node", cache = FALSE, ...) {
            r <- initRuleset(x)
            .interpret(r, propdata, mode = mode, cache = cache, ...)
          })

#' @param cores integer. Default `1` core.
#' @param core_thresh integer. Default `250000` cells.
#' @param file character. Path to output raster file. Defaults to a temporary GeoTIFF.
#' @param nrows integer. Default `nrow(propdata) / (terra::ncell(propdata) / core_thresh)`
#' @param overwrite logical. Overwrite `file` if it exists?
#' @export
#' @rdname interpret
setMethod("interpret", signature = c("Node", "SpatRaster"), 
          function(x,
                   propdata,
                   mode = "node",
                   cores = 1,
                   core_thresh = 25000L,
                   file = paste0(tempfile(), ".tif"),
                   nrows = nrow(propdata) / (terra::ncell(propdata) / core_thresh),
                   overwrite = TRUE,
                   ...) {
            .interpretRast(x, propdata, cores = cores, core_thresh = core_thresh, ...)
          })

#' @export
#' @rdname interpret
setMethod("interpret", signature = c("character", "SpatRaster"), 
          function(x,
                   propdata,
                   mode = "node",
                   cores = 1,
                   core_thresh = 25000L,
                   file = paste0(tempfile(), ".tif"),
                   nrows = nrow(propdata) / (terra::ncell(propdata) / core_thresh),
                   overwrite = TRUE,
                   ...) {
            r <- initRuleset(x)
            .interpretRast(r, propdata, cores = cores, core_thresh = core_thresh, ...)
          })

### .interpret: workhorse data.frame method
#  mode = "table" simply returns a data.frame of rating values
#  mode = "node" performs calculations in the data.tree object, 
#                optionally storing inputs when cache=TRUE, and 
#                returns a data.frame of rating values
.interpret <- function(x, propdata, mode = "node", cache = FALSE, ...) {
  
  # TODO: option for argument for sub-rating values
  
  if (nrow(propdata) == 0) {
    return(data.frame(rating = numeric(0L)))
  }
  
  if (tolower(mode) == "node") {
    # this modifies the input Node x in place
    x$Do(traversal = "post-order", .interpretNode, propdata, cache = cache)
    return(data.frame(rating = x$rating))
  } else if (tolower(mode) == "table") {
    # this returns a data.frame after extracting info from input Node x
    .interpretDataFrame(x, propdata, ...)
  }
}

# experimental method that does evaluation outside of data.tree
# eval functions and children are extracted from the tree, and iterated
# 
# eventually may be able to construct a more efficient function from input
# rather than brute forcing and being somewhat slower than data.tree
.interpretDataFrame <- function(x, propdata, ...) {
   y <- list()
   names <- character()
   
   .extractNode <- function(x) {
     names <<- c(names, x$name)
     children <- sapply(x$children, function(y) y$name)
     if (length(children) == 0) {
       children <- x$propname
     }
     ef <- x$evalFunction
     if (is.null(ef))
       ef <- function(x) x
     if (!is.null(children))
       attr(ef, 'children') <- children
     y <<- c(y, ef)
   }
   
   x$Do(traversal = "post-order", .extractNode)
   
   names(y) <- make.names(names)
   nt <- names(y)
   
   for (i in seq_along(y)) {
     FUN <- y[[i]]
     nti <- nt[i]
     if (is.function(FUN)) {
       child <- make.names(attr(FUN, "children"))
       if (length(child) == 1) {
         d <- propdata[[child]]
         if (!is.null(d))
           propdata[[nti]] <- FUN(matrix(d, ncol = 1))
         else stop("No data found for '", child, "' while evaluating '", 
                   nti, "'", call. = FALSE) 
       } else if (length(child) > 1) {
         d <- propdata[child]
         propdata[[nti]] <- FUN(as.matrix(d))
       }
     }
   }
   data.frame(rating = propdata[[nt[i]]])
}

.interpretNode <- function(x, propdata, cache = FALSE) {
  
  if (x$isRoot) {
    
    # pass value of first child to root node
    x$rating <- x$children[[1]]$rating
    
  } else if (!is.null(x$propname)) {
    # extract data from `evaldata`
    nm <- make.names(x$propname)
    if (!nm %in% colnames(propdata))
      stop(sprintf("column '%s' not found in `propdata`", nm), call. = FALSE)
    x_data <- propdata[, nm]
    
    # TODO: generalize methods for naming `evaldata`, use of propiid
    
    # evaluate properties
    x$rating <- x$evalFunction(x_data)
    
    # storing input in tree useful, but larger object
    if (cache) {
      x$data <- x_data
    }
  } else if (!is.null(x$rule_refid)) {
    
    # rules are an aggregation of their children
    x$rating <- sapply(x$children, function(y) y$rating)
    
  } else if (!is.null(x$Type)) {
    
    # evaluate hedges and operators on children
    x$rating <- x$evalFunction(sapply(x$children, function(y) y$rating))
    
  }
  
  x$rating <- as.numeric(x$rating)
  
}

#' @importFrom terra ncell readStart writeStart readValues writeValues readStop writeStop
#' @importFrom parallel makeCluster stopCluster clusterApply
#' @importFrom data.table rbindlist 
.interpretRast <- function(x,
                           propdata,
                           mode = "node",
                           cores = 1,
                           core_thresh = 25000L,
                           file = paste0(tempfile(), ".tif"),
                           nrows = nrow(propdata) / (terra::ncell(propdata) / core_thresh),
                           overwrite = TRUE) {
  
  stopifnot(requireNamespace("terra"))
  suppressWarnings(terra::readStart(propdata))
  
  # nrows must be an integer
  nrows <- floor(nrows)
  
  # create template brick
  out <- terra::rast(propdata)
  cnm <- c("rating")
  terra::nlyr(out) <- length(cnm)
  names(out) <- cnm
  
  out_info <- terra::writeStart(out, filename = file, overwrite = overwrite, progress = 0)
  outrows <- c(out_info$row, nrow(out))
  start_row <- lapply(1:out_info$n, function(i) out_info$row[i] + c(0, (seq_len(floor((out_info$nrows[i]) / nrows)) * nrows)))
  n_row <- lapply(seq_along(start_row), function(i) diff(c(start_row[[i]] - 1, outrows[i + 1])))
  n_set <- sum(sapply(start_row, length))
  
  if (cores > 1) {
    cls <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cls))
    
    # TODO: can blocks be parallelized?
    count <- 1
    for (i in seq_along(n_row)) {
      for (j in seq_along(n_row[[i]])) {
        if (n_row[[i]][j] > 0) {
          st <- Sys.time()
          blockdata <- terra::readValues(propdata,
                                         row = start_row[[i]][j],
                                         nrows = n_row[[i]][j],
                                         dataframe = TRUE)
          ids <- 1:nrow(blockdata)
          skip.idx <- which(is.na(blockdata[[1]]))
          
          if (length(skip.idx) > 0) {
            blockcomplete <- blockdata[-skip.idx,]
          } else blockcomplete <- blockdata
          
          if (nrow(blockcomplete) > 0) {
            # parallel within-block processing
            cids <- 1:nrow(blockcomplete)
            sz <- round(nrow(blockcomplete) / cores) + 1
            X <- split(blockcomplete, f = rep(seq(from = 1, to = floor(length(cids) / sz) + 1),
                                              each = sz)[1:length(cids)])
            r <- data.table::rbindlist(
              parallel::clusterApply(cls, X, function(y) {
                .interpret(x, y, mode = mode, cache = FALSE, ...)
              }),
              use.names = TRUE,
              fill = TRUE
            )
            # TODO: why does fill=TRUE need to be used here? it introduces NAs
          } else {
            r <- data.frame(rating = numeric(0), stringsAsFactors = FALSE)
          }
          
          # fill skipped NA cells
          r.na <- r[0, , drop = FALSE][1:length(skip.idx), , drop = FALSE]
          r <- rbind(r, r.na)[order(c(ids[!ids %in% skip.idx], skip.idx)),]
          
          st2 <- Sys.time()
          terra::writeValues(out, as.matrix(r), start_row[[i]][j], nrows = n_row[[i]][j])
          st3 <- Sys.time()
          
          deltat <- signif(difftime(Sys.time(), st, units = "auto"), 2)
          message(paste0(
            "Batch ", count, " of ", n_set, " (n=",
            nrow(blockcomplete), " on ", cores, " cores) done in ",
            deltat, " ", attr(deltat, 'units')
          ))
          count <- count + 1
        }
      }
    }
  } else {
    for (i in seq_along(n_row)) {
      for (j in seq_along(n_row[[i]])) {
        if (n_row[[i]][j] > 0) {
          dataall <- terra::readValues(
            propdata,
            row = start_row[[i]][j],
            nrows = n_row[[i]][j],
            dataframe = TRUE
          )
          ids <- 1:nrow(dataall)
          
          skip.idx <- which(is.na(dataall[[1]]))
          
          if (length(skip.idx) > 0) {
            datacomplete <- dataall[-skip.idx,]
          } else datacomplete <- dataall
          
          r2 <- .interpret(x, datacomplete)
          
          # fill skipped NA cells
          r.na <- r2[0, , drop = FALSE][1:length(skip.idx), , drop = FALSE]
          r2 <- rbind(r2, r.na)[order(c(ids[!ids %in% skip.idx], skip.idx)),]
          
          terra::writeValues(out, as.matrix(r2), start_row[[i]][j], nrows = n_row[[i]][j])
        }
      }
    }
  }
  
  out <- terra::writeStop(out)
  terra::readStop(propdata)
  out
}
