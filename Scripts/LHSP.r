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
futureSuccess <- function(energy, successRate) {
	mortalityRisk = 0.03 + (100-energy)/500
	lifeSuccess <- successRate / mortalityRisk
	return(lifeSuccess)
}

fname <- "incubation_metabolism_output.txt"
overlaps <- read_csv(paste("Output/", fname, sep=""))

overlaps %>% group_by(incubationMetabolism) %>% count()

negs <- overlaps %>%
	   group_by(incubationMetabolism) %>%
	   summarise(gNeg = geoMean(neglect+1),
	   	     n=n())

energies <- overlaps %>%
	      subset(meanEnergy_F > 0) %>%
	      group_by(incubationMetabolism) %>%
	      summarise(gMeanEnergy = geoMean(meanEnergy_F))

success <- overlaps %>%
		group_by(incubationMetabolism, hatchSuccess) %>%
		count() %>%
		spread(key=hatchSuccess, value=n, fill=0) %>%
		set_colnames(c("incubationMetabolism", "fail", "hatch")) %>%
		transmute(successRate=hatch / (fail+hatch))

incMetSum <- left_join(negs, energies) %>%
		   left_join(success)

fname <- "foraging_metabolism_output.txt"
overlaps <- read_csv(paste("Output/", fname, sep=""))

overlaps %>% group_by(foragingMetabolism) %>% count()

negs <- overlaps %>%
	   group_by(foragingMetabolism) %>%
	   summarise(gNeg = geoMean(neglect+1),
	   	     n=n())

energies <- overlaps %>%
	      subset(meanEnergy_F > 0) %>%
	      group_by(foragingMetabolism) %>%
	      summarise(gMeanEnergy = geoMean(meanEnergy_F))

success <- overlaps %>%
		group_by(foragingMetabolism, hatchSuccess) %>%
		count() %>%
		spread(key=hatchSuccess, value=n, fill=0) %>%
		set_colnames(c("foragingMetabolism", "fail", "hatch")) %>%
		transmute(successRate=hatch / (fail+hatch))

forMetSum <- left_join(negs, energies) %>%
		   left_join(success) 

fname <- "maxEnergy_output.txt"
overlaps <- read_csv(paste("Output/", fname, sep=""))

overlaps %>% group_by(maxEnergyThreshold) %>% count()

negs <- overlaps %>%
	   group_by(maxEnergyThreshold) %>%
	   summarise(gNeg = geoMean(neglect+1),
	   	     n=n())

energies <- overlaps %>%
	      subset(meanEnergy_F > 0) %>%
	      group_by(maxEnergyThreshold) %>%
	      summarise(gMeanEnergy = geoMean(meanEnergy_F))

success <- overlaps %>%
		group_by(maxEnergyThreshold, hatchSuccess) %>%
		count() %>%
		spread(key=hatchSuccess, value=n, fill=0) %>%
		set_colnames(c("maxEnergyThreshold", "fail", "hatch")) %>%
		transmute(successRate=hatch / (fail+hatch))

maxEneSum <- left_join(negs, energies) %>%
		   left_join(success) %>%
		   mutate(lrs=map2_dbl(gMeanEnergy,successRate,futureSuccess))

####################
## Visualization ###
####################

THEME_LT <- theme_bw() +
	    theme(panel.grid.minor=element_blank(),
		  axis.title=element_text(size=10),
		  axis.text=element_text(size=8),
		  plot.title=element_text(size=12),
		  panel.grid=element_blank())


g1 <- ggplot(incMetSum) +
	geom_line(aes(x=incubationMetabolism, y=gNeg), size=0.6) +
	xlab(expression(alpha)) +
	scale_y_continuous(limits=c(0, 30)) +
	ylab("Neglect")	+
	THEME_LT

g2 <- ggplot(incMetSum) +
	geom_line(aes(x=incubationMetabolism, y=gMeanEnergy), size=0.6) +
	xlab(expression(alpha)) +
	scale_y_continuous(limits=c(0, 160)) +
	ylab("Energy") +
	THEME_LT

g3 <- ggplot(incMetSum) +
	geom_line(aes(x=incubationMetabolism, y=successRate), size=0.6) +
	xlab(expression(alpha)) +
	scale_y_continuous(limits=c(0, 1)) +
	ylab("Hatching success rate") +
	THEME_LT

g4 <- ggplot(forMetSum) +
	geom_line(aes(x=foragingMetabolism, y=gNeg), size=0.6) +
	xlab(expression(beta)) +
	scale_y_continuous(limits=c(0, 30)) +
	ylab("Neglect") +
	THEME_LT

g5 <- ggplot(forMetSum) +
	geom_line(aes(x=foragingMetabolism, y=gMeanEnergy), size=0.6) +
	xlab(expression(beta)) +
	scale_y_continuous(limits=c(0, 160)) +
	ylab("Energy") +
	THEME_LT

g6 <- ggplot(forMetSum) +
	geom_line(aes(x=foragingMetabolism, y=successRate), size=0.6) +
	xlab(expression(beta)) +
	scale_y_continuous(limits=c(0, 1)) +
	ylab("Hatching success rate") +
	THEME_LT

g7 <- ggplot(maxEneSum) +
	geom_line(aes(x=maxEnergyThreshold, y=gNeg), size=0.6) +
	xlab(expression(H[F])) +
	scale_y_continuous(limits=c(0, 30)) +
	ylab("Neglect") +
	THEME_LT

g8 <- ggplot(maxEneSum) +
	geom_line(aes(x=maxEnergyThreshold, y=gMeanEnergy), size=0.6) +
	xlab(expression(H[F])) +
	scale_y_continuous(limits=c(0, 160)) +
	ylab("Energy") +
	THEME_LT

g9 <- ggplot(maxEneSum) +
	geom_line(aes(x=maxEnergyThreshold, y=successRate), size=0.6) +
	xlab(expression(H[F])) +
	scale_y_continuous(limits=c(0, 1)) +
	ylab("Hatching success rate") +
	THEME_LT

fullG <- plot_grid(g1, g2, g3, g4, g5, g6, g7, g8, g9, ncol=3, labels="AUTO")
ggsave(fullG, filename="Output/Figure_1.png", width=8, height=8)

maxR0 <- maxEneSum %>%
	  arrange(-lrs) %>%
	  top_n(1)

gLRS <- ggplot(maxEneSum) +
	  geom_line(aes(x=maxEnergyThreshold, y=lrs), size=0.6) +
	  geom_vline(aes(xintercept=maxR0$maxEnergyThreshold),
	  		colour="gray", linetype="dashed") +
	  xlab(expression(H[F])) +
	  ylab(expression(Predicted~R['0'])) +
	  THEME_LT
ggsave(gLRS, filename="Output/Figure_2.png", width=8, height=3)
