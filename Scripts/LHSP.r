####################
#### Logistics #####
####################

library(Rcpp)
library(tidyverse)
library(gridExtra)
library(cowplot)

# setwd("~/LHSP")

# Set C++11 for Rcpp compilation
Sys.setenv("PKG_CXXFLAGS"="-std=c++11") 

# NOTE UNCOMMENTING WILL WIPE .o FILES FROM SCRIPTS FOLDER IN WD
# 		BE CAREFUL
# scriptFiles <- list.files("Scripts/", full.names=TRUE)
# invisible(file.remove(scriptFiles[grep(".o", scriptFiles)]))

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
			spread(key=modelSet, value=n, fill=0) %>%
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

pairFilt <- function(mat, vOne, vTwo) {
	return(mat %>%
			filter((v1==vOne & v2==vTwo) | (v1==vTwo & v2==vOne)))
}
pxs <- pairwise.chisq(xsTable)

# (2)
# EXAMPLE ANOVA -- comparing mean overall energy levels between four models
# (lumping sexes)
en <- sexes %>% 
		filter(model=="null" |
			   model=="overlap_swap" |
			   model=="overlap_rand" |
			   (model=="sexdiff" & coeff==1)) %>%
		filter(hatchSuccess==1) # succesful seasons only
		select(model, sex, endEnergy, meanEnergy, varEnergy)

a <- aov(formula = endEnergy ~ model, data=en)

# Then pairwise information with Tukey's Honest Significant Difference testing
anovaResults <- TukeyHSD(a)

# (#)
# EXAMPLE PAIRED T-TEST -- comparing sex differences within null model
# (the differences which are an unfortunate result of the deterministic
# 	state assignment at the beginning of each iteration, but nontheless!)
s <- sexes %>%
		filter(model=="null") %>%
		filter(hatchSuccess == 1) %>%
		select(iteration, sex, endEnergy) %>%
		spread(key=sex, value=endEnergy)

tResults <- t.test(s$f, s$m, paired=TRUE)

####################
## Visualization ###
####################

THEME_LT <- theme_bw() +
				theme(panel.grid.minor=element_blank(),
					  axis.title=element_text(size=10),
					  axis.text=element_text(size=8),
					  plot.title=element_text(size=12))

M_COLOR = alpha("#ff6961", 0.5)
F_COLOR = alpha("#61a8ff", 0.5)

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

fig1 <- plot_grid(ibp, fbp, labels=c("Incubating", "Foraging"), 
				  label_size=10, label_x=0.65, label_y=0.90, 
				  nrow=2, ncol=1, align="hv")

ggsave(fig1, filename="Output/Figure_1.png", width=6, height=4, unit="in")


es <- sexes %>%
		filter(model=="null" |
			   model=="overlap_swap" |
			   model == "overlap_rand" |
			   (model == "sexdiff" & coeff==1)) %>%
		filter(hatchSuccess==1) %>%
		mutate(model=factor(model)) %>%
		select(model, sex, endEnergy)

fig2 <- ggplot(es) +
			geom_boxplot(aes(x=model, fill=sex, y=endEnergy)) +
			guides(fill=guide_legend(title="Sex")) +
			scale_x_discrete(limits=c("null", "overlap_swap", 
									  "overlap_rand", "sexdiff"),
							 labels=c("null"="NULL",
									  "overlap_rand"="OVERLAP_RAND",
									  "overlap_swap"="OVERLAP_SWAP",
									  "sexdiff"="SEXDIFF[1 Egg]")) +
			scale_fill_manual(labels=c("f"="Female", "m"="Male"),
								values=c("f"=F_COLOR, "m"=M_COLOR)) +
			xlab("Model") +
			ylab("Final energy at breeding season end (kJ)") +
			THEME_LT

ggsave(fig2, filename="Output/Figure_2.png", width=6, height=4, unit="in")

sds <- hps %>%
		filter(model=="sexdiff") %>%
		filter(hatchSuccess==1)

fig3 <- ggplot(sds) +
			geom_line(aes(x=coeff, y=p)) +
			scale_y_continuous(limits=c(0.98, 1)) +
			xlab("No. eggs") +
			ylab("Hatching success rate") +
			THEME_LT

ggsave(fig3, filename="Output/Figure_3.png", width=3, height=3, unit="in")

fv <- hps %>%
		filter(hatchSuccess==1 &
			(model=="foraging_var" |
			 model=="sexdiff" & coeff==1))

fig4 <- ggplot(fv) +
			geom_line(aes(x=coeff, y=p), size=1) +
			scale_x_continuous(breaks=seq(0.5, 9.5, by=2),
							   labels=c(paste(0.5*100-100,"%", sep=""),
							   			paste("+", seq(2.5, 9.5, by=2)*100-100, 
							   				  "%", sep=""))) +
			xlab("Change to foraging distribution standard deviation") +
			ylab("Hatching success rate") +
			THEME_LT

ggsave(fig4, filename="Output/Figure_4.png", width=4, height=4, unit="in")

fm <- hps %>%
		filter(hatchSuccess==1 &
			   (model=="foraging_mean" |
			   	model=="sexdiff" & coeff==1))

fig5 <- ggplot(fm) +
			geom_line(aes(x=(coeff-1)*100, y=p), size=1) +
			scale_x_continuous(breaks=seq(-20, 0, by=5),
					   		   labels=paste(seq(-20,0,by=5),"%",sep="")) +
			xlab("Change to foraging distribution mean") +
			ylab("Hatch success probability") +
			THEME_LT

ggsave(fig5, filename="Output/Figure_5.png", width=4, height=4, unit="in")

