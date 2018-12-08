# TODO
# Confirm energetics values (esp. minimum energy threshold and BMR)
# Send iterations through R
# Sex-specific differences
# Confirm longest egg threshold
# Look at neglect parameters
# Verify initial behavior

# logistics
library(Rcpp)
library(tidyverse)

# setwd("~/Desktop/LHSP")

setwd("C://Users//Liam//Documents//LHSP")

Sys.setenv("PKG_CXXFLAGS"="-std=c++11")

# Src C++ functions and call models. 
# See hpp and main.cpp files for details
scriptFiles <- list.files("Scripts/", full.names=TRUE)
invisible(file.remove(scriptFiles[grep(".o", scriptFiles)]))

Rcpp::sourceCpp("Scripts/main.cpp")
main()

# Read in output data
null <- read_csv("Output/null_output.txt") %>%
			mutate(model = "null")

# overlap <- read_csv("Output/overlap_output.txt") %>%
# 		    	mutate(model = "overlap")

# sexdiff <- read_csv("Output/sexdiff_output.txt") %>%
# 				mutate(model = "sexdiff")

# sexdiffcomp <- read_csv("Output/sexdiffcomp_output.txt") %>%
# 					mutate(model = "sexdiffcomp")

# foragingdiff <- read_csv("Output/foragingdiff_output.txt") %>%
# 					mutate(model = "foragingdiff")

# # Summarize and prelim analysis

# od <- overlap %>%
# 		group_by(hatchSuccess) %>%
# 		count() %>%
# 		filter(hatchSuccess == 1) %>%
# 		mutate(p = n / max(overlap$iteration))

# sd <- bind_rows(sexdiff, sexdiffcomp) %>%
# 		group_by(model, coeff = iteration%%10, hatchSuccess) %>%
# 		count() %>%
# 		ungroup() %>%
# 		mutate(coeff = coeff / 10) %>%
# 		filter(hatchSuccess == 1) %>%
# 		mutate(p = n / max(sexdiff$iteration / 10)) %>%
# 		bind_rows(mutate(od, coeff=1.0))

# sdPlot <- ggplot(sd) +
# 			geom_line(aes(x=coeff, y=p, color=model)) +
# 			theme_bw()

# fd <- foragingdiff %>%
# 		group_by(coeff = iteration%%10, hatchSuccess) %>%
# 		count() %>%
# 		ungroup() %>%
# 		mutate(coeff = (coeff / 10) + 1.1) %>%
# 		filter(hatchSuccess == 1) %>%
# 		mutate(p = n / max(foragingdiff$iteration / 10)) %>%
# 		bind_rows(mutate(od, coeff=1))

# fdPlot <- ggplot(fd) +
# 				geom_line(aes(x=coeff, y=p)) +
# 				theme_bw()

# energyComp <- bind_rows(null, overlap, subset(sexdiff, iteration%%10==5), subset(foragingdiff, iteration%%10==5))

# ggplot(energyComp) +
# 	geom_boxplot(aes(x=model, y=energy_M, group=hatchSuccess))

# count <- bind_rows(null, overlap) %>%
# 			group_by(model, hatchSuccess) %>%
# 			count() %>%
# 			mutate(p = n / max(null$iteration)) %>%
# 			filter(hatchSuccess == 1)