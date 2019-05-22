####################
#### Logistics #####
####################

# library(Rcpp)
library(tidyverse)
library(shiny)
library(gridExtra)
library(cowplot)

setwd("~/Desktop/LHSP")

# # Set C++11 for Rcpp compilation
# Sys.setenv("PKG_CXXFLAGS"="-std=c++11") 

# # NOTE UNCOMMENTING WILL WIPE .o FILES FROM SCRIPTS FOLDER IN WD
# # 		BE CAREFUL
# scriptFiles <- list.files("Scripts/", full.names=TRUE)
# invisible(file.remove(scriptFiles[grep(".o", scriptFiles)]))

# ####################
# ####   Model   #####
# ####################

# # Calls the model through Rcpp
# # All terminal output will write through Rcout onto the R terminal
# # But all objects should be cleaned from memory by the time the model ends
# # The C++ program is self-sufficient and writes output to file
# Rcpp::sourceCpp("Scripts/main.cpp")
# main()

####################
####    DATA   #####
####################

raw <- read_csv("Output/sims.txt") %>%
	mutate(hatchRate = numSuccess/iterations)

runApp("Scripts/")