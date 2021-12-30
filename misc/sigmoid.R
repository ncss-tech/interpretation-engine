# investigating weird results from NASIS-style sigmoid curves

targets <- data.frame(x = c(0.5, 0.668, 0.752, 1.004, 1.098901099, 1.396, 1.75, 1.956, 2.208, 2.404, 2.684, 3),
                      y = c(0, 0.00903168, 0.02032128, 0.08128512, 0.115, 0.25690112, 0.5, 0.65122048, 0.79927552, 0.88633088, 0.96804608, 1))
fit <- nls(y ~ SSlogis(x, Asym, xmid, scal), data = targets)
plot(fit)

# targets <- data.frame(x = c(-1, -0.74, -0.5, -0.36, 0),
#                       y = c(0, 0.1352, 0.5, 0.7408, 1))
# fit <- nls(y ~ SSlogis(x, Asym, xmid, scal), data = targets)
# fit
# 
# targets <- data.frame(x = c(-5, -2.2, 0, 2.28, 5.01),
#                       y = c(0, 0.1568, 0.5, 0.852032, 1))
# fit <- nls(y ~ SSlogis(x, Asym, xmid, scal), data = targets)
# fit
# 
# targets <- data.frame(x = c(-1, -0.3, 0, 0.428, 1),
#                       y = c(0, 0.245, 0.5, 0.836408, 1))
# fit <- nls(y ~ SSlogis(x, Asym, xmid, scal), data = targets)
# fit
# 
# targets <- data.frame(x = c(-2, -0.25, 1.5, 2.55, 5),
#                       y = c(0, 0.125, 0.5, 0.755, 1))
# fit <- nls(y ~ SSlogis(x, Asym, xmid, scal), data = targets)


# alternate sigmoid function / compare with stats::plogis()
plogis2 <- function(x, x0, k = 1, L = 1) {
  # use 1/k so that k is analogous to plogis(scale=)
  L / (1 + exp(-((1 / k) * (x - x0))))
}

# scales vector x such that minimum value is 0 and the maximum value is 0
.correctTo01 <- function(x, na.rm = FALSE) {
  x <- x - min(x, na.rm = na.rm)
  x / max(x, na.rm = na.rm)
}

# calculate residual sum of squares
.RSS <- function(y1, y2) {
  sum((y1 - y2) ^ 2)
}

# plogis() function
tst1 <- function(scale, location, x, y) {
  res <- plogis(x, location = location, scale = scale)
  .RSS(.correctTo01(res), y)
}

# plogis2() function
tst2 <- function(scale, location, x, y, maxval = 1) {
  res <- plogis2(x, x0 = location, k = scale, L = maxval)
  .RSS(.correctTo01(res), y)
}

location <- min(targets$x) + (max(targets$x) - min(targets$x)) / 2
resplogis <- optimize(tst1, interval = c(0.01, 10), location = location, x = targets$x, y = targets$y)
resplogis2 <- optimize(tst2, interval = c(0.01, 10), location = location, x = targets$x, y = targets$y)

resplogis$minimum
# when the k parameter is inverted as 1/k in plogis2(), the minima of scale optim is identical to plogis()
resplogis2$minimum
#> [1] 0.3496267 # for location=1.75 [0.5, 3] width = 2.5
#> [1] 1.43014   # for location=0    [-5, 5]  width = 10
#> [1] 0.2869359 # for location=0    [-1, 1]  width = 2
#> [1] 0.1427943 # for location=-0.5 [-1, 0]  width = 1
odf <- data.frame(
    scaleminimum = c(0.3496267, 1.43014, 0.2869359, 0.1427943, 0.9998915),
    lbound = c(0.5,-5,-1, 1, -2),
    ubound = c(3, 5, 1, 0, 5)
  )
odf$width <- abs(odf$ubound - odf$lbound)
scalemod <- lm(scaleminimum ~ width, data = odf)
summary(scalemod)
plot(odf$scaleminimum~odf$width)
abline(scalemod)

predict(scalemod, data.frame(width = 7)) 
# >        1 
# > 0.9998915 
# predict(scalemod, data.frame(width = 7)) / coef(scalemod)[2]
# >        1 
# > 6.982213

# use this one for now
res <- resplogis

res1 <- plogis(targets$x, location = location, scale = res$minimum)
res1 <- res1 - min(res1)
res1 <- res1 / max(res1)

res2 <- plogis2(targets$x, location, k = res$minimum)
res2 <- res2 - min(res2)
res2 <- res2 / max(res2)

plot(res1 ~ targets$x)
lines(res2 ~ targets$x, col = "red", lty=2)
abline(h = targets$y)
abline(v = targets$x)

# yfun <-  function(x) 0.19 * 0.5 * log((1 + x) / (1 - x)) # atanh()


