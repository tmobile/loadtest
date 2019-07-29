context("Run a load test using loadtest")
library(loadtest)

test_that("loadtest returns a valid data.frame", {
  threads <- 3
  loops <- 4
  result <- loadtest("https://www.google.com","GET", num_threads = threads, loops = loops)
  expect_is(result, "data.frame")
  expect_equal(nrow(result), threads*loops)
  expect_true(all(result$request_status=="Success"))
})
