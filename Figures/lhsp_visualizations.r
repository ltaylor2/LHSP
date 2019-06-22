############################################################
### Logistics
############################################################
library(tidyverse)
library(broom)
library(extrafont)

setwd("C://Users/Liam/Documents/LHSP")
# setwd("~/Desktop/LHSP")

theme_lt <- theme_bw() +
		theme(panel.grid = element_blank(),
		      axis.text = element_text(size=18, family="Gill Sans MT"),
		      axis.title = element_text(size=22, family="Gill Sans MT"),
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
			geom_boxplot(aes(x=model, y=hatchRate), width=0.25) +
			scale_x_discrete(labels=c("noOverlap" = "Ignoring mate",
						  "standard" = "Orderly switching",
						  "overlapRand" = "Random switching")) +
			xlab("") +
			ylab("Success rate") +
			theme_lt +
			theme(axis.title.x = element_blank(),
			      axis.text.x = element_text(size=theme_lt$axis.title$size,
			      				 margin=margin(t=15),
			      				 color="black"))

ggsave(overlapComparison, filename="Figures/overlapComparison.png", width=10, height=6, unit="in")


############################################################
### Retaliation and Compensation
############################################################

reactionStrats <- ggplot(subset(data, (model=="standard" | modelGroup %in% c("compensation", "retaliation")) & foragingMean==160)) +
			geom_line(aes(x=model, y=hatchRate, group=strategy), colour="lightgray") +
			geom_boxplot(aes(x=model, y=hatchRate), width=0.25) +
			scale_x_discrete(limits=c("retaliation2", "retaliation", "standard", "compensation", "compensation2"),
				         labels=c("Retaliate\n(2d)", "Retaliate\n(1d)", "Normal", "Compensate\n(1d)", "Compensate\n(2d)")) +
			ylab("Success rate") +
			scale_y_continuous(limits=c(0, 1)) +
			theme_lt +
			theme(axis.title.x = element_blank(),
			      axis.text.x = element_text(size=theme_lt$axis.title$size,
			      				 margin=margin(t=15),
			      				 color="black"))
ggsave(reactionStrats, filename="Figures/reactionStrats.png", width=11, height=6.3, unit="in")

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
				xlab("Environmental condition") +
				ylab("Success rate") +
				theme_lt

ggsave(standardForagingMean, filename="Figures/standardForagingMean.png", width=6, height=6, unit="in")


############################################################
### Neglect comparisons
############################################################


neglect <- ggplot(subset(data, model=="standard" & foragingMean==160)) +
			geom_point(aes(x=totNeglect, y=hatchRate)) +
			xlab("Total egg neglect (days)") +
			ylab("Success rate") +
			theme_lt

ggsave(neglect, filename="Figures/neglect.png", width=6, height=6, unit="in")


############################################################
### Life history tradeoffs
############################################################

foragingLabels <- function(fVal) {
	ret <- paste("Environment: ", fVal, sep="")
	return(ret)
}

toDF <- data %>%
			subset(model=="standard" & foragingMean %in% c(130, 145, 160)) %>%
			mutate(fLabel = map_chr(foragingMean, foragingLabels),
				   fLabel = factor(fLabel, levels=c("Environment: 160", 
				   									"Environment: 145",
				   									"Environment: 130")))


tradeoffs <- ggplot(toDF) +
				geom_point(aes(x=gEnergy_F, y=hatchRate), colour="lightgray") +
				geom_smooth(aes(x=gEnergy_F, y=hatchRate), colour="black", se=FALSE) +
				scale_x_continuous(breaks=seq(0, 1000, by=200), limits=c(-10, 1010)) +
				ylab("Success rate") +
				xlab("Parent energy") +
				facet_grid(facets=vars(fLabel)) +
				theme_lt +
				theme(strip.text = element_text(size=theme_lt$axis.text.size, family="Gill Sans MT"),
					  strip.background = element_rect(fill="white", colour="black"),
					  panel.spacing = unit(0.25, "in"))

ggsave(tradeoffs, filename="Figures/tradeoffs.png", width=6, height=6, unit="in")

############################################################
### Life history buffering
############################################################

deltaGE <- data %>%
				subset(model=="standard") %>%
				select(strategy, foragingMean, gEnergy_F) %>%
				nest(-strategy) %>%
				mutate(test = map(data, ~ lm(gEnergy_F ~ foragingMean, data=.x)),
					   lm = map(test, tidy)) %>%
				unnest(lm, .drop=TRUE) %>%
				select(strategy, term, estimate) %>%
				spread(key=term, value=estimate) %>%
				setNames(c("strategy", "iGE", "mGE"))

deltaHR <- data %>%
				subset(model=="standard") %>%
				select(strategy, foragingMean, hatchRate) %>%
				nest(-strategy) %>%
				mutate(test = map(data, ~ lm(hatchRate ~ foragingMean, data=.x)),
					   lm = map(test, tidy)) %>%
				unnest(lm, .drop=TRUE) %>%
				select(strategy, term, estimate) %>%
				spread(key=term, value=estimate) %>%
				setNames(c("strategy", "iHR", "mHR"))

srs <- data %>% 
		subset(model=="standard" & foragingMean==160) %>%
		select(strategy, hatchRate)

deltas <- full_join(deltaGE, deltaHR, by="strategy") %>%
			full_join(srs, by="strategy")

buffering <- ggplot(deltas) +
				geom_point(aes(x=mGE, y=mHR, colour=hatchRate)) +
				xlab(expression(Delta*"Parent energy (~Environment)")) +
				ylab(expression(Delta*"Success rate (~Environment)")) +
				guides(colour=FALSE) +
				theme_lt


ggsave(buffering, filename="Figures/buffering.png", width=6, height=6)

############################################################
### Life history buffering subplots
############################################################

spDF <- data %>%
			subset(model=="standard" & (strategy=="50--400"))


sub1 <- ggplot(spDF) +
			geom_point(aes(x=foragingMean, y=hatchRate), colour="lightgray") +
			geom_smooth(aes(x=foragingMean, y=hatchRate, group=strategy), colour="black", method="lm", se=FALSE) +
			geom_hline(aes(yintercept=max(hatchRate)), colour="blue", linetype="dashed") +
			xlab("Environmental condition") +
			ylab("Success rate") +
			theme_lt +
			theme(axis.text = element_blank(),
				  axis.ticks = element_blank(),
				  axis.title = element_text(size=15))

ggsave(sub1, filename="Figures/subplot1.png", width=3, height=3)

sub2 <- ggplot(spDF) +
			geom_point(aes(x=foragingMean, y=gEnergy_F), colour="lightgray") +
			geom_smooth(aes(x=foragingMean, y=gEnergy_F), colour="black", method="lm", se=FALSE) +
			xlab("Environmental condition") +
			ylab("Parent energy") +
			theme_lt +
			theme(axis.text = element_blank(),
				  axis.ticks = element_blank(),
				  axis.title = element_text(size=15))

ggsave(sub2, filename="Figures/subplot2.png", width=3, height=3)