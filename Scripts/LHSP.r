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

rawF <- read_csv("Output/sims_F.txt") %>%
	 mutate(hatchRate = numSuccess/iterations)

rawM <- read_csv("Output/sims_M.txt") %>%
	 mutate(hatchRate = numSuccess/iterations)

hsF <- rawF %>%
	subset(foragingMean == 151 & minEnergyThresh < maxEnergyThresh) %>%
	select(maxEnergyThresh, minEnergyThresh, hatchRate)

neg <- rawF %>%
	subset(maxEnergyThresh==750 & minEnergyThresh==150) %>%
	mutate(negRate = totNeglect/hatchDays) %>%
	select(foragingMean, negRate, hatchRate)
runApp("Scripts/")


