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


#' Plot the elapsed times of the requests
#'
#' @param results A data frame returned from the loadtest function
#' @return A ggplot2 showing the elapsed times of the requests during the test
#' @examples
#' results <- loadtest("google.com","GET")
#' plot_elapsed_times(result)
#' @export
plot_elapsed_times <- function(results){
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 is needed for this function.",call. = FALSE)
  }
  ggplot2::ggplot(results, ggplot2::aes(x=time_since_start,y=elapsed,color=request_status))+
    ggplot2::geom_point()+
    ggplot2::labs(x="Time since start (milliseconds)",
                  y = "Time to complete request (milliseconds)",
                  color="Request status",
                  title="Time to complete request over duration of test")+
    ggplot2::theme_minimal()+
    ggplot2::scale_color_manual(values=c("#606060", "#E20074"), drop=FALSE)+
    ggplot2::theme(legend.position = "bottom")+
    ggplot2::scale_y_continuous(limits=c(0,NA))+
    ggplot2::geom_hline(yintercept = mean(results$elapsed))
}

#' Plot the elapsed times of the requests as a histogram
#'
#' @param results A data frame returned from the loadtest function
#' @param binwidth The binwidth for the histogram
#' @return A ggplot2 showing the elapsed times of the requests during the test
#' @examples
#' results <- loadtest("google.com","GET")
#' plot_elapsed_times_histogram(results)
#' @export
plot_elapsed_times_histogram <- function(results,binwidth=250){
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 is needed for this function.",call. = FALSE)
  }
  ggplot2::ggplot(results, ggplot2::aes(x=elapsed,fill=request_status))+
    ggplot2::geom_histogram(binwidth=binwidth,color="#606060")+
    ggplot2::scale_x_continuous(breaks=seq(0,max(results[["elapsed"]])*2,binwidth))+
    ggplot2::theme_minimal()+
    ggplot2::scale_fill_manual(values=c("#606060", "#E20074"), drop=FALSE)+
    ggplot2::labs(x="Time to complete response (milliseconds)",fill="Request status",
                  title="Distribution of time to complete responses")+
    ggplot2::theme(legend.position = "bottom")
}

#' Plot the requests per second made during the test
#'
#' @param results A data frame returned from the loadtest function
#' @return A ggplot2 showing the distribution of requests by request per second
#' @examples
#' results <- loadtest("google.com","GET")
#' plot_requests_per_second(results)
#' @export
plot_requests_per_second <- function(results){
  if (!any(c(requireNamespace("ggplot2", quietly = TRUE),
           requireNamespace("dplyr", quietly = TRUE),
           requireNamespace("tidyr", quietly = TRUE)))) {
    stop("Packages ggplot2, dplyr, and tidyr are needed for this function.",call. = FALSE)
  }
  results[["time_since_start_rounded"]] <- floor(results[["time_since_start"]]/1000)

  counts <- dplyr::count(results, time_since_start_rounded)
  counts <- tidyr::complete(counts, time_since_start_rounded=seq(min(time_since_start_rounded),max(time_since_start_rounded),1),fill=list(n=0))
  counts <- dplyr::count(counts,n)
  counts[["p"]] <- counts[["nn"]]/sum(counts[["nn"]])
  counts <- tidyr::complete(counts, n=0:max(n),fill=list(nn=0,p=0))
  counts[["label"]] <- paste0(round(counts[["p"]],2)*100,"%")
  counts[["label"]] <- ifelse(counts[["nn"]] == 0, "", counts[["label"]])

  ggplot2::ggplot(counts, ggplot2::aes(x=n,y=p,label=label))+
    ggplot2::geom_col(fill="#E20074", color="#606060")+
    ggplot2::theme_minimal()+
    ggplot2::geom_text(vjust=-0.5)+
    ggplot2::scale_x_continuous(breaks=seq(0,1000,1))+
    ggplot2::scale_y_continuous(limits=c(0,1),labels=function(x) paste0(round(x,2)*100,"%"))+
    ggplot2::labs(x="Requests per second",y="Percent of time at that rate",
                  title="Distribution of number of responses within a second")
}

#' Plot the requests per second made during the test
#'
#' @param results A data frame returned from the loadtest function
#' @return A ggplot2 showing how each thread's tests went
#' @examples
#' results <- loadtest("google.com","GET")
#' plot_requests_by_thread(results)
#' @export
plot_requests_by_thread <- function(results){
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 is needed for this function.",call. = FALSE)
  }
  results[["thread"]] <- factor(results[["thread"]],levels=1:max(results[["thread"]]))
  ggplot2::ggplot(results,ggplot2::aes(x=time_since_start,y=thread,color=request_status))+
    ggplot2::geom_point()+
    ggplot2::theme_minimal()+
    ggplot2::scale_color_manual(values=c("#606060", "#E20074"), drop=FALSE)+
    ggplot2::labs(x="Time since start (milliseconds)",
                  y="Thread",
                  color="Request status",
                  title="Timeline of requests by thread",
                  caption="Point is at time of the start of request")+
    ggplot2::theme(legend.position = "bottom")
}
