

# https://www.lucidresearch.org/software

# https://juandes.github.io/FuzzyLogic-R/docs/fuzzy_tutorial

# https://cran.r-project.org/web/packages/sets/vignettes/sets.pdf


# https://www.abebooks.com/book-search/title/fuzzy-sets-and-fuzzy-logic-theory-and-applications/


# https://stats.stackexchange.com/questions/72117/what-is-the-difference-between-probability-and-fuzzy-logic


# custom x,y eval -> charfun_generator(f)


library(sets)




sets_options("universe", NULL)

# pH scale ranges from 0-14
# ideal conditions are roughly 6.5-7.5
# with asymmetric shoulders
pH <- fuzzy_trapezoid_gset(corners = c(5.6, 6.5, 7.5, 7.9), height = 1, universe = seq(0, 14, by = 0.1))


# cation exchange capacity, typically 1-30 cmol [+] / kg soil
# values > 10 are good
CEC <- fuzzy_sigmoid_gset(cross = 10, slope = 0.5, universe = seq(1, 30, by = 0.1))


# sand content, a mass fraction, 0-100%
# values < 85% are ideal
sand <- fuzzy_sigmoid_gset(cross = 85, slope = -0.25, universe = seq(1, 100, by = 1))

par(mfcol = c(1, 3), las = 1, cex.axis = 1.25)
plot(pH, main = 'Soil pH\n<2mm Fraction')
plot(CEC, main = 'Cation Exchange Capacity\n<2mm Fraction')
plot(sand, main = 'Sand %\n<2mm Fraction')







sets_options("universe", NULL)

x <- fuzzy_normal_gset(mean = 10, sd = 2)
y <- fuzzy_normal_gset(mean = 8, sd = 2)
z <- fuzzy_sigmoid_gset(cross = 10, slope = 1)

plot(tuple(x, y, z), lty = 3)

lines(x | y | z, col = 2)
lines(x & y & z, col = 3)

# lines(gset_mean(x, y, z), col = 3, lty = 2)






## set universe
sets_options("universe", seq(from = 0, to = 25, by = 0.1))

## set up fuzzy variables
variables <-
  set(service =
        fuzzy_partition(varnames =
                          c(poor = 0, good = 5, excellent = 10),
                        sd = 1.5),
      food =
        fuzzy_variable(rancid =
                         fuzzy_trapezoid(corners = c(-2, 0, 2, 4)),
                       delicious =
                         fuzzy_trapezoid(corners = c(7, 9, 11, 13))),
      tip =
        fuzzy_partition(varnames =
                          c(cheap = 5, average = 12.5, generous = 20),
                        FUN = fuzzy_cone, radius = 5)
  )

## set up rules
rules <-
  set(
    fuzzy_rule(service %is% poor || food %is% rancid,
               tip %is% cheap),
    fuzzy_rule(service %is% good,
               tip %is% average),
    fuzzy_rule(service %is% excellent || food %is% delicious,
               tip %is% generous)
  )

## combine to a system
system <- fuzzy_system(variables, rules)
print(system)
plot(system) ## plots variables

## do inference
fi <- fuzzy_inference(system, list(service = 3, food = 8))

## plot resulting fuzzy set
# par(n)
plot(fi)

## defuzzify
gset_defuzzify(fi, "centroid")
gset_defuzzify(fi, "meanofmax")

plot(fuzzy_inference(system, list(service = 5, food = 5)))


## reset universe
sets_options("universe", NULL)






sets_options("universe", seq(1, 100, 0.5))


variables <- set(
  temperature = fuzzy_partition(varnames = c(cold = 30, good = 70, hot = 90),
                                sd = 10.0),
  humidity = fuzzy_partition(varnames = c(dry = 30, good = 60, wet = 80), 
                             sd = 3.0),
  precipitation = fuzzy_partition(varnames = c(no.rain = 30, little.rain = 60,
                                               rain = 90), sd = 7.5),
  weather = fuzzy_partition(varnames = c(bad = 40, ok = 65, perfect = 80),
                            FUN = fuzzy_cone, radius = 10)
)

# Fuzzy rules
rules <- set(
  fuzzy_rule(temperature %is% good && humidity %is% dry &&
               precipitation %is% no.rain, weather %is% perfect),
  fuzzy_rule(temperature %is% hot && humidity %is% wet &&
               precipitation %is% rain, weather %is% bad),
  fuzzy_rule(temperature %is% cold, weather %is% bad),
  fuzzy_rule(temperature %is% good || humidity %is% good ||
               precipitation %is% little.rain, weather %is% ok),
  fuzzy_rule(temperature %is% hot && precipitation %is% little.rain,
             weather %is% ok),
  fuzzy_rule(temperature %is% hot && humidity %is% dry &&
               precipitation %is% little.rain, weather %is% ok)
)


model <- fuzzy_system(variables, rules)

par(las = 1)
plot(model)


example.1 <- fuzzy_inference(model, list(temperature = 75, humidity = 0, precipitation = 70))

gset_defuzzify(example.1, "centroid")

plot(example.1)

example.2 <- fuzzy_inference(model, list(temperature = 30, humidity = 0, precipitation = 70))
gset_defuzzify(example.2, "largestofmax")

plot(example.2)


sets_options("universe", NULL)  # Reset the universe


## multisets
(A <- gset(letters[1:5], memberships = c(3, 2, 1, 1, 1)))
(B <- gset(c("a", "c", "e", "f"), memberships = c(2, 2, 1, 2)))

rep(B, 2)
gset_memberships(tuple(A, B), c("a","c"))

gset_union(A, B)
gset_intersection(A, B)
gset_complement(A, B)

gset_is_multiset(A)
gset_sum(A, B)
gset_difference(A, B)

## fuzzy sets
(A <- gset(letters[1:5], memberships = c(1, 0.3, 0.8, 0.6, 0.2)))
(B <- gset(c("a", "c", "e", "f"), memberships = c(0.7, 1, 0.4, 0.9)))
cut(B, 0.5)
A * B
A <- gset(3L, memberships = 0.5, universe = 1:5)
!A

## fuzzy multisets
(A <- gset(c("a", "b", "d"),
           memberships = list(c(0.3, 1, 0.5), c(0.9, 0.1),
                              gset(c(0.4, 0.7), c(1, 2)))))
(B <- gset(c("a", "c", "d", "e"),
           memberships = list(c(0.6, 0.7), c(1, 0.3), c(0.4, 0.5), 0.9)))
gset_union(A, B)
gset_intersection(A, B)
gset_complement(A, B)

## other operations
mean(gset(1:3, c(0.1,0.5,0.9)))
median(gset(1:3, c(0.1,0.5,0.9)))

## vectorization
list(gset(1, 0.5), gset(2, 2L), gset()) <= gset(1, 2L)






