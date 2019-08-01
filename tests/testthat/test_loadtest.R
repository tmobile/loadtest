context("Run a load test using loadtest")
library(loadtest)

test_that("loadtest returns a valid response", {
  threads <- 1
  loops <- 10
  result <- loadtest("https://www.microsoft.com","GET", threads = threads, loops = loops, delay_per_request = 500)
  expect_is(result, "data.frame")
  expect_equal(nrow(result), threads*loops)
  expect_true(all(result$request_status=="Success"))

  expect_is("ggplot")
})
