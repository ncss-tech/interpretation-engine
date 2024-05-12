test_that("lookupProperties works", {
  
  skip_if_offline()
  skip_on_cran()
  
  skip_if_not_installed("rvest")
  skip_if_not_installed("soilDB")
  
  expect_true(inherits(lookupProperties(c(528230), c(37736, 10083)), 'data.frame'))
})
