# =========================================================================
# Copyright © 2019 T-Mobile USA, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# See the LICENSE file for additional language around disclaimer of warranties.
# Trademark Disclaimer: Neither the name of "T-Mobile, USA" nor the names of
# its contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
# =========================================================================

library(loadtest)

test_that("loadtest returns a valid response", {
  threads <- 2
  loops <- 5
  results <- loadtest("https://www.microsoft.com", threads = threads, loops = loops, delay_per_request = 250)
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

test_that("loadtest works with more method/headers/body", {
  threads <- 2
  loops <- 5
  results <- loadtest("http://httpbin.org/post",
                      method = "POST",
                      headers = c("version" = "v1.0"),
                      body = list(text = "example text"),
                      encode = "json",
                      threads = threads,
                      loops = loops,
                      delay_per_request = 250)
  expect_is(results, "data.frame")
  expect_equal(nrow(results), threads*loops, label = "Table had invalid number of rows")
  expect_true(all(results$request_status=="Success"),label = "Some requests failed")

  results <- loadtest("https://jsonplaceholder.typicode.com/comments?postId=1&userId=1",
                      method = "GET",
                      threads = threads,
                      loops = loops,
                      delay_per_request = 250)

  expect_is(results, "data.frame")
  expect_equal(nrow(results), threads*loops, label = "Table had invalid number of rows")
  expect_true(all(results$request_status=="Success"),label = "Some requests failed")
})

test_that("query string is correctly parsed", {
  query_string <- "postId=1&userId=1&whatever=888"
  result <- loadtest:::parse_query_string(query_string)

  expect_is(result, "list")
  expect_equal(names(result), c("postId", "userId", "whatever"))
  expect_equal(result$postId[[1]], "1")
  expect_equal(result$userId[[1]], "1")
  expect_equal(result$whatever[[1]], "888")

  query_string <- "postId=1&userId=1&whatever="
  expect_warning(loadtest:::parse_query_string(query_string),
                "The following parameters did not have a value and were dropped: whatever")

  query_string <- "postId=1&userId=1&userId=8"
  expect_warning(loadtest:::parse_query_string(query_string),
                 "Duplicate parameters found, using only the first occurence of: userId")

  result <- suppressWarnings(loadtest:::parse_query_string(query_string))
  expect_equal(names(result), c("postId", "userId"))
  expect_equal(result$postId[[1]], "1")
  expect_equal(result$userId[[1]], "1")
})

test_that("query path is correctly parsed", {
  expect_equal(
    loadtest:::parse_url("https://jsonplaceholder.typicode.com/"),
    list(protocol = "https", domain = "jsonplaceholder.typicode.com",
         path = "/", port = "443")
  )

  expect_equal(
    loadtest:::parse_url("https://jsonplaceholder.typicode.com/comments?postId=1&userId=1"),
    list(protocol = "https", domain = "jsonplaceholder.typicode.com",
         path = "/comments", port = "443",
         query_parameters = list(postId = "1", userId = "1"))
  )
})
