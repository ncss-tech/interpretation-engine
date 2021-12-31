storie_c_factor <- list(DomainPoints = c(0, 1, 3, 8, 15, 30, 45, 60, 75, 100, 200), 
                        RangePoints = c(1, 1, 0.95, 0.9, 0.85, 0.7, 0.5, 0.4, 0.3, 0.25, 0.1))
storie_c_factor_xml <- "<?xml version=\"1.0\" encoding=\"utf-16\"?>\r\n<EvaluationParameter xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\r\n  <DomainPoints>\r\n    <double>0</double>\r\n    <double>1</double>\r\n    <double>3</double>\r\n    <double>8</double>\r\n    <double>15</double>\r\n    <double>30</double>\r\n    <double>45</double>\r\n    <double>60</double>\r\n    <double>75</double>\r\n    <double>100</double>\r\n    <double>200</double>\r\n  </DomainPoints>\r\n  <RangePoints>\r\n    <double>1</double>\r\n    <double>1</double>\r\n    <double>0.95</double>\r\n    <double>0.9</double>\r\n    <double>0.85</double>\r\n    <double>0.7</double>\r\n    <double>0.5</double>\r\n    <double>0.4</double>\r\n    <double>0.3</double>\r\n    <double>0.25</double>\r\n    <double>0.1</double>\r\n  </RangePoints>\r\n</EvaluationParameter>"

test_that(".CVIRSplineDerivative works", {
  d <-storie_c_factor$DomainPoints
  r <- storie_c_factor$RangePoints
  dydx <- .CVIRSplineDerivative(d, r)
  expect_equal(round(.CVIRSplinePoint(d, r, dydx, 1, 2, 0), 2), 1.00)
  expect_equal(round(.CVIRSplinePoint(d, r, dydx, 1, 2, 0.5), 2), 1.00)
  expect_equal(round(.CVIRSplinePoint(d, r, dydx, 1, 2, 1), 2), 1.00)
  expect_equal(round(.CVIRSplinePoint(d, r, dydx, 2, 3, 3), 2), 0.95)
  expect_equal(round(.CVIRSplinePoint(d, r, dydx, 5, 6, 25), 2), 0.76)
  FUN <- .CVIRSplineInterpolator(storie_c_factor_xml)
  expect_equal(round(FUN(c(0, 0.5, 1, 3, 25)), 2), c(1.00, 1.00, 1.00, 0.95, 0.76))
})

