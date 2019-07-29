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
# =========================================================================




#' loadtest: load testing directly from R
#'
#' This package has the loadtest() function, which allows you to run a load test for
#' an HTTP request, and returns a summary data frame. It also includes helper functions
#' to create plots and reports
#'
#' @docType package
#' @name loadtest-package
NULL


check_java_installed <- function(){
  tryCatch({
    version <- system2("java","-version", stdout=TRUE, stderr=TRUE)
    if(length(version) == 0){
      warning("Unable to check if Java installed")
      FALSE
    } else {
      version <- regmatches(version[1],regexec("^java version \"([0-9\\.]+)\"", version[1]))[[1]][2]
      main_version <- as.numeric(regmatches(version[1],regexec("^([0-9]+).", version[1]))[[1]][2])
      if(main_version < 8){
        stop("Java must be version 8+")
      }
      TRUE
    }

  }, error = function(e){
    stop("Java missing or incorrectly installed")
  })
  TRUE
}

check_jmeter_installed <- function(){
  tryCatch({
    version <- system2("jmeter","--version", stdout=TRUE, stderr=TRUE)
    if(length(version) == 0){
      warning("Unable to check if JMeter installed")
      FALSE
    } else {
      TRUE
    }
  }, error = function(e){
    stop("JMeter missing or incorrectly installed")
  })
  TRUE
}
