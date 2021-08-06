############################################################
### Logistics
############################################################
library(tidyverse)
library(scales)
library(broom)
library(cowplot)
library(ggthemes)

setwd("~/Documents/LHSP/")

theme_lt <- theme_bw() +
		theme(panel.grid = element_blank(),
		      axis.text = element_text(size=10),
		      axis.title = element_text(size=12),
		      axis.title.y = element_text(angle=90, margin=margin(r=15)),
		      axis.title.x = element_text(margin=margin(t=15)))

############################################################
### Data input
############################################################
resultsUni <- read_csv("Output/sims_uni.txt", col_names=TRUE) %>%
		       mutate(model="uni")

resultsSemi  <- read_csv("Output/sims_semi.txt", col_names=TRUE) %>%
		         mutate(model="semi")

resultsBi <- read_csv("Output/sims_bi.txt", col_names=TRUE) %>%
		      mutate(model="bi")

resultsAll <- bind_rows(resultsUni, resultsSemi, resultsBi) %>%
	         mutate(hatchRate = numSuccess/iterations,
                  deathRate = numParentFail/iterations,
                  failRate = (numAllFail+numEggTimeFail+numEggColdFail)/iterations,
                  gEnergy_F = meanEnergy_F - varEnergy_F / (2*meanEnergy_F),
                  gEnergy_M = meanEnergy_M - varEnergy_M / (2*meanEnergy_M),
                  gEnergy_OVERALL = gEnergy_F + gEnergy_M / 2,
                  strategy_F = paste(minEnergyThresh_F, maxEnergyThresh_F, sep="-"),
                  strategy_M = paste(minEnergyThresh_M, maxEnergyThresh_M, sep="-"),
                  strat_diff_F = maxEnergyThresh_F - minEnergyThresh_F,
                  strat_diff_M = maxEnergyThresh_M - minEnergyThresh_M,
                  strategy_OVERALL = paste(strategy_F, strategy_M, sep="--"),
                  ID = paste(strategy_OVERALL, model, sep="---"))

resultsMeans <- resultsAll %>%
             select(model, foragingMean, meanEnergy_F, varEnergy_F, failRate, deathRate, totNeglect, maxNeglect, hatchRate) %>%
             filter(foragingMean < 300) %>%
             group_by(model, foragingMean) %>%
             summarize_all(mean, na.rm=TRUE)

plot_totNeglect <- ggplot(resultsMeans) +
                geom_point(aes(x=foragingMean, y=totNeglect, color=model), alpha=0.5) +
                geom_line(aes(x=foragingMean, y=totNeglect, color=model), alpha=0.8) +
                geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
                scale_color_colorblind() +
                ggtitle("Total egg neglect") +
                guides(color=FALSE) +
                theme_lt +
                theme(axis.title.y=element_blank(),
                      axis.text.y=element_blank(),
                      axis.ticks.y=element_blank(),
                      axis.ticks.x=element_blank(),
                      axis.text.x=element_blank(),
                      axis.title.x=element_blank())

plot_meanF <- ggplot(resultsMeans) +
             geom_point(aes(x=foragingMean, y=meanEnergy_F, color=model), alpha=0.5) +
             geom_line(aes(x=foragingMean, y=meanEnergy_F, color=model), alpha=0.8) +
             geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
             scale_color_colorblind() +
             ggtitle("Mean female energy") +
             guides(color=FALSE) +
             theme_lt +
             theme(axis.title.y=element_blank(),
                   axis.text.y=element_blank(),
                   axis.ticks.y=element_blank(),
                   axis.ticks.x=element_blank(),
                   axis.text.x=element_blank(),
                   axis.title.x=element_blank())

plot_varF <- ggplot(resultsMeans) +
             geom_point(aes(x=foragingMean, y=varEnergy_F, color=model), alpha=0.5) +
             geom_line(aes(x=foragingMean, y=varEnergy_F, color=model), alpha=0.8) +
             geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
             scale_color_colorblind(breaks=c("uni", "semi", "bi"),
                                    labels=c("uni"="Female only", "semi"="Female + Male provisioning", "bi"="Biparental")) +
             ggtitle("Variance female energy") +
             guides(color=guide_legend(fill=NA)) +
             theme_lt +
             theme(axis.title.y=element_blank(),
                   axis.text.y=element_blank(),
                   axis.ticks.y=element_blank(),
                   axis.ticks.x=element_blank(),
                   axis.text.x=element_blank(),
                   axis.title.x=element_blank(),
                   legend.title=element_blank(),
                   legend.position=c(0.2, 0.6),
                   legend.margin=margin(0))

plot_fail <- ggplot(resultsMeans) +
          geom_point(aes(x=foragingMean, y=failRate, color=model), alpha=0.5) +
          geom_line(aes(x=foragingMean, y=failRate, color=model), alpha=0.8) +
          geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
          scale_y_continuous(limits=c(0, 1)) +
          scale_color_colorblind() +
          ggtitle("Egg failure rate") +
          guides(color=FALSE) +
          theme_lt +
          theme(axis.title.y=element_blank(),
                axis.text.y=element_blank(),
                axis.ticks.y=element_blank(),
                axis.ticks.x=element_blank(),
                axis.text.x=element_blank(),
                axis.title.x=element_blank())

plot_death <- ggplot(resultsMeans) +
             geom_point(aes(x=foragingMean, y=deathRate, color=model), alpha=0.5) +
             geom_line(aes(x=foragingMean, y=deathRate, color=model), alpha=0.8) +
             geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
             scale_y_continuous(limits=c(0, 1)) +
             scale_color_colorblind() +
             ggtitle("Parent death rate") +
             guides(color=FALSE) +
             theme_lt +
             theme(axis.title.y=element_blank(),
                   axis.text.y=element_blank(),
                   axis.ticks.y=element_blank(),
                   axis.ticks.x=element_blank(),
                   axis.text.x=element_blank(),
                   axis.title.x=element_blank())

plot_hatchRate <- ggplot(resultsMeans) +
               geom_point(aes(x=foragingMean, y=hatchRate, color=model), alpha=0.5) +
               geom_line(aes(x=foragingMean, y=hatchRate, color=model), alpha=0.8) +
               geom_vline(aes(xintercept=163), linetype="dashed", colour="lightgray") +
               scale_y_continuous(limits=c(0, 1)) +
               scale_color_colorblind() +
               ggtitle("Hatch rate") +
               guides(color=FALSE) +
               xlab("Mean foraging calories per day (\"Environmental Condition\")") +
               theme_lt +
               theme(axis.title.y=element_blank(),
                     axis.text.y=element_blank(),
                     axis.ticks.y=element_blank())


plots <- plot_grid(plot_totNeglect, plot_meanF, plot_varF, plot_fail, plot_death, plot_hatchRate, nrow=6)

ggsave(plots, file="Figures/lhsp_preview.png", width=6, height=10, unit="in")










# # First, looking at strategies in empirical foraging environment: foragingMean = 163
#
# empEnvironment <- data %>%
# 			   filter(model=="default" & foragingMean==163)
#
# plot_strat_success <- ggplot(empEnvironment) +
# 			 	   geom_histogram(aes(x=hatchRate), fill="lightgray", colour="black", binwidth=0.05) +
# 			 	   scale_x_continuous(limits=c(-0.1, 1.1),
# 			 	   					  breaks=seq(0, 1, by=0.20)) +
# 			 	   xlab("Hatch rate") +
# 			 	   ylab("No. strategy combinations") +
# 			 	   theme_lt
#
# ggsave(plot_strat_success, filename="Figures/strat_success.png", width=3, height=3, unit="in")
#
# stratOrdersMin <- seq(0, 950, by=50) %>%
# 			   map(function(s) { return(paste(s, seq((s+50), 1000, by=50), sep="-")) }) %>%
# 			   unlist()
#
# stratOrdersMax <- seq(50, 1000, by=50) %>%
# 			   map(function(s) { return(paste(seq(0, s-50, by=50), s, sep="-")) }) %>%
# 			   unlist()
#
# plot_hatchRate_by_Strategy_163 <- ggplot(empEnvironment) +
# 					           geom_raster(aes(x=strategy_F, y=strategy_M, fill=hatchRate)) +
# 		   				       scale_fill_gradient(low="white", high="black") +
# 		   				       scale_x_discrete(limits=stratOrdersMin) +
# 		   				       scale_y_discrete(limits=stratOrdersMin) +
# 		   				       guides(fill=FALSE) +
# 		   				       xlab("Female strategy") +
# 		   				       ylab("Male strategy") +
# 		   				       theme_lt +
#   		   				       theme(axis.text=element_text(size=4),
#    				  		     		 axis.text.x=element_text(angle=90, hjust=0.5),
#    				  		     		 plot.margin=margin(0, 0, 0, 0, "in"),
#    				  		     		 panel.spacing = unit(0, "lines"))
# ggsave(plot_hatchRate_by_Strategy_163, filename="Figures/hatchRate_by_Strategy_163.png", width=8, height=8, unit="in")
#
# stratHighRate_hunger_F <- empEnvironment %>%
# 				       mutate(isHighRate=hatchRate>=0.95) %>%
# 				       group_by(minEnergyThresh_F, isHighRate) %>%
# 				       count() %>%
# 				       group_by(minEnergyThresh_F) %>%
# 				       mutate(rate=n/sum(n)) %>%
# 				       filter(isHighRate) %>%
# 				       select(thresh=minEnergyThresh_F, rate) %>%
# 				       mutate(threshType="min", sex="F")
#
# stratHighRate_satiation_F <- empEnvironment %>%
# 				          mutate(isHighRate=hatchRate>=0.95) %>%
# 				          group_by(maxEnergyThresh_F, isHighRate) %>%
# 				          count() %>%
# 				          group_by(maxEnergyThresh_F) %>%
# 				          mutate(rate=n/sum(n)) %>%
# 				          filter(isHighRate) %>%
# 				          select(thresh=maxEnergyThresh_F, rate) %>%
# 				          mutate(threshType="max", sex="F")
#
# stratHighRate_hunger_M <- empEnvironment %>%
# 				       mutate(isHighRate=hatchRate>=0.95) %>%
# 				       group_by(minEnergyThresh_M, isHighRate) %>%
# 				       count() %>%
# 				       group_by(minEnergyThresh_M) %>%
# 				       mutate(rate=n/sum(n)) %>%
# 				       filter(isHighRate) %>%
# 				       select(thresh=minEnergyThresh_M, rate) %>%
# 				       mutate(threshType="min", sex="M")
#
# stratHighRate_satiation_M <- empEnvironment %>%
# 				          mutate(isHighRate=hatchRate>=0.95) %>%
# 				          group_by(maxEnergyThresh_M, isHighRate) %>%
# 				          count() %>%
# 				          group_by(maxEnergyThresh_M) %>%
# 				          mutate(rate=n/sum(n)) %>%
# 				          filter(isHighRate) %>%
# 				          select(thresh=maxEnergyThresh_M, rate) %>%
# 				          mutate(threshType="max", sex="M")
#
# stratHighRates <- bind_rows(stratHighRate_hunger_F, stratHighRate_satiation_F,
# 							stratHighRate_hunger_M, stratHighRate_satiation_M)
#
# plot_stratHighRates_hunger <- ggplot(filter(stratHighRates, threshType=="min")) +
# 						   geom_point(aes(x=thresh, y=rate, colour=sex), alpha=0.3, size=0.5) +
# 						   geom_line(aes(x=thresh, y=rate, colour=sex), alpha=0.5) +
# 						   scale_colour_manual(values=c("F"="red",
# 						   								"M"="blue")) +
# 						   scale_x_continuous(limits=c(0, 1000),
# 						   					  breaks=seq(0, 1000, by=200)) +
# 					       scale_y_continuous(limits=c(0, 1),
# 					      					  breaks=seq(0, 1, by=0.25)) +
# 						   xlab("Hunger threshold") +
# 						   ylab("Prop. high success\ncombinations") +
# 						   guides(colour=FALSE) +
# 						   theme_lt
#
# plot_stratHighRates_satiation <- ggplot(filter(stratHighRates, threshType=="max")) +
# 						      geom_point(aes(x=thresh, y=rate, colour=sex), alpha=0.3, size=0.5) +
#   						      geom_line(aes(x=thresh, y=rate, colour=sex), alpha=0.5) +
# 						      scale_colour_manual(values=c("F"="red",
# 						      							   "M"="blue")) +
# 						      scale_x_continuous(limits=c(0, 1000),
# 						   					  	 breaks=seq(0, 1000, by=200)) +
# 						      scale_y_continuous(limits=c(0, 1),
# 						      					 breaks=seq(0, 1, by=0.25)) +
# 						      xlab("Satiation threshold") +
# 						      ylab("") +
# 						      guides(colour=FALSE) +
# 						      theme_lt
#
# plots_stratHighRates <- plot_grid(plot_stratHighRates_hunger, plot_stratHighRates_satiation, nrow=1)
# ggsave(plots_stratHighRates, filename="Figures/stratHighRates.png", width=6, height=3)
#
# plot_highStrat_totNeglect <- ggplot(filter(empEnvironment, hatchRate>=0.95)) +
# 			 	      geom_histogram(aes(x=totNeglect), binwidth=1,
# 			 	      				 fill="lightgray", colour="black") +
# 			 	      scale_x_continuous(limits=c(-1, 10),
# 			 	      					 breaks=seq(0, 8, by=2)) +
# 			 	      xlab("Total neglect") +
# 			 	      ylab("No. high success\ncombinations") +
# 			 	      theme_lt
#
# ggsave(plot_highStrat_totNeglect, filename="Figures/highStrat_totNeglect.png", width=3, height=3, unit="in")
#
# plot_highStrat_maxNeglect <- ggplot(filter(empEnvironment, hatchRate>=0.95)) +
# 			 	      geom_histogram(aes(x=maxNeglect), binwidth=1,
# 			 	      				 fill="lightgray", colour="black") +
# 			 	      scale_x_continuous(limits=c(-1, 5),
# 			 	      					 breaks=seq(0, 4, by=1)) +
# 			 	      xlab("Maximum neglect") +
#   			 	      ylab("No. high success\ncombinations") +
# 			 	      theme_lt
#
# ggsave(plot_highStrat_maxNeglect, filename="Figures/highStrat_maxNeglect.png", width=3, height=3, unit="in")
#
# plot_highStrat_parentEnergy <- ggplot(filter(empEnvironment, hatchRate>=0.95)) +
# 			 	        geom_histogram(aes(x=gEnergy_OVERALL), binwidth=25,
# 			 	        	           fill="lightgray", colour="black") +
# 			 	        scale_x_continuous(limits=c(700, 1350),
# 			 	        				   breaks=seq(700, 1350, by=250)) +
# 			 	        xlab("Parent energy") +
# 			 	        ylab("No. high success\ncombinations") +
# 			 	        theme_lt
#
# ggsave(plot_highStrat_parentEnergy, filename="Figures/highStrat_parentEnergy.png", width=3, height=3, unit="in")
#
# plot_totNeglect_energy <- ggplot(empEnvironment) +
# 					   geom_point(aes(x=totNeglect, y=gEnergy_OVERALL),
# 						  		   colour="gray", alpha=0.4) +
# 					   geom_smooth(aes(x=totNeglect, y=gEnergy_OVERALL),
# 					   			       method="lm", se=FALSE,
# 					   			       colour="black") +
# 					   scale_x_continuous(limits=c(0, 15),
# 					   				      breaks=seq(0, 15, by=5)) +
# 					   scale_y_continuous(limits=c(700, 1500),
# 					   				      breaks=seq(700, 1500, by=250)) +
# 					   xlab("Total neglect") +
# 					   ylab("Parent energy") +
# 					   theme_lt
#
# plot_maxNeglect_energy <- ggplot(empEnvironment) +
# 					   geom_point(aes(x=maxNeglect, y=gEnergy_OVERALL),
# 						  		   colour="gray", alpha=0.4) +
# 					   geom_smooth(aes(x=maxNeglect, y=gEnergy_OVERALL),
# 					   				   method="lm", se=FALSE,
# 					   			       colour="black") +
# 					   scale_x_continuous(limits=c(0, 10),
# 					   				      breaks=seq(0, 10, by=5)) +
# 					   scale_y_continuous(limits=c(700, 1500),
# 					   				      breaks=seq(700, 1500, by=250)) +
# 					   xlab("Maximum neglect") +
# 					   ylab("") +
# 					   theme_lt
#
# plots_neglect_energy <- plot_grid(plot_totNeglect_energy, plot_maxNeglect_energy, nrow=1)
# ggsave(plots_neglect_energy, filename="Figures/neglect_energy.png", width=6, height=3, unit="in")
#
# plot_hatch_energy_byMin <- ggplot(empEnvironment) +
# 						geom_point(aes(x=hatchRate, y=gEnergy_OVERALL),
# 						  		   colour="gray", alpha=0.4) +
# 						geom_smooth(aes(x=hatchRate, y=gEnergy_OVERALL,
# 									group=minEnergyThresh_F, colour=minEnergyThresh_F),
# 									method="lm", se=FALSE) +
# 						scale_y_continuous(limits=c(700, 1500)) +
# 						guides(colour=FALSE) +
# 						xlab("Hatch rate") +
# 				        ylab("Parent energy") +
# 						ggtitle("Hunger threshold") +
# 						theme_lt
#
# plot_hatch_energy_byMax <- ggplot(empEnvironment) +
# 						geom_point(aes(x=hatchRate, y=gEnergy_OVERALL),
# 						  		   colour="gray", alpha=0.4) +
# 						geom_smooth(aes(x=hatchRate, y=gEnergy_OVERALL,
# 									group=maxEnergyThresh_F, colour=maxEnergyThresh_F),
# 									method="lm", se=FALSE) +
# 						scale_y_continuous(limits=c(700, 1500)) +
# 						guides(colour=FALSE) +
# 						xlab("Hatch rate") +
# 						ylab("") +
# 						ggtitle("Satiation threshold") +
# 						theme_lt
#
# plots_hatch_energy <- plot_grid(plot_hatch_energy_byMin, plot_hatch_energy_byMax, nrow=1)
# ggsave(plots_hatch_energy, filename="Figures/hatch_energy.png", width=6, height=3, unit="in")
#
# envChange <- data %>%
# 		  filter(model=="default")
#
# envMeans <- envChange %>%
# 		 group_by(foragingMean) %>%
# 		 summarize(meanHatch = mean(hatchRate),
# 		 		   varHatch = var(hatchRate),
# 		 		   meanNeglect = mean(totNeglect),
# 		 		   meanEnergy = mean(gEnergy_OVERALL))
#
# plot_env_hatch <- ggplot(envChange) +
# 			   geom_line(aes(x=foragingMean, y=hatchRate, group=strategy_OVERALL),
# 			   		     colour="gray", alpha=0.5) +
# 			   geom_line(data=envMeans,
# 			   			 aes(x=foragingMean, y=meanHatch),
# 			   			 colour="black") +
# 			   geom_point(data=envMeans,
# 			   			  aes(x=foragingMean, y=meanHatch)) +
# 			   scale_x_continuous(breaks=seq(130, 166, by=3),
# 			   					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			   xlab("Environmental condition") +
# 			   ylab("Hatch rate") +
# 			   theme_lt
#
# ggsave(plot_env_hatch, filename="Figures/env_hatch.png", width=3, height=3, unit="in")
#
# plot_env_hatch_var <- ggplot(envMeans) +
# 				   geom_line(aes(x=foragingMean, y=varHatch)) +
# 				   geom_point(aes(x=foragingMean, y=varHatch)) +
# 				   scale_x_continuous(breaks=seq(130, 166, by=3),
# 				   					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 				   xlab("Environmental condition") +
# 				   ylab("Variance in hatch rate") +
# 				   theme_lt
#
# ggsave(plot_env_hatch_var, filename="Figures/env_variance.png", width=3, height=3, unit="in")
#
#
# plot_env_neglect <- ggplot(envChange) +
# 			     geom_line(aes(x=foragingMean, y=totNeglect, group=strategy_OVERALL),
# 			     		       colour="gray", alpha=0.5) +
# 			     geom_line(data=envMeans,
# 			     		   aes(x=foragingMean, y=meanNeglect),
# 			     		   colour="black") +
# 			     geom_point(data=envMeans,
# 			     			  aes(x=foragingMean, y=meanNeglect)) +
# 			     scale_x_continuous(breaks=seq(130, 166, by=3),
# 			     					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			     xlab("Environmental condition") +
# 			     ylab("Total neglect") +
# 			     theme_lt
#
#
# ggsave(plot_env_neglect, filename="Figures/env_neglect.png", width=3, height=3, unit="in")
#
#
# plot_env_energy <- ggplot(envChange) +
# 			    geom_line(aes(x=foragingMean, y=gEnergy_OVERALL, group=strategy_OVERALL),
# 			    		      colour="gray", alpha=0.5) +
# 			    geom_line(data=envMeans,
# 			    		  aes(x=foragingMean, y=meanEnergy),
# 			    		  colour="black") +
# 			    geom_point(data=envMeans,
# 			    		   aes(x=foragingMean, y=meanEnergy)) +
# 			    scale_x_continuous(breaks=seq(130, 166, by=3),
# 			    					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			    xlab("Environmental condition") +
# 			    ylab("Parent energy") +
# 			    theme_lt
# ggsave(plot_env_energy, filename="Figures/env_energy.png", width=3, height=3, unit="in")
#
#
# getSwitch <- function(d) {
# 	switch <-  d %>%
# 		   filter(hatchRate < 0.5) %>%
# 		   arrange(-foragingMean) %>%
# 		   pull(foragingMean) %>%
# 		   .[1]
# 	return(switch)
# }
# resilience <- data %>%
# 	 	   filter(model=="default") %>%
# 	 	   select(foragingMean, hatchRate, strategy_OVERALL) %>%
# 	 	   nest(-strategy_OVERALL) %>%
# 	 	   mutate(switchEnv = map_dbl(data, getSwitch)) %>%
# 	 	   mutate(res = map_dbl(switchEnv, ~ 1/.)) %>%
# 	 	   select(strategy_OVERALL, switchEnv, res) %>%
# 	 	   right_join(filter(data, model=="default"), by="strategy_OVERALL") %>%
# 	 	   filter(foragingMean==163)
#
# plot_resilience <- ggplot(resilience) +
# 				geom_point(aes(x=res, y=hatchRate),
# 						   colour="gray", alpha=1, size=0.5, shape=1) +
# 				xlab("Resilience") +
# 				ylab("Hatch rate (emp. condition)") +
# 				scale_x_continuous(limits=c(0.006, 0.0074),
# 								   breaks=c(0.006, 0.007)) +
# 				theme_lt
#
#
# ggsave(plot_resilience, filename="Figures/env_resilience.png", width=3, height=3, unit="in")
#
#
# labelFunction <- function(s) {
# 	ret <- paste("Environment: ", s, sep="")
# 	return(ret)
# }
#
# plot_mediated_tradeoff <- ggplot(filter(envChange, foragingMean %in% c(130, 148, 166))) +
# 					   geom_point(aes(x=hatchRate, y=gEnergy_OVERALL),
# 					   		          colour="gray", alpha=0.2, shape=1) +
# 					   geom_smooth(aes(x=hatchRate, y=gEnergy_OVERALL),
# 					   				   method="loess", se=FALSE,
# 					   				   colour="black") +
# 					   facet_grid(rows=vars(foragingMean),
# 					   			  labeller=labeller(foragingMean = labelFunction)) +
# 					   scale_y_continuous(limits=c(0, 1500)) +
# 					   xlab("Hatch rate") +
# 					   ylab("Parent energy") +
# 					   theme_lt +
# 					   theme(strip.text = element_text(size=theme_lt$axis.text.size, family="Gill Sans MT"),
# 					   	     strip.background = element_rect(fill="white", colour="black"))
#
# ggsave(plot_mediated_tradeoff, filename="Figures/mediated_tradeoff.png", width=6, height=6, unit="in")
#
# overlapMeans <- data %>%
# 			 filter(modelGroup=="regular") %>%
# 			 select(model, foragingMean, hatchRate, gEnergy_OVERALL) %>%
# 			 nest(data=c(hatchRate, gEnergy_OVERALL)) %>%
# 			 mutate(meanHatch = map_dbl(data, ~ mean(unlist(.$hatchRate))),
# 			 	    lowerHatch = map_dbl(data, ~quantile(unlist(.$hatchRate), 0.25)),
# 			 	    upperHatch = map_dbl(data, ~quantile(unlist(.$hatchRate), 0.75)),
# 			 	    meanEnergy= map_dbl(data, ~ mean(unlist(.$gEnergy_OVERALL))),
# 			 	    lowerEnergy = map_dbl(data, ~quantile(unlist(.$gEnergy_OVERALL), 0.25)),
# 			 	    upperEnergy = map_dbl(data, ~quantile(unlist(.$gEnergy_OVERALL), 0.75))) %>%
# 			 select(-data)
#
# plot_overlap <- ggplot(filter(data, modelGroup=="regular")) +
# 			 geom_line(aes(x=foragingMean, y=hatchRate, group=ID),
# 			    	   colour="lightgray", alpha=1) +
# 			 geom_line(data=overlapMeans,
# 			 		   aes(x=foragingMean, y=meanHatch, colour=model),
# 			 		   alpha=0.8) +
#  			 geom_point(data=overlapMeans,
# 			 		    aes(x=foragingMean, y=meanHatch, colour=model),
# 			 		    position=position_dodge(width=1), alpha=1) +
# 			 geom_errorbar(data=overlapMeans,
# 			 			   aes(x=foragingMean, ymin=lowerHatch, ymax=upperHatch,
# 			 				   colour=model),
# 			 			   width=0, position=position_dodge(width=1), alpha=0.8) +
# 			 xlab("Environmental condition") +
# 			 ylab("Hatch rate") +
# 			 scale_colour_brewer(limits=c("default", "overlapRand", "noOverlap"),
# 			 				     labels=c("default"="DEFAULT",
# 			 				  	   	      "noOverlap"="OVERLAP",
# 			 				  			  "overlapRand"="RAND-SWITCH"),
# 			 				     palette = "Set2") +
# 			 scale_y_continuous(limits=c(0, 1)) +
# 			 scale_x_continuous(breaks=seq(130, 166, by=3),
# 			 					labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			 guides(colour=guide_legend(title="Model")) +
# 			 theme_lt +
# 		     theme(legend.position=c(0.2, 0.84))
#
# ggsave(plot_overlap, filename="Figures/overlap.png", width=6, height=6, unit="in")
#
# plot_overlap_energy <- ggplot(filter(data, modelGroup=="regular")) +
# 			        geom_line(aes(x=foragingMean, y=gEnergy_OVERALL, group=ID),
# 			           	      colour="lightgray", alpha=1) +
# 			        geom_line(data=overlapMeans,
# 			        		  aes(x=foragingMean, y=meanEnergy, colour=model),
# 			        		  alpha=0.8) +
#  			        geom_point(data=overlapMeans,
# 			        		   aes(x=foragingMean, y=meanEnergy, colour=model),
# 			        		   position=position_dodge(width=1), alpha=1) +
# 			        geom_errorbar(data=overlapMeans,
# 			        		      aes(x=foragingMean, ymin=lowerEnergy, ymax=upperEnergy,
# 			        			      colour=model),
# 			        			  width=0, position=position_dodge(width=1), alpha=0.8) +
# 			        xlab("Environmental condition") +
# 			        ylab("Parent energy") +
# 			        scale_colour_brewer(limits=c("default", "overlapRand", "noOverlap"),
# 			        			        labels=c("default"="DEFAULT",
# 			        				  	  	     "noOverlap"="OVERLAP",
# 			        				  			 "overlapRand"="RAND-SWITCH"),
# 			        				    palette = "Set2") +
# 			        scale_x_continuous(breaks=seq(130, 166, by=3),
# 			        				   labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			        guides(colour=guide_legend(title="Model")) +
# 			        theme_lt +
# 		            theme(legend.position=c(0.2, 0.84))
#
# ggsave(plot_overlap_energy, filename="Figures/overlap_energy.png", width=6, height=6, unit="in")
#
# resCompMeans <- data %>%
# 			 filter(modelGroup %in% c("retaliation", "compensation") | model == "default") %>%
# 			 select(model, foragingMean, hatchRate, gEnergy_OVERALL) %>%
# 			 nest(data=c(hatchRate, gEnergy_OVERALL)) %>%
# 			 mutate(meanHatch = map_dbl(data, ~ mean(unlist(.$hatchRate))),
# 			 	    lowerHatch = map_dbl(data, ~quantile(unlist(.$hatchRate), 0.25)),
# 			 	    upperHatch = map_dbl(data, ~quantile(unlist(.$hatchRate), 0.75)),
# 			 	    meanEnergy= map_dbl(data, ~ mean(unlist(.$gEnergy_OVERALL))),
# 			 	    lowerEnergy = map_dbl(data, ~quantile(unlist(.$gEnergy_OVERALL), 0.25)),
# 			 	    upperEnergy = map_dbl(data, ~quantile(unlist(.$gEnergy_OVERALL), 0.75))) %>%
# 			 select(-data)
#
# plot_ret_comp <- ggplot(filter(data, modelGroup %in% c("retaliation", "compensation") | model == "default")) +
# 			  geom_line(aes(x=foragingMean, y=hatchRate, group=ID),
# 			       	    colour="lightgray", alpha=0.5) +
# 			  geom_line(data=resCompMeans,
# 			  		    aes(x=foragingMean, y=meanHatch, colour=model),
# 			  		    alpha=0.8) +
#  			  geom_point(data=resCompMeans,
# 			  		     aes(x=foragingMean, y=meanHatch, colour=model),
# 			  		     position=position_dodge(width=3), alpha=1) +
# 			  geom_errorbar(data=resCompMeans,
# 			  			    aes(x=foragingMean, ymin=lowerHatch, ymax=upperHatch,
# 			  				    colour=model),
# 			  			    width=0, position=position_dodge(width=3), alpha=1) +
# 			  xlab("Environmental condition") +
# 			  ylab("Hatch rate") +
# 			  scale_colour_brewer(limits=c("compensation2",
# 			  					 	       "compensation1",
# 			  							   "default",
# 			  							   "retaliation1",
# 			  							   "retaliation2"),
# 			  		     		  labels=c("retaliation2"="RETALIATION-2",
# 			  				   	           "retaliation1"="RETALIATION-1",
# 			  						       "default"="DEFAULT",
# 			  						       "compensation1"="COMPENSATION-1",
# 			  						       "compensation2"="COMPENSATION-2"),
# 			  					  palette = "RdYlBu",
# 			  					  direction = -1) +
# 			  scale_y_continuous(limits=c(0, 1)) +
# 			  scale_x_continuous(breaks=seq(130, 166, by=3),
# 			  				 	 labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			  guides(colour=guide_legend(title="Model")) +
# 			  theme_lt +
# 			  theme(legend.position=c(0.2, 0.84))
#
# ggsave(plot_ret_comp, filename="Figures/ret_comp.png", width=6, height=6, unit="in")
#
#
# plot_ret_energy <- ggplot(filter(data, modelGroup %in% c("retaliation", "compensation") | model == "default")) +
# 			  # geom_line(aes(x=foragingMean, y=hatchRate, group=ID),
# 			  #      	    colour="lightgray", alpha=0.5) +
# 			  geom_line(data=resCompMeans,
# 			  		    aes(x=foragingMean, y=meanEnergy, colour=model),
# 			  		    alpha=0.8) +
#  			  geom_point(data=resCompMeans,
# 			  		     aes(x=foragingMean, y=meanEnergy, colour=model),
# 			  		     position=position_dodge(width=3), alpha=1) +
# 			  geom_errorbar(data=resCompMeans,
# 			  			    aes(x=foragingMean, ymin=lowerEnergy, ymax=upperEnergy,
# 			  				    colour=model),
# 			  			    width=0, position=position_dodge(width=3), alpha=1) +
# 			  xlab("Environmental condition") +
# 			  ylab("Parent energy") +
# 			  scale_colour_brewer(limits=c("compensation2",
# 			  					 	       "compensation1",
# 			  							   "default",
# 			  							   "retaliation1",
# 			  							   "retaliation2"),
# 			  		     		  labels=c("retaliation2"="RETALIATION-2",
# 			  				   	           "retaliation1"="RETALIATION-1",
# 			  						       "default"="DEFAULT",
# 			  						       "compensation1"="COMPENSATION-1",
# 			  						       "compensation2"="COMPENSATION-2"),
# 			  					  palette = "RdYlBu",
# 			  					  direction = -1) +
# 			  scale_x_continuous(breaks=seq(130, 166, by=3),
# 			  				 	 labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			  guides(colour=guide_legend(title="Model")) +
# 			  theme_lt +
# 			  theme(legend.position=c(0.2, 0.84))
#
# ggsave(plot_ret_energy, filename="Figures/ret_comp_energy.png", width=6, height=6, unit="in")
#
# getSwitch <- function(d) {
# 	switch <-  d %>%
# 		   filter(hatchRate < 0.5) %>%
# 		   arrange(-foragingMean) %>%
# 		   pull(foragingMean) %>%
# 		   .[1]
# 	return(switch)
# }
# socResilience <- data %>%
# 			  filter(modelGroup %in% c("retaliation", "compensation") | model == "default") %>%
# 	 	      select(model, foragingMean, hatchRate, strategy_OVERALL) %>%
# 	 	      nest(data=c(foragingMean, hatchRate)) %>%
# 	 	      mutate(switchEnv = map_dbl(data, getSwitch)) %>%
# 	 	      mutate(res = map_dbl(switchEnv, ~ 1/.)) %>%
# 	 	      select(model, strategy_OVERALL, switchEnv, res)
#
# socResilienceMeans <- socResilience %>%
# 				   nest(data=c(switchEnv, strategy_OVERALL, res)) %>%
# 				   mutate(meanRes = map_dbl(data, ~ mean(unlist(.$res))),
# 				   	      lowRes = map_dbl(data, ~ quantile(unlist(.$res), 0.25)),
# 				   	      highRes = map_dbl(data, ~ quantile(unlist(.$res), 0.75))) %>%
# 				   select(-data)
#
# plot_social_resilience <- ggplot(socResilience) +
# 					   geom_violin(aes(x=model, y=res)) +
# 					   scale_x_discrete(limits=c("retaliation2",
# 			  					 	             "retaliation1",
# 			  							         "default",
# 			  							         "compensation1",
# 			  							         "compensation2"),
# 					        		    labels=c("retaliation2"="RET-2",
# 					   		   	                 "retaliation1"="RET-1",
# 					   				             "default"="DEFAULT",
# 					   				             "compensation1"="COMP-1",
# 					   				             "compensation2"="COMP-2")) +
# 					   xlab("Model") +
# 					   ylab("Resilience") +
# 					   theme_lt
#
# ggsave(plot_social_resilience, filename="Figures/soc_res.png", width=6, height=6, unit="in")
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
# plot_overlap <- ggplot(filter(data, modelGroup=="regular")) +
# 			 geom_line(aes(x=foragingMean, y=hatchRate, group=ID), colour="lightgray") +
# 			 geom_boxplot(aes(x=foragingMean, y=hatchRate,
# 			 				  group=interaction(model, foragingMean), fill=model), outlier.shape=NA) +
# 			 xlab("Environmental condition") +
# 			 ylab("Hatch rate") +
# 			 scale_fill_brewer(limits=c("overlapRand", "default", "noOverlap"),
# 			 				   labels=c("default"="DEFAULT",
# 			 					   	    "noOverlap"="OVERLAP",
# 			 							"overlapRand"="RAND-SWITCH"),
# 			 				   palette = "Pastel1") +
# 			 scale_y_continuous(limits=c(0, 1)) +
# 			 scale_x_continuous(breaks=seq(130, 166, by=3),
# 			 					labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 			 guides(fill=guide_legend(title="Model Type")) +
# 			 theme_lt
#
# retaliationCompensation <- ggplot(filter(data, !(model %in% c("noOverlap", "overlapRand")))) +
# 					   geom_line(aes(x=foragingMean, y=hatchRate, group=ID), colour="lightgray") +
# 					   geom_boxplot(aes(x=foragingMean, y=hatchRate, group=interaction(model, foragingMean), fill=model), outlier.shape=NA) +
# 					   xlab("Environmental Condition") +
# 					   ylab("Hatch Rate") +
# 					   scale_y_continuous(limits=c(0, 1)) +
# 					   scale_x_continuous(breaks=seq(130, 166, by=3),
# 					   					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 					   guides(fill=guide_legend(title="Model Type")) +
# 					   theme_lt
#
# ggsave(retaliationCompensation, filename="Figures/retaliationCompensation.png", width=10, height=10, unit="in")
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
# test <- data %>%
# 	 filter(model=="default") %>%
# 	 select(minEnergyThresh_F, maxEnergyThresh_F, minEnergyThresh_M, maxEnergyThresh_M, foragingMean, hatchRate, strategy_OVERALL) %>%
# 	 nest(-strategy_OVERALL) %>%
# 	 mutate(test=map(data, ~tidy(nls(hatchRate~SSlogis(foragingMean, Asym, xmid, scale), data=.x)))) %>%
# 	 unnest(cols=c(strategy_OVERALL, test)) %>%
# 	 select(strategy_OVERALL, term, estimate) %>%
# 	 pivot_wider(names_from=term, values_from=estimate) %>%
# 	 right_join(filter(data, model=="default"), by="strategy_OVERALL") %>%
#
# resiliency_vs_hatch <- ggplot(filter(test, foragingMean==163)) +
# 					geom_point(aes(x=hatchRate, y=160/xmid)) +
# 					theme_lt
#
# ggsave(resiliency_vs_hatch, filename="Figures/resiliency_vs_hatch.png", width=8, height=8, unit="in")
#
#
#
# resiliency_by_strategy <- ggplot(test) +
# 					    geom_tile(aes(x=maxEnergyThresh_F, y=maxEnergyThresh_M, fill=xmid)) +
# 					    facet_grid(cols=vars(minEnergyThresh_F), rows=vars(minEnergyThresh_M),
# 					    			 space="free", scales="free", switch="both", as.table=FALSE) +
# 		   			 	scale_fill_gradient(low="white", high="black") +
# 		   			 	scale_x_continuous(breaks=seq(0, 1000, by=50)) +
# 		   			 	scale_y_continuous(breaks=seq(0, 1000, by=50)) +
# 		   			 	guides(colour=guide_legend(title="Hatch Rate")) +
# 		   			 	theme_lt +
#   		   			 	theme(axis.text=element_text(size=4),
#    				  			  axis.text.x=element_text(angle=90, hjust=0.5),
#    				  			  plot.margin=margin(0, 0, 0, 0, "in"),
#    				  			  panel.spacing = unit(0, "lines"))
#
# ggsave(resiliency_by_strategy, filename="Figures/resiliency_by_strategy.png", width=8, height=8, unit="in")
#
#
#
# hatchRanks <- data %>%
# 		   filter(model=="default") %>%
# 	  	   select(minEnergyThresh_F, maxEnergyThresh_F,
# 	  			  minEnergyThresh_M, maxEnergyThresh_M,
# 	  			  foragingMean, hatchRate, hatchRank, strategy_OVERALL)
#
# topStrats <- hatchRanks %>%
# 		  filter(foragingMean==163) %>%
# 		  filter(hatchRank==max(hatchRank)) %>%
# 		  pull(strategy_OVERALL	)
#
# topData <- data %>%
# 		filter(strategy_OVERALL %in% topStrats)
#
#
# rankPlot <- ggplot(hatchRanks) +
# 		 geom_line(aes(x=foragingMean, y=hatchRank, group=strategy_OVERALL), colour="lightgray") +
# 		 geom_point(aes(x=foragingMean, y=hatchRank), colour="black", size=0.5) +
# 		 theme_lt
#
# ggsave(rankPlot, filename="Figures/rankPlot.png", height=30, width=10, unit="in")
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
# stratMeans_hunger_F <- empEnvironment %>%
# 					group_by(minEnergyThresh_F) %>%
# 					summarize(hatchRate=mean(hatchRate)) %>%
# 					select(thresh=minEnergyThresh_F, hatchRate) %>%
# 					mutate(threshType="min", sex="F")
#
# stratMeans_satiation_F <- empEnvironment %>%
# 					   group_by(maxEnergyThresh_F) %>%
# 					   summarize(hatchRate=mean(hatchRate)) %>%
# 					   select(thresh=maxEnergyThresh_F, hatchRate) %>%
# 					   mutate(threshType="max", sex="F")
#
# stratMeans_hunger_M <- empEnvironment %>%
# 					group_by(minEnergyThresh_M) %>%
# 					summarize(hatchRate=mean(hatchRate)) %>%
# 					select(thresh=minEnergyThresh_M, hatchRate) %>%
# 					mutate(threshType="min", sex="M")
#
# stratMeans_satiation_M <- empEnvironment %>%
# 					   group_by(maxEnergyThresh_M) %>%
# 					   summarize(hatchRate=mean(hatchRate)) %>%
# 					   select(thresh=maxEnergyThresh_M, hatchRate) %>%
# 					   mutate(threshType="max", sex="M")
#
# stratMeans <- bind_rows(stratMeans_hunger_F, stratMeans_satiation_F,
# 						stratMeans_hunger_M, stratMeans_satiation_M)
#
# plot_stratMeans_hunger <- ggplot(filter(stratMeans, threshType=="min")) +
# 					   geom_point(aes(x=thresh, y=hatchRate, colour=sex), alpha=0.3, size=0.5) +
# 					   geom_line(aes(x=thresh, y=hatchRate, colour=sex), alpha=0.5) +
# 					   scale_colour_manual(values=c("F"="red",
# 					  								"M"="blue")) +
# 					   scale_x_continuous(limits=c(0, 1000),
# 					   					  breaks=seq(0, 1000, by=200)) +
# 					   scale_y_continuous(limits=c(0, 1),
# 					   					  breaks=seq(0, 1, by=0.25)) +
# 					   xlab("Hunger threshold") +
# 					   ylab("Mean hatch") +
# 					   guides(colour=FALSE) +
# 					   theme_lt
#
# plot_stratMeans_satiation <- ggplot(filter(stratMeans, threshType=="max")) +
# 					      geom_point(aes(x=thresh, y=hatchRate, colour=sex), alpha=0.3, size=0.5) +
# 					      geom_line(aes(x=thresh, y=hatchRate, colour=sex), alpha=0.5) +
# 					      scale_colour_manual(values=c("F"="red",
# 					        						   "M"="blue")) +
# 					      scale_x_continuous(limits=c(0, 1000),
# 					   					     breaks=seq(0, 1000, by=200)) +
# 					      scale_y_continuous(limits=c(0, 1),
# 					   					     breaks=seq(0, 1, by=0.25)) +
# 					      xlab("Hunger threshold") +
# 					      ylab("Mean hatch") +
# 					      guides(colour=FALSE) +
# 					      theme_lt
#
# plots_stratMeans <- plot_grid(plot_stratMeans_hunger, plot_stratMeans_satiation, nrow=1)
# ggsave(plots_stratMeans, filename="Figures/stratMeans.png", width=6, height=3)
#
#
#
#
#
# hatchRateBYenvironment <- ggplot(data %>% filter(modelGroup=="regular")) +
# 					   geom_line(aes(x=foragingMean, y=hatchRate, group=ID), colour="lightgray") +
# 					   geom_boxplot(aes(x=foragingMean, y=hatchRate, group=interaction(model, foragingMean), fill=model), outlier.shape=NA) +
# 					   xlab("Environmental Condition") +
# 					   ylab("Hatch Rate") +
# 					   scale_y_continuous(limits=c(0, 1)) +
# 					   scale_x_continuous(breaks=seq(130, 166, by=3),
# 					   					  labels=map_chr(seq(130, 166, by=3), function(b){if((b-130)%%18==0){return(as.character(b))};return("")})) +
# 					   scale_fill_discrete(limits=c("default", "overlapRand", "noOverlap"),
# 					   					   labels=c("default"="Orderly switching",
# 					   								"noOverlap"="Ignoring mate",
# 					   								"overlapRand"="Random switching")) +
# 					   guides(fill=guide_legend(title="Model Type")) +
# 					   theme_lt
#
# ggsave(hatchRateBYenvironment, filename="Figures/hatchRateBYenvironment.png", width=10, height=10, unit="in")
#
#
# test <- data %>%
# 	 filter(model=="default") %>%
# 	 select(minEnergyThresh_F, maxEnergyThresh_F, minEnergyThresh_M, maxEnergyThresh_M, foragingMean, hatchRate, strategy_OVERALL) %>%
# 	 nest(-strategy_OVERALL) %>%
# 	 mutate(test=map(data, ~tidy(nls(hatchRate~SSlogis(foragingMean, Asym, xmid, scale), data=.x)))) %>%
# 	 unnest(cols=c(strategy_OVERALL, test)) %>%
# 	 select(strategy_OVERALL, term, estimate) %>%
# 	 pivot_wider(names_from=term, values_from=estimate) %>%
# 	 right_join(filter(data, model=="default"), by="strategy_OVERALL")
#
#
# stratResiliency <- ggplot(test) +
# 		   geom_tile(aes(x=minEnergyThresh_F, y=maxEnergyThresh_F, fill=xmid)) +
# 		   guides(colour=guide_legend(title="Midpoint of Logistic Curve \n for Hatch Rate ~ Environment")) +
# 		   theme_lt +
# 		   theme(axis.text=element_text(size=4),
# 		   		 axis.text.x=element_text(angle=90, hjust=0.5))
#
# ggsave(stratResiliency, filename="Figures/stratResiliency.png", width=10, height=10, unit="in")
#
# ggplot(test) +
# 	geom_point(aes(x=xmid, y=meanEnergy_OVERALL), colour="lightgray") +
# 	geom_line(aes(x=xmid, y=meanEnergy_OVERALL, group=minEnergyThresh_F, ))
# 	theme_lt
#
# ############################################################
# ### Strategy comparisons
# ############################################################
#
# test <- data %>%
# 	 filter(model=="default") %>%
# 	 arrange(minEnergyThresh_F, maxEnergyThresh_F, minEnergyThresh_M, maxEnergyThresh_M)
#
# m1 <- lm(data=test,
# 	     formula=hatchRate ~ foragingMean*minEnergyThresh_F*maxEnergyThresh_F*minEnergyThresh_M*maxEnergyThresh_M) %>%
#    tidy()
#
# lmEstimates <- ggplot(m1) +
# 			geom_bar(aes(x=term, y=log(abs(estimate))), stat="identity") +
# 			theme_lt +
# 			xlab("") +
# 			theme(axis.text.x=element_text(size=10, angle=90))
#
# ggsave(lmEstimates, filename="Figures/lmEstimates.png", width=15, height=10, unit="in")
#
#
# stratOrders <- seq(0, 950, by=50) %>%
# 			map(function(s) { return(paste(s, seq((s+50), 1000, by=50), sep="-")) }) %>%
# 			unlist()
#
# strategies <- ggplot(filter(data, model=="default" & foragingMean==160)) +
# 		   geom_tile(aes(x=strategy_F, y=strategy_M, fill=hatchRate)) +
# 		   scale_x_discrete(limits=stratOrders) +
# 		   scale_y_discrete(limits=stratOrders) +
# 		   guides(colour=guide_legend(title="Hatch Rate")) +
# 		   theme_lt +
# 		   theme(axis.text=element_text(size=4),
# 		   		 axis.text.x=element_text(angle=90, hjust=0.5))
#
# ggsave(strategies, filename="Figures/strategies.png", width=10, height=10, unit="in")
#
#
# ############################################################
# ### Overlap comparisons
# ############################################################
# overlapDiffs <- data %>%
# 			 filter(modelGroup=="regular") %>%
# 			 select(strategy_OVERALL, model, foragingMean, hatchRate) %>%
# 			 pivot_wider(names_from="model",
# 			   			 values_from="hatchRate") %>%
# 			 mutate(overlapEffect=default-noOverlap,
# 			 		randEffect=default-overlapRand,
# 			 		diffDiffs=randEffect-overlapEffect)
#
# overlapDiffComparison <- ggplot(overlapDiffs) +
# 					  geom_line(aes(x=foragingMean, y=overlapEffect, group=strategy_OVERALL), colour="lightgray") +
# 					  geom_boxplot(aes(x=foragingMean, y=overlapEffect, group=foragingMean)) +
# 					  geom_point(aes(x=foragingMean, y=overlapEffect, colour=default)) +
# 					  scale_colour_gradient(low="black",
#      				  						high="pink") +
# 					  xlab("Environmental condition") +
# 					  ylab("Effect of overlap") +
# 					  theme_lt
# ggsave(overlapDiffComparison, filename="Figures/overlapDiffComparison.png", width=10, height=6, unit="in")
#
# overlapRandComparison <- ggplot(overlapDiffs) +
# 				  geom_line(aes(x=foragingMean, y=randEffect, group=strategy_OVERALL), colour="lightgray") +
# 				  geom_boxplot(aes(x=foragingMean, y=randEffect, group=foragingMean)) +
# 				  geom_point(aes(x=foragingMean, y=randEffect, colour=default)) +
# 				  scale_colour_gradient(low="black",
#      			  						high="pink") +
# 				  xlab("Environmental condition") +
# 				  ylab("Effect of random switching") +
# 				  theme_lt
# ggsave(overlapRandComparison, filename="Figures/overlapRandComparison.png", width=10, height=6, unit="in")
#
# overlapDiffDiffs <- ggplot(overlapDiffs) +
# 				 geom_line(aes(foragingMean, diffDiffs, group=strategy_OVERALL), colour="lightgray")
# ggsave(overlapDiffDiffs, filename="Figures/overlapDiffDiffs.png", width=10, height=6, unit="in")
#
#
# overlapComparison <- ggplot(subset(data, modelGroup=="regular")) +
# 				  geom_line(aes(x=model, y=hatchRate, group=strategy_OVERALL), colour="lightgray") +
# 				  facet_grid(vars(foragingMean)) +
# 				  geom_boxplot(aes(x=model, y=hatchRate), width=0.25) +
# 				  scale_x_discrete(limits=c("noOverlap", "overlapRand", "default"),
# 				  				   labels=c("noOverlap" = "Ignoring mate",
# 				  			  				"default" = "Orderly switching",
# 				  			  				"overlapRand" = "Random switching")) +
# 				  xlab("") +
# 				  ylab("Success rate") +
# 				  theme_lt +
# 				  theme(axis.title.x = element_blank(),
# 				        axis.text.x = element_text(size=theme_lt$axis.title$size,
# 				        margin=margin(t=15),
# 				        color="black"))
#
# ggsave(overlapComparison, filename="Figures/overlapComparison.png", width=10, height=6, unit="in")
#
#
# ############################################################
# ### Retaliation and Compensation
# ############################################################
#
# reactionStrats <- ggplot(subset(data, (model=="standard" | modelGroup %in% c("compensation", "retaliation")) & foragingMean==160)) +
# 			geom_line(aes(x=model, y=hatchRate, group=strategy), colour="lightgray") +
# 			geom_boxplot(aes(x=model, y=hatchRate), width=0.25) +
# 			scale_x_discrete(limits=c("retaliation2", "retaliation", "standard", "compensation", "compensation2"),
# 				         labels=c("Retaliate\n(2d)", "Retaliate\n(1d)", "Normal", "Compensate\n(1d)", "Compensate\n(2d)")) +
# 			ylab("Success rate") +
# 			scale_y_continuous(limits=c(0, 1)) +
# 			theme_lt +
# 			theme(axis.title.x = element_blank(),
# 			      axis.text.x = element_text(size=theme_lt$axis.title$size,
# 			      				 margin=margin(t=15),
# 			      				 color="black"))
# ggsave(reactionStrats, filename="Figures/reactionStrats.png", width=11, height=6.3, unit="in")
#
# ############################################################
# ### Foraging mean comparisons
# ############################################################
#
# meanRates <- data %>%
# 				subset(model == "standard" |
# 				       modelGroup %in% c("compensation", "retaliation")) %>%
# 				group_by(foragingMean, model, modelGroup) %>%
# 				summarize(meanHR = mean(hatchRate))
#
# standardForagingMean <- ggplot(subset(data, model=="standard")) +
# 				geom_line(aes(x=foragingMean, y=hatchRate, group=strategy), colour="lightgray") +
# 				geom_line(data=subset(meanRates, model=="standard"),
# 					  aes(x=foragingMean, y=meanHR), size=1.3) +
# 				xlab("Environmental condition") +
# 				ylab("Success rate") +
# 				theme_lt
#
# ggsave(standardForagingMean, filename="Figures/standardForagingMean.png", width=6, height=6, unit="in")
#
#
# ############################################################
# ### Neglect comparisons
# ############################################################
#
#
# neglect <- ggplot(subset(data, model=="standard" & foragingMean==160)) +
# 			geom_point(aes(x=totNeglect, y=hatchRate), colour="black") +
# 			geom_line(aes(x=totNeglect, y=hatchRate, group=minEnergyThresh), colour="lightgray") +
# 			geom_line(aes(x=totNeglect, y=hatchRate, group=maxEnergyThresh), colour="cornflowerblue") +
# 			geom_point(aes(x=totNeglect, y=hatchRate), colour="black") +
# 			xlab("Total egg neglect (days)") +
# 			ylab("Success rate") +
# 			theme_lt
#
# ggsave(neglect, filename="Figures/neglect.png", width=6, height=6, unit="in")
#
#
# ############################################################
# ### Life history tradeoffs
# ############################################################
#
# foragingLabels <- function(fVal) {
# 	ret <- paste("Environment: ", fVal, sep="")
# 	return(ret)
# }
#
# toDF <- data %>%
# 			subset(model=="standard" & foragingMean %in% c(130, 145, 160)) %>%
# 			mutate(fLabel = map_chr(foragingMean, foragingLabels),
# 				   fLabel = factor(fLabel, levels=c("Environment: 160",
# 				   									"Environment: 145",
# 				   									"Environment: 130")))
#
#
# tradeoffs <- ggplot(toDF) +
# 				geom_point(aes(x=gEnergy_F, y=hatchRate), colour="lightgray") +
# 				geom_smooth(aes(x=gEnergy_F, y=hatchRate), colour="black", se=FALSE) +
# 				scale_x_continuous(breaks=seq(0, 1000, by=200), limits=c(-10, 1010)) +
# 				scale_y_continuous(breaks=c(0.00, 0.50, 1.0)) +
# 				ylab("Success rate") +
# 				xlab("Parent energy") +
# 				facet_grid(facets=vars(fLabel)) +
# 				theme_lt +
# 				theme(strip.text = element_text(size=theme_lt$axis.text.size, family="Gill Sans MT"),
# 				strip.background = element_rect(fill="white", colour="black"),
# 					  panel.spacing = unit(0.25, "in"))
#
# ggsave(tradeoffs, filename="Figures/tradeoffs.png", width=6, height=6, unit="in")
#
# ############################################################
# ### Life history buffering
# ############################################################
#
# deltaGE <- data %>%
# 				subset(model=="standard") %>%
# 				select(strategy, foragingMean, gEnergy_F) %>%
# 				nest(-strategy) %>%
# 				mutate(test = map(data, ~ lm(gEnergy_F ~ foragingMean, data=.x)),
# 					   lm = map(test, tidy)) %>%
# 				unnest(lm, .drop=TRUE) %>%
# 				select(strategy, term, estimate) %>%
# 				spread(key=term, value=estimate) %>%
# 				setNames(c("strategy", "iGE", "mGE"))
#
# deltaHR <- data %>%
# 				subset(model=="standard") %>%
# 				select(strategy, foragingMean, hatchRate) %>%
# 				nest(-strategy) %>%
# 				mutate(test = map(data, ~ lm(hatchRate ~ foragingMean, data=.x)),
# 					   lm = map(test, tidy)) %>%
# 				unnest(lm, .drop=TRUE) %>%
# 				select(strategy, term, estimate) %>%
# 				spread(key=term, value=estimate) %>%
# 				setNames(c("strategy", "iHR", "mHR"))
#
# srs <- data %>%
# 		subset(model=="standard" & foragingMean==160) %>%
# 		select(strategy, hatchRate)
#
# deltas <- full_join(deltaGE, deltaHR, by="strategy") %>%
# 			full_join(srs, by="strategy")
#
# buffering <- ggplot(deltas) +
# 				geom_point(aes(x=mGE, y=mHR, colour=hatchRate)) +
# 				xlab(expression(Delta*"Parent energy (~Environment)")) +
# 				ylab(expression(Delta*"Success rate (~Environment)")) +
# 				guides(colour=FALSE) +
# 				theme_lt
#
# ggsave(buffering, filename="Figures/buffering.png", width=6, height=6)
#
# ############################################################
# ### Life history buffering subplots
# ############################################################
#
# spDF <- data %>%
# 			subset(model=="standard" & (strategy=="50--400"))
#
#
# bufferSub1 <- ggplot(spDF) +
# 			geom_point(aes(x=foragingMean, y=hatchRate), colour="lightgray") +
# 			geom_smooth(aes(x=foragingMean, y=hatchRate, group=strategy), colour="black", method="lm", se=FALSE) +
# 			geom_hline(aes(yintercept=max(hatchRate)), colour="blue", linetype="dashed") +
# 			xlab("Environmental condition") +
# 			ylab("Success rate") +
# 			theme_lt +
# 			theme(axis.text = element_blank(),
# 				  axis.ticks = element_blank(),
# 				  axis.title = element_text(size=15))
#
# ggsave(bufferSub1, filename="Figures/bufferSub1.png", width=3, height=3)
#
# bufferSub2 <- ggplot(spDF) +
# 			geom_point(aes(x=foragingMean, y=gEnergy_F), colour="lightgray") +
# 			geom_smooth(aes(x=foragingMean, y=gEnergy_F), colour="black", method="lm", se=FALSE) +
# 			xlab("Environmental condition") +
# 			ylab("Parent energy") +
# 			theme_lt +
# 			theme(axis.text = element_blank(),
# 				  axis.ticks = element_blank(),
# 				  axis.title = element_text(size=15))
#
# ggsave(bufferSub2, filename="Figures/bufferSub2.png", width=3, height=3)
