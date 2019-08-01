context("Run a load test using loadtest")
library(loadtest)

test_that("loadtest returns a valid response", {
  threads <- 2
  loops <- 5
  results <- loadtest("https://www.microsoft.com","GET", threads = threads, loops = loops, delay_per_request = 250)
  expect_is(results, "data.frame")
  expect_equal(nrow(results), threads*loops, label = "Table had invalid number of rows")
  expect_true(all(results$request_status=="Success"),label = "Some requests failed")

  expect_is(plot_elapsed_times(results),"ggplot")
  expect_is(plot_elapsed_times_histogram(results),"ggplot")
  expect_is(plot_requests_by_thread(results),"ggplot")
  expect_is(plot_requests_per_second(results),"ggplot")

  save_location <- tempfile(fileext=".html")

  loadtest_report(results,save_location)

  expect_true(file.size(save_location) > 1024^2, label = "Report not generated correctly")

  file.remove(save_location)
})
