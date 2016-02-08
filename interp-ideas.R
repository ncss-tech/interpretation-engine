library(latticeExtra)
library(scales)
library(plyr)
library(reshape)
library(mgcv)


# develop a rating ~ property relationship
poperty.rating <- function(min, max, location=0, scale=1, shape='peak', res=100) {
  
  # generate a sequence along property space
  p <- seq(from=min, to=max, length.out=res)
  
  # logistic function
  if(shape == 'peak')
    i <- dlogis(p, location=location, scale=abs(scale))
  
  # sigmoid shape
  else if(shape == 'sigmoid') 
    i <- plogis(p, location=location, scale=abs(scale))
  
  # catch typos
  else
    stop('must specify `peak` or `sigmoid`', call.=FALSE)
  
  # rescale result to [0,1]
  i.real <- rescale(i, to=c(0, 1))
  
  # flip direction
  if(sign(scale) == -1)
    i.real <- 1 - i.real
  
  return(data.frame(p=p, i=i.real))
}


# generate some fake data to illustrate use of location/scale parameters
d <- expand.grid(min=1, max=60, location=seq(10, 40, by=10), scale=c(-10, -5, 1, 5, 10), shape=c('peak','sigmoid'))

# generate ratings
x <- ddply(d, c('shape', 'location', 'scale'), function(i) poperty.rating(min=i$min, max=i$max, location=i$location, scale=i$scale, shape=i$shape, res=50))

# convert factors, fix labels
x$shape <- factor(x$shape)
x$location <- factor(x$location, labels=paste('location =', unique(x$location)))
x$scale <- factor(x$scale, labels=paste('scale =', unique(x$scale)))

# plot effects of location and scale, update to outer-style strips
pp <- xyplot(i ~ p | location + scale, data=x, groups=shape, type=c('l','g'), auto.key=list(lines=TRUE, points=FALSE, columns=2, title='shape'), scales=list(alternating=3), ylab='Limitation or Suitability', xlab='Soil Property')
useOuterStrips(pp)



# generate some ratings
pH <- poperty.rating(min=4, max=10, location=6.8, shape='sigmoid', res=30)
clay <- poperty.rating(min=4, max=50, location=15, scale=8, shape='peak', res=30)

# stack-up and plot ratings vs. propertiems
xyplot(i ~ p | which , data=make.groups(pH, clay), type=c('l', 'g'), scales=list(x=list(relation='free')), col='black', lwd=2)


# interaction
cols <- colorRampPalette(brewer.pal(8, 'Spectral'))

m <- pH$i %o% clay$i
levelplot(m, row.values=pH$p, column.values=clay$p, aspect='fill', xlab='Soil Property A', ylab='Soil Property B', col.regions=cols)



###
### use for 2015 SSSA talk
###

# generate some ratings
pH <- poperty.rating(min=4, max=10, location=6.8, shape='peak', res=30)
clay <- poperty.rating(min=4, max=50, location=30, scale=-8, shape='sigmoid', res=30)
Db <- poperty.rating(min=0.8, max=2.4, location=1.2, scale=0.5, shape='peak', res=5)

# stack-up and plot ratings vs. propertiems
xyplot(i ~ p | which , data=make.groups(pH, clay, Db), type=c('l', 'g'), scales=list(x=list(relation='free')), col='black', lwd=2)

col.list <- c(grey(c(0.5,0.9)), brewer.pal(9, 'Spectral')[-c(1,2)], 'purple')
cols <- colorRampPalette(col.list, space='Lab', interpolate='linear')

m <- pH$i %o% clay$i %o% Db$i
# dimnames(m) <- list(pH$p, clay$p, c('Db < 1 g/cc', 'Db 1.2 g/cc', 'Db 1.6 g/cc', 'Db 2.0 g/cc', 'Db > 2.4 g/cc'))
dimnames(m) <- list(pH$p, clay$p, c('Low Density', 'Ideal Density', 'Slight Compaction', 'Moderate Compaction', 'High Compaction'))

# annotate with values at closest to named pH values
pH.value <- sapply(c(5, 7, 9), function(i) which.min(abs(pH$p - i)))
pH.value.label <- round(pH$p[pH.value])

# locate values where suitability is closest to select fuzzy or real values
# clay.value <- sapply(c(0.25, 0.75, .99), function(i) which.min(abs(clay$i - i)))
clay.value <- sapply(c(8,18,35), function(i) which.min(abs(clay$p - i)))
clay.value.label <- round(clay$p[clay.value])  

png(file='interp-simulation.png', width=2400, height=900, antialias = 'cleartype', res=120)
levelplot(m, as.table=TRUE, main=list('Soil Suitability Rating', cex=2), aspect='fill', xlab=list('Soil pH', cex=2), ylab=list('Clay Content (%)', cex=2), col.regions=cols, cuts=100, scales=list(x=list(alternating=1, at=pH.value, label=pH.value.label, cex=1.5), y=list(alternating=3, at=clay.value, label=clay.value.label, cex=1.5)), colorkey=list(space='top', labels=list(cex=2)), strip=strip.custom(bg='white'), par.strip.text=list(cex=1.5), par.settings=list(layout.heights=list(key.axis.padding=1)), layout=c(5,1), panel=function(x, ...){
  panel.levelplot(x=x, ...)
  panel.abline(h=clay.value, v=pH.value, lty=3)
}) + contourplot(m, at=c(0.05, 0.15, 0.55, 0.85), label.stye='align', labels=list(labels=c('unsuited','poor', 'moderate', 'good'), font=2, cex=1.25), lwd=0.8)

dev.off()


# extract a value based on parameters
m <- pH$i %o% clay$i
m[which.min(abs(6 - pH$p)), which.min(abs(21 - clay$p))]


# or a slice
m <- pH$i %o% clay$i %o% Db$i
plot(Db$p, m[which.min(abs(8 - pH$p)), which.min(abs(12 - clay$p)), ])
levelplot(m[, ,which.min(abs(2 - Db$p)) ], row.values=pH$p, column.values=clay$p, aspect='fill', xlab='pH', ylab='clay', col.regions=cols)


