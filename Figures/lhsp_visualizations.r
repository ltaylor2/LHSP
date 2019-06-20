############################################################
### Logistics
############################################################
library(tidyverse)
library(extrafont)

setwd("~/Desktop/LHSP")

theme_lt <- theme_bw() +
		theme(panel.grid = element_blank(),
		      axis.text = element_text(size=14, family="Gill Sans MT"),
		      axis.title = element_text(size=19, family="Gill Sans MT"),
		      axis.title.y = element_text(angle=90, margin=margin(r=15)),
		      axis.title.x = element_text(margin=margin(t=15)))

############################################################
### Data input
############################################################
standard <- read_csv("Output/sims_standard.txt", col_names=TRUE) %>%
		mutate(model="standard",
		       modelGroup="regular")

overlapRand <- read_csv("Output/sims_overlapRand.txt", col_names=TRUE) %>%
		mutate(model="overlapRand",
		       modelGroup="regular")

noOverlap <- read_csv("Output/sims_noOverlap.txt", col_names=TRUE) %>%
		mutate(model="noOverlap",
		       modelGroup="regular")

compensation <- read_csv("Output/sims_compensate.txt", col_names=TRUE) %>%
		mutate(model="compensation",
		       modelGroup="compensation")

compensation2 <- read_csv("Output/sims_compensate2.txt", col_names=TRUE) %>%
		mutate(model="compensation2",
		       modelGroup="compensation")

retaliation <- read_csv("Output/sims_retaliate.txt", col_names=TRUE) %>%
		mutate(model="retaliation",
		       modelGroup="retaliation")

retaliation2 <- read_csv("Output/sims_retaliate2.txt", col_names=TRUE) %>%
		mutate(model="retaliation2",
		       modelGroup="retaliation")

data <- bind_rows(standard, noOverlap, overlapRand,
	          compensation, compensation2,
		  retaliation, retaliation2) %>%
		mutate(hatchRate = numSuccess/iterations,
		       gEnergy_F = meanEnergy_F - varEnergy_F / (2*meanEnergy_F),
		       gEnergy_M = meanEnergy_M - varEnergy_M / (2*meanEnergy_M),
		       strategy = paste(minEnergyThresh, maxEnergyThresh, sep="--"))

############################################################
### Overlap comparisons
############################################################
overlapComparison <- ggplot(subset(data, foragingMean==160 & modelGroup=="regular")) +
			geom_line(aes(x=model, y=hatchRate, group=strategy), colour="lightgray") +
			geom_boxplot(aes(x=model, y=hatchRate), width=0.5) +
			scale_x_discrete(labels=c("noOverlap" = "Ignore mate",
						  "standard" = "Orderly switching",
						  "overlapRand" = "Random switching")) +
			xlab("") +
			ylab("Success rate") +
			theme_lt +
			theme(axis.title.x = element_blank(),
			      axis.text.x = element_text(size=theme_lt$axis.title$size-1,
			      				 margin=margin(t=15),
			      				 color="black"))

ggsave(overlapComparison, filename="Figures/overlapComparison.png", width=9, height=8, unit="in")

############################################################
### Foraging mean comparisons
############################################################

meanRates <- data %>%
		subset(model == "standard" | 
		       modelGroup %in% c("compensation", "retaliation")) %>%
		group_by(foragingMean, model, modelGroup) %>%
		summarize(meanHR = mean(hatchRate))

standardForagingMean <- ggplot(subset(data, model=="standard")) +
				geom_line(aes(x=foragingMean, y=hatchRate, group=strategy), colour="lightgray") +
				geom_line(data=subset(meanRates, model=="standard"), 
					  aes(x=foragingMean, y=meanHR), size=1.3) +
				xlab("Mean foraging intake (kJ/day)") +
				ylab("Success rate") +
				theme_lt

ggsave(standardForagingMean, filename="Figures/standardForagingMean.png", width=8, height=8, unit="in")

############################################################
### Retaliation and Compensation
############################################################

reactionStrats <- ggplot(subset(data, (model=="standard" | modelGroup %in% c("compensation", "retaliation")) & foragingMean==160)) +
			geom_line(aes(x=model, y=hatchRate, group=strategy), colour="lightgray") +
			geom_boxplot(aes(x=model, y=hatchRate), width=0.5) +
			scale_x_discrete(limits=c("retaliation2", "retaliation", "standard", "compensation", "compensation2"),
				         labels=c("Retaliation\n(2d)", "Retaliate\n(1d)", "Normal", "Compensate\n(1d)", "Compensate\n(2d)")) +
			ylab("Success rate") +
			theme_lt +
			theme(axis.title.x = element_blank(),
			      axis.text.x = element_text(size=theme_lt$axis.title$size-1,
			      				 margin=margin(t=15),
			      				 color="black"))

ggsave(reactionStrats, filename="Figures/reactionStrats.png", width=11, height=6, unit="in")

############################################################
### Life history tradeoffs
############################################################

ggplot(subset(data, model=="standard" & foragingMean %in% c(142, 151, 160))) +
	geom_point(aes(x=gEnergy_F, y=hatchRate), colour="black") +
	geom_point(aes(x=gEnergy_M, y=hatchRate), colour="cornflowerblue") +
	geom_smooth(aes(x=gEnergy_F, y=hatchRate), colour="black", se=FALSE) +
	geom_smooth(aes(x=gEnergy_M, y=hatchRate), colour="cornflowerblue", se=FALSE) +
	ylab("Success rate") +
	xlab("Geometric mean parental energy") +
	facet_grid(facets=vars(foragingMean)) +
	coord_flip() +
	theme_lt


############################################################
### Life history buffering
############################################################

ggplot(subset(data, model=="standard")) +
	geom_line(aes(x=foragingMean, y=hatchRate/gEnergy_F, group=strategy)) +
	geom_smooth(aes(x=foragingMean, y=hatchRate/gEnergy_F))
