
# TODO
# Verify parameter sources
# Tidy + Analysis
# Figures
# Report
# README 
# REMOVE OLD DOCS+ final push

####################
#### Logistics #####
####################

library(Rcpp)
library(tidyverse)
library(gridExtra)
library(cowplot)

setwd("~/LHSP")

# setwd("C://Users//Liam//Documents//LHSP")

# Set C++11 for Rcpp compilation
Sys.setenv("PKG_CXXFLAGS"="-std=c++11") 

# NOTE UNCOMMENTING WILL WIPE .o FILES FROM SCRIPTS FOLDER IN WD
# BE CAREFUL
scriptFiles <- list.files("Scripts/", full.names=TRUE)
invisible(file.remove(scriptFiles[grep(".o", scriptFiles)]))

####################
####   Model   #####
####################

# Calls the model through Rcpp
# All terminal output will write through Rcout onto the R terminal
# But all objects should be cleaned from memory by the time the model ends
# The C++ program is self-sufficient and writes output to file
Rcpp::sourceCpp("Scripts/main.cpp")
main()

####################
####    DATA   #####
####################

# All data tidyed, combined, and broken up into male/female for energy values
null <- read_csv("Output/null_output.txt") %>%
			mutate(model = "null",
				   coeff = 1)

overlap_swap <- read_csv("Output/overlap_swap_output.txt") %>%
		    	mutate(model = "overlap_swap",
		    		   coeff = 1)

overlap_rand <- read_csv("Output/overlap_rand_output.txt") %>%
		    	mutate(model = "overlap_rand",
		    		   coeff = 1)

sexdiff <- read_csv("Output/sexdiff_output.txt") %>%
				mutate(model = "sexdiff") %>%
				mutate(coeff = (iteration%%5)+1)

foraging_var <- read_csv("Output/foraging_var_output.txt") %>%
						mutate(model = "foraging_var") %>%
						mutate(coeff = (iteration%%10) + 0.5)

foraging_mean <- read_csv("Output/foraging_mean_output.txt") %>%
					mutate(model = "foraging_mean") %>%
					mutate(coeff = (iteration%%10)/100 * 2 + 0.8)

ms <- all %>%
		select(model, iteration, hatchSuccess, coeff, contains("_M")) %>%
		rename_at(.vars=vars(ends_with("_M")),
				  .funs=funs(sub("_M","",.))) %>%
		mutate(sex="m")

fs <- all %>%
		select(model, iteration, hatchSuccess, coeff, contains("_F")) %>%
		rename_at(.vars=vars(ends_with("_F")),
				  .funs=funs(sub("_F","",.))) %>%
		mutate(sex="f")


# Results for all models in by-iteration rows
all <- bind_rows(null, overlap_swap, overlap_rand,
				 sexdiff, foraging_var, foraging_mean)

# Sex-specific energy results for all models 
sexes <- bind_rows(ms, fs)

# Hatching success for all models
hps <- all %>%
		group_by(model, hatchSuccess, coeff) %>%
		count() %>%
		mutate(p = n / max(null$iteration)) %>%
		ungroup()

source("Scripts/PIT_LHSP.r")

# Foraging and incubation bout info for histograms\
bouts <- read_csv("Output/bouts.txt") %>%
			bind_rows(readPITData())
####################
####  Analysis #####
####################

# (1) 
#	Chi-squared test for hatch success probabilities
# 	Need a table with columns of model, rows of 1/0, and hatch success

xsTable <- hps %>%
			select(model, hatchSuccess, coeff, n) %>%
			unite("modelSet", model, coeff, sep="_") %>%
			spread(key=modelSet, value=n) %>%
			select(-hatchSuccess)

pairwise.chisq <- function(mat) {
	combinations <- t(combn(names(mat),2))

	v1 <- c()
	v2 <- c()
	xs <- c()
	ps <- c()

	for (i in 1:nrow(combinations)) {

		xsTable <- bind_cols(mat[,combinations[i,1]],
							 mat[,combinations[i,2]])

		test <- chisq.test(xsTable)

		v1 <- c(v1, combinations[i,1])
		v2 <- c(v2, combinations[i,2])
		xs <- c(xs, test$statistic[[1]])
		ps <- c(ps, test$p.value)
	}

	fullTest <- data_frame(v1=v1, v2=v2, xs=xs, ps=ps)

	alphaCorrect <- nrow(fullTest)

	# bonferonni correction, equivalent to dividing target
	# alpha by the number of repeated tests
	fullTest <- mutate(fullTest, ps=ps*alphaCorrect)
	return(fullTest)
}

pxs <- pairwise.chisq(xsTable)

anovaTable <- sexes %>%
				unite("mc", model, coeff, sep="_")

nullSummary <- sexes %>%
				filter(model=="null") %>%
				select(hatchSuccess, endEnergy, meanEnergy, varEnergy, 
						meanIncubation, varIncubation, numIncubation,
						meanForaging, varForaging, numForaging,
						sex) %>%
				group_by(hatchSuccess, sex)

####################
## Visualization ###
####################

THEME_LT <- theme_bw() +
				theme(panel.grid.minor=element_blank(),
					  axis.title=element_text(size=10),
					  axis.text=element_text(size=8),
					  plot.title=element_text(size=12))

M_COLOR = "#ff6961"
F_COLOR = "#61a8ff"

ibp <- ggplot() +
		geom_histogram(data=subset(bouts, model=="real" & state=="incubating"),
					  aes(x=boutLength, y=..count../sum(..count..)), fill="darkgray", colour="black", binwidth=1) +
		geom_histogram(data=subset(bouts, model=="null" & state=="incubating"), 
    				  aes(x=boutLength, y=..count../sum(..count..)), colour="black", fill="blue", alpha=0.4, binwidth=1) +
		geom_histogram(data=subset(bouts, model=="overlap_swap" & state=="incubating"), 
    				  aes(x=boutLength, y=..count../sum(..count..)), colour="black", fill="green", alpha=0.4, binwidth=1) +
		scale_x_continuous(limits=c(-1, 30)) +
		scale_y_continuous(limits=c(0, 0.6)) +
		xlab("") +
		ylab("Probability") +
		THEME_LT 

fbp <- ggplot() +
		geom_histogram(data=subset(bouts, model=="real" & state=="foraging"),
					  aes(x=boutLength, y=..count../sum(..count..)), fill="darkgray", colour="black", binwidth=1) +
		geom_histogram(data=subset(bouts, model=="null" & state=="foraging"), 
    				  aes(x=boutLength, y=..count../sum(..count..)), colour="black", fill="blue", alpha=0.4, binwidth=1) +
		geom_histogram(data=subset(bouts, model=="overlap_swap" & state=="foraging"), 
    				  aes(x=boutLength, y=..count../sum(..count..)), colour="black", fill="green", alpha=0.4, binwidth=1) +
		scale_x_continuous(limits=c(-1, 30)) +
		scale_y_continuous(limits=c(0, 0.6)) +
		xlab("Bout length (days)") +
		ylab("Probability") +
		THEME_LT

fig1 <- plot_grid(ibp, fbp, labels=c("Incubating", "Foraging"), label_size=10, label_x=0.65, label_y=0.90, nrow=2, ncol=1, align="hv")
ggsave(bps, filename="Output/Figure_1.png", width=4, height=4)

ggplot(subset(energies, hatchSuccess==1)) +
	geom_boxplot(aes(x=model, y=meanForaging, fill=sex))

ggplot(subset(counts, hatchSuccess==1)) +
	geom_boxplot(aes(x=levels(model)-.25, y=endEnergy_M), fill=M_COLOR) +
	geom_boxplot(aes(x=levels(model)+.25, y=endEnergy_F), fill=F_COLOR)

fm <- hps %>%
		filter(hatchSuccess==1 &
			   (model=="foraging_mean" |
			   	model=="sexdiff" & coeff==1))

g <- ggplot(fm) +
	geom_line(aes(x=(coeff-1)*100, y=p), size=1) +
	scale_x_continuous(breaks=seq(-20, 0, by=5),
					   labels=paste(seq(-20,0,by=5),"%",sep="")) +
	xlab("Change to foraging distribution mean") +
	ylab("Hatch success probability") +
	THEME_LT

ggsave("foraging_mean_plot.png", plot=g, width=4, height=4)

fv <- hps %>%
		filter(hatchSuccess==1 &
			(model=="foraging_var" |
			 model=="sexdiff" & coeff==1))

g <- ggplot(fv) +
		geom_line(aes(x=coeff, y=p), size=1) +
		xlab("Change to foraging distribution variance") +
		THEME_LT