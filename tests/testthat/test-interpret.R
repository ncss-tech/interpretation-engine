test_that("interpret works", {
  r <- initRuleset("Erodibility Factor Maximum")
  p <- getPropertySet(r)

  my_data <- data.frame(Kmax = seq(0, 1, 0.01))
  colnames(my_data) <- make.names(p$propname)

  res <- interpret(r, my_data)
  expect_equal(res$rating[1], 1.0, tolerance = 0.001)
  expect_equal(res$rating[50], 0.679902, tolerance = 0.001)
  expect_equal(res$rating[101], 0.058775, tolerance = 0.001)
})
