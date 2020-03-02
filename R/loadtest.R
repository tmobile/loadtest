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


#' Convert a query string into its parts
#'
#' This function gets the query parameters from a url as input,
#' and outputs a list. Each element's name is the name of the parameters,
#' and each element's value is the parameter's value.
#'
#' @param query_string a string containing the query parameters e.g.: "postId=1&userId=1"
#'
#' @return a list
#'
#' @examples
#' parse_query_string("postId=1&userId=1")
parse_query_string <- function(query_string) {
  query_parts <- strsplit(query_string, "&", fixed = TRUE)[[1]]
  parameters <- strsplit(query_parts, "=", fixed = TRUE)
  valid_parameters <- parameters[sapply(parameters, length) == 2]

  if (length(valid_parameters) < length(parameters)) {
    warning(
      paste("The following parameters did not have a value and were dropped:",
            paste(sapply(setdiff(parameters, valid_parameters), "[[", 1), collapse = ", "))
    )
  }

  keys <- sapply(valid_parameters, "[[", 1)
  decoded_keys <- unname(sapply(keys, URLdecode))

  parameter_values <- sapply(valid_parameters, "[[", 2)
  decoded_values <- unname(sapply(parameter_values, URLdecode))

  return_list <- as.list(setNames(decoded_values, decoded_keys))

  unique_names <- unique(names(return_list))

  if (length(unique_names) < length(names(return_list))) {
    warning(
      paste("Duplicate parameters found, using only the first occurence of:",
            paste(names(return_list)[duplicated(return_list)]), collapse = ", ")
    )
  }

  return_list[unique_names]
}


#' Convert a url into core components
#'
#' This code takes a url and breaks it into several components
#' \describe{
#' \item{protocol}{Either http or https}
#' \item{domain}{The base domain, such as https://www.t-mobile.com}
#' \item{path}{The path after the base domain such as /mail/account=1}
#' \item{port}{The port to use, either 80 for HTTP, 443 for HTTPS, or anything if explicitly set like :8000 after a domain}
#' }
#'
#' @param url a string containing a url
#'
parse_url <- function(url){
  # split the url into its core parts
  parsed_url <- regmatches(url,regexec("(https?://)?(.*?)(:[0-9]+)?((/.*)|$)", url))[[1]]
  # find the protocol. Assume HTTP unless explicitly stated
  if(parsed_url[[2]]==""){
    protocol <- "http"
  } else if(parsed_url[[2]] == "https://"){
    protocol <- "https"
  } else {
    protocol <- "http"
  }

  domain <- gsub("/", "", parsed_url[[3]])
  full_path <- parsed_url[[5]]
  path_elements <- strsplit(parsed_url[[5]], "\\?")

  if (length(path_elements[[1]]) == 0) {
    path <- "/"
  } else {
    path <- path_elements[[1]][[1]]
  }

  # find the port
  port <- parsed_url[[4]]
  port <- gsub(":", "", parsed_url[[4]])
  if(port==""){
    if(protocol == "https"){
      port <- "443"
    } else {
      port <- "80"
    }
  }

  if (length(path_elements[[1]]) > 1) {
    query_parameters <- plumber:::parseQS(path_elements[[1]][[2]])
    return(
      list(protocol = protocol, domain = domain, path = path, port = port,
           query_params = query_parameters)
    )
  }

  list(protocol = protocol, domain = domain, path = path, port = port)
}

#' Run a load test of an HTTP request
#'
#' This is the core function of the package, which creates many HTTP requests using Apache JMeter.
#' In this function, you specify a URL and HTTP method along with how many times to hit the URL,
#' then the function calls JMeter to run a load test. For requests that require special headers or
#' a body, you can specify them as well.
#'
#' @param url The url to hit as part of the test, such as https://www.t-mobile.com .
#' @param method The HTTP method to use. Defaults to "GET" but other common choices are "POST", "PUT", and "DELETE".
#' @param body A list to be encoded as a json object to use as the body of the HTTP request.
#' @param headers A named character vector of headers to use as part of HTTP request. The names are the keys and the vector contents are the values.
#' @param encode The method of encoding the body, if it exists.
#' @param threads The number of threads to concurrently run in the test.
#' @param loops The number of times each thread should hit the endpoint.
#' @param ramp_time The time (in seconds) that it should take before all threads are firing.
#' @param delay_per_request A delay (in milliseconds) after a thread completes before it should make its next request.

#' Raw assumes the body is a character and preserves it.
#' Json converts a list into json like the pacakge httr.
#' @return A data.frame containing the JMeter test results of the HTTP requests made during the tests. The columns
#' have the following specification.
#' \describe{
#'   \item{request_id}{An intentifier for each request. An integer from 1 to the number of requests}
#'   \item{start_time}{The time the request was started, as a POSIXct.}
#'   \item{thread}{The thread the request was made from (from 1 to n, where n is the number of threads)}
#'   \item{threads}{The number of open threads at the time the request was made. Should decrease to 1 as the requests finish.}
#'   \item{response_code}{The response code of the HTTP request, such as 200, 403, or 500.
#'   A character that should be able to be converted to an integer, but may be a string be if an error occurred.}
#'   \item{response_message}{The message of the response. May be an error if the request fails.}
#'   \item{request_status}{A factor for if the request succeeded (Success/Failure)}
#'   \item{sent_bytes}{The number of bytes sent in the request.}
#'   \item{received_bytes}{The number of bytes received in the request.}
#'   \item{time_since_start}{The number of milliseconds after the test started that the request started.
#'   Useful for plotting the time the request occurred relative to the start of the test.
#'   You will need to add other values to this (such as elapsed) to measure end times of requests.}
#'   \item{elapsed}{The number of milliseconds that elapsed between when the request started and when the response was finished being received.}
#'   \item{latency}{The number of milliseconds that elapsed between when the request started and when the response began. Thus, this
#'   does not include the time it takes to receive the request, which can matter for a large download.
#'   This is included in the elapsed time (and is at most equal to).}
#'   \item{connect}{The number of milliseconds needed to make the connection. This is included in both the elapsed and latency measures,
#'   but it may need to be removed depending on what should be measured.}
#' }
#'
#' @examples
#' # a simple GET request
#' results <- loadtest(url = "https://www.t-mobile.com", threads = 2, loops = 5)
#'
#' # a more complex POST request
#' results <- loadtest(url = "http://deepmoji.teststuff.biz",
#'                     method = "POST",
#'                     headers = c("version"="v1.0"),
#'                     body = list(sentences = list("I love this band")),
#'                     encode = "json",
#'                     threads = 1,
#'                     loops = 15,
#'                     delay_per_request = 100)
#' @export
loadtest <- function(url,
                     method = c("GET", "POST", "HEAD", "TRACE", "OPTIONS", "PUT", "DELETE"),
                     headers = NULL,
                     body = NULL,
                     encode = c("raw","json"),
                     threads = 1,
                     loops = 16,
                     ramp_time = 0,
                     delay_per_request = 0){

  invisible(check_java_installed())
  invisible(check_jmeter_installed())

  # set up the test specification file ---------------------
  method <- match.arg(method)
  encode <- match.arg(encode)

  parsed_url <- parse_url(url)
  protocol <- parsed_url$protocol
  domain <- parsed_url$domain
  path <- parsed_url$path
  port <- parsed_url$port
  query_parameters <- parsed_url$query_parameters

  read_file_as_char <- function(file_name){
    readChar(file_name, file.info(file_name)$size)
  }

  template <- read_file_as_char(system.file("template.jmx", package = "loadtest")) # tempate for the full request
  header_template <- read_file_as_char(system.file("header_template.txt", package = "loadtest")) # template for each request header
  body_template <- read_file_as_char(system.file("body_template.txt", package = "loadtest")) # template for the request body, if one is needed
  query_parameters_template <- read_file_as_char(system.file("query_parameters_template.txt", package = "loadtest")) # template for the query parameters, if one is needed

  original_headers <- headers
  original_body <- body

  if(is.null(headers)){
    headers <- c()
  }

  if(encode=="json"){
    headers = c(headers,c("Content-Type"="application/json"))
  }

  if(length(headers) > 0){
    headers_in_template <- lapply(seq_along(headers), function(i) glue::glue(header_template,name=names(headers)[[i]],value=headers[[i]]))
    headers <- paste0(headers_in_template,collapse="\n")
  } else {
    headers <- ""
  }

  if(!is.null(body)){

    if(encode=="json"){
      request_body <- gsub("\"", "&quot;", jsonlite::toJSON(body,auto_unbox=TRUE))
    } else if(encode=="raw"){
      request_body <- gsub("\"", "&quot;", body)
    } else {
      stop("'encode' value not yet supported")
    }
    body <- glue::glue(body_template,request_body = request_body)
  } else {
    body <- ""
  }

  if (!is.null(query_parameters)) {
    query_parameters_in_template <- lapply(seq_along(query_parameters), function(i) glue::glue(query_parameters_template, name=names(query_parameters)[[i]],value=query_parameters[[i]]))
    query_parameters <- paste0(query_parameters_in_template,collapse="\n")
  } else {
    query_parameters <- ""
  }

  # where to save the test specification
  spec_location <- tempfile(fileext = ".jmx")

  # where to save the results
  save_location <- tempfile(fileext = ".csv")

  # the full test specification
  jmx_spec <- glue::glue(template)

  # save the specification
  write(jmx_spec, spec_location)

  # run the test -----------------------------
  message("loadtest - beginning load test")
  system2(jmeter_path(),args=c("-n","-t",spec_location,"-l",save_location), stdout="")
  message("loadtest - completed load test")

  # read back in the results as a data frame -------------------------------
  output <- read.csv(save_location,
                            stringsAsFactors = FALSE,
                            colClasses = c(
                              timeStamp = "numeric",
                              elapsed = "numeric",
                              label = "NULL",
                              responseCode = "character",
                              responseMessage = "character",
                              threadName = "character",
                              success = "logical",
                              failureMessage = "NULL",
                              bytes = "numeric",
                              sentBytes = "numeric",
                              grpThreads = "NULL",
                              allThreads = "numeric",
                              Latency = "numeric",
                              IdleTime = "numeric",
                              Connect = "numeric"
                            ))
  names(output) <- c("start_time", "elapsed", "response_code","response_message", "thread",
                     "request_status", "received_bytes", "sent_bytes", "threads", "latency", "idle", "connect")

  output[["start_time"]] <- as.POSIXct(output[["start_time"]]/1000, origin="1970-01-01")
  output[["time_since_start"]] <- round(as.numeric(output[["start_time"]]-min(output[["start_time"]]))*1000)
  output[["thread"]] <- as.integer(gsub("^Thread Group 1-", "", output[["thread"]]))
  output[["request_id"]] <- 1:nrow(output)
  output[["request_status"]] <- factor(ifelse(output[["request_status"]],"Success","Failure"),c("Failure","Success"))
  output <- output[,c("request_id", "start_time", "thread", "threads", "response_code", "response_message",
                      "request_status", "sent_bytes", "received_bytes", "time_since_start", "elapsed", "latency", "connect")]

  attr(output, "config") <- list(url=url,
                                 method=method,
                                 headers=original_headers,
                                 body=original_body)
  tryCatch({
    file.remove(spec_location)
    file.remove(save_location)
    file.remove("jmeter.log")
  }, error = function(e){
    warning("Unable to remove created temp files")
  })
  output
}

