# evaluation curve plots

## TODO: add critical points
#' Plot Evaluation Curve
#'
#' @param x data
#' @param xlim `plot` xlim default `NULL`
#' @param resolution number of points (default 100)
#' @param pch point character for source domain/range values. Default: `NA`
#' @param ... additional arguments passed to plot
#'
#' @return a plot
#' @export
#' @importFrom graphics grid abline lines points
plotEvaluation <- function(x, xlim=NULL, resolution=100, pch = NA, ...) {
  
  # most evaluation curves return an approxfun() function
  res <- extractEvalCurve(x)
  
  plt.xlim <- FALSE
  
  # default sequence attempts to use min/max range from eval
  # this isn't always useful, as min/max might be way too wide
  if (is.null(xlim)) {
    if (is.na(x$propmin) || is.na(x$propmax)) {
      # crisp expressions return a function of x that can return a logical vector
      stop("Cannot plot CrispExpression: ", attr(res, 'CrispExpression'), " with evaluation propmin/propmax = NA; please specify `xlim`", call. = FALSE)
    }
    s <- seq(x$propmin, x$propmax, length.out = resolution)
    s.range <- range(s)
    xlim <- s.range
  } else {
    if (is.numeric(xlim)) {
      s <- seq(xlim[1], xlim[2], length.out = resolution)
      s.range <- range(s)
    } else {
      s <- xlim
      plt.xlim <- TRUE
    }
  }
  
  x.lab <- paste0(x$propname, ' (', x$propuom, ')')
  if (plt.xlim) {
    # allows for plotting of categorical domains
    plot(res(xlim) ~ factor(xlim),
         xlab = x.lab,
         cex.lab = 0.85,
         ylab = 'fuzzy rating',
         main = x$evalname,
         sub = x$evaluationtype,
         cex.sub = 0.85,
         las = 1,
         ylim = c(0, 1)
    )
  } else {
    plot(0, 0, type = 'n',
      xlab = x.lab,
      cex.lab = 0.85,
      ylab = 'fuzzy rating',
      main = x$evalname,
      sub = x$evaluationtype,
      cex.sub = 0.85,
      las = 1,
      ylim = c(0, 1),
      xlim = xlim,
      ...
    )
    lines(s, res(s))
  }
  
  domain <- attr(res, 'domain')
  resrange <- attr(res, 'range')
  if (length(domain) == length(resrange) && length(domain) > 1)
    points(domain, resrange, pch = pch)
  grid()
  abline(h=c(0,1), lty=2, col='red')
}
