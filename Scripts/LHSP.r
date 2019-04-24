####################
#### Logistics #####
####################

library(Rcpp)
library(tidyverse)
library(gridExtra)
library(cowplot)
library(EnvStats)
library(magrittr)
require(purrr)

# setwd("~/LHSP")

# Set C++11 for Rcpp compilation
Sys.setenv("PKG_CXXFLAGS"="-std=c++11") 

####################
####   Model   #####
####################

# Calls the model through Rcpp
# All terminal output will write through Rcout onto the R terminal
# But all objects should be cleaned from memory by the time the model ends
# The C++ program is self-sufficient and writes output to file


# NOTE UNCOMMENTING WILL WIPE .o FILES FROM SCRIPTS FOLDER IN WD/SCRIPT
# 		BE CAREFUL
scriptFiles <- list.files("Scripts/", full.names=TRUE)
invisible(file.remove(scriptFiles[grep(".o", scriptFiles)]))

Rcpp::sourceCpp("Scripts/main.cpp")
main()

####################
####    DATA   #####
####################

overlaps <- read_csv("Output/overlap_swap_output.txt")


futureSuccess <- function(energy, successRate) {
	mortalityRisk = 0.03 + (100-energy)/500
	lifeSuccess <- successRate / mortalityRisk
	return(lifeSuccess)
}

negs <- overlaps %>%
	   group_by(maxEnergyThreshold) %>%
	   summarise(gNeg = geoMean(neglect+1))

energies <- overlaps %>%
	      subset(meanEnergy_F > 0) %>%
	      group_by(maxEnergyThreshold) %>%
	      summarise(gMeanEnergy = geoMean(meanEnergy_F))

success <- overlaps %>%
		group_by(maxEnergyThreshold, hatchSuccess) %>%
		count() %>%
		spread(key=hatchSuccess, value=n) %>%
		set_colnames(c("maxEnergyThreshold", "fail", "hatch")) %>%
		transmute(successRate=hatch / (fail+hatch))

overlap_summary <- left_join(negs, energies) %>%
		   	left_join(success) %>%
		   	mutate(lrs=map2_dbl(gMeanEnergy,successRate, futureSuccess))

####################
## Visualization ###
####################

THEME_LT <- theme_bw() +
	    theme(panel.grid.minor=element_blank(),
		  axis.title=element_text(size=10),
		  axis.text=element_text(size=8),
		  plot.title=element_text(size=12),
		  panel.grid=element_blank())

g1 <- ggplot(overlap_summary) +
	geom_line(aes(x=maxEnergyThreshold, y=lrs), size=0.6) +
	ylab(expression(Predicted~R['0'])) +
	xlab(expression(H[f])) +
	THEME_LT

# max lrs @ maxEnergyThresh = 0.6
ggsave(g1, filename="Output/h_by_lrs.png", width=4.5, height=2)

ggplot(overlap_summary) +
	geom_line(aes(x=maxEnergyThreshhold, y=gNeg), size=0.6) +
	