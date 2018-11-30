# logistics
library(Rcpp)
library(tidyverse)

setwd("~/Desktop/LHSP")
Sys.setenv("PKG_CXXFLAGS"="-std=c++11")

Rcpp::sourceCpp("Scripts/main.cpp")
main()

d <- read_csv("Output/test.txt")
head(d)