library(InterpretationEngine)

# property value -- e.g. random slope slope gradient (%) in [8,60] at 100 locations
property <- runif(367, 8, 60)

# evaluation e.g. Slope 15% to 25%
#> subset(NASIS_evaluations, evalname == "Slope 15% to 25%")$evaliid
#> [1] 51407

e <- NASIS_evaluations[NASIS_evaluations$evaliid == 51407, ]

rating <- extractEvalCurve(e)(property)

# current behavior: x axis is row index, y axis is rating
plot(rating)

# histogram, note default break to have separate bin for min/maxed out values == 0 or 1
hrating <- rating
hrating[hrating == 1.00] <- 1.01
hist(hrating, breaks = c(-0.01, seq(0, 1, 0.1), 1.01), freq = TRUE, include.lowest = FALSE)

# points on evaluation curve
plotEvaluation(e, xlim = c(0, 60))
points(property, rating)

# sorted on rating: x axis is row index, y axis is rating
plot(sort(rating))

# sorted on rating: y axis is cumulative proportion of input data, x axis is rating
plot(sort(rating), 
     seq(0, 1, 1 / length(rating))[-length(rating)], 
     ylab = "Cumulative Proportion of Dataset",
     xlim = c(0, 1))

# maybe better?
# sorted on rating: x axis is cumulative proportion of input data, y axis is rating
plot(seq(0, 1, 1 / length(rating))[-length(rating)], 
     sort(rating), 
     xlab = "Cumulative Proportion of Dataset", 
     ylim = c(0, 1))

# density plot: x axis is rating, y axis is probability density (frequency of ratings)
plot(density(rating, from = 0, to = 1, width = 0.01))


