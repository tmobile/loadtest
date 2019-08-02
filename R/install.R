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


#' Command for the jmeter executable
#'
#' The command to call to run jmeter. Usually just "jmeter",
#' but you can use Sys.setenv("LOADTEST_JMETER_PATH") to specify the location if
#' jmeter isn't in the path environment variable
#'
#' @return A string with the command to run for jmeter
jmeter_path <- function(){
  jmeter_env_path = Sys.getenv("LOADTEST_JMETER_PATH")
  if(jmeter_env_path != ""){
    jmeter_env_path
  } else {
    "jmeter"
  }
}

#' Command for the java executable
#'
#' The command to call java. Usually just "java",
#' but you can use Sys.setenv("LOADTEST_JAVA_PATH") to specify the location if
#' java isn't in the path environment variable. This is only used for checking
#' that the package should work when loaded, so it's not important to change unless you hate the warning
#' any circumstance.
#'
#' @return A string with the command to run for jmeter
java_path <- function(){
  java_env_path = Sys.getenv("LOADTEST_JAVA_PATH")
  if(java_env_path != ""){
    java_env_path
  } else {
    "java"
  }
}


check_java_installed <- function(){
  tryCatch({
    if(!nzchar(Sys.which(java_path()))){
      warning("Unable to find Java installation. https://github.com/tmobile/loadtest#installation")
      FALSE
    } else {
      TRUE
    }
  }, error = function(e){
    warning("Unable to find Java installation. https://github.com/tmobile/loadtest#installation")
  })
  TRUE
}

check_jmeter_installed <- function(){
  tryCatch({
    if(!nzchar(Sys.which(jmeter_path()))){
      warning("Unable to find JMeter installation. https://github.com/tmobile/loadtest#installation")
      FALSE
    } else {
      TRUE
    }
  }, error = function(e){
    warning("Unable to find JMeter installation. https://github.com/tmobile/loadtest#installation")
  })
  TRUE
}
