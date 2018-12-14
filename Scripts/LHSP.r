
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

setwd("~/LHSP")

# setwd("C://Users//Liam//Documents//LHSP")

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

overlap_swap <- read_csv("Output/overlap_swap_output.txt") %>%
		    	mutate(model = "overlap_swap")

overlap_rand <- read_csv("Output/overlap_rand_output.txt") %>%
		    	mutate(model = "overlap_rand")

sexdiff <- read_csv("Output/sexdiff_output.txt") %>%
				mutate(model = "sexdiff") %>%
				mutate(coeff = (iteration%%5)+1)

foragingVar <- read_csv("Output/foragingvar_output.txt") %>%
						mutate(model = "foragingvar") %>%
						mutate(coeff = (iteration%%10)/10 + 1.1)

foragingMean <- read_csv("Output/foragingmean_output.txt") %>%
					mutate(model = "foragingmean") %>%
					mutate(coeff = (iteration%%10)/100 * 2 + 0.8)

# sexdiffcomp_1 <- read_csv("Output/sexdiffcomp_1_output.txt") %>%
# 					mutate(model="sexdiffcomp_1")

# sexdiffcomp_2 <- read_csv("Output/sexdiffcomp_2_output.txt") %>%
# 					mutate(model="sexdiffcomp_2")

sdf <- sexdiff %>%
		group_by(coeff, hatchSuccess) %>%
		count() %>%
		mutate(p = n / max(null$iteration)) %>%
		filter(hatchSuccess==1) %>%
		ungroup()

ms <- sexdiff %>%
		select(model, iteration, hatchSuccess, coeff, contains("_M")) %>%
		rename_at(.vars=vars(ends_with("_M")),
				  .funs=funs(sub("_M","",.))) %>%
		mutate(sex="m")

fs <- sexdiff %>%
		select(model, iteration, hatchSuccess, coeff, contains("_F")) %>%
		rename_at(.vars=vars(ends_with("_F")),
				  .funs=funs(sub("_F","",.))) %>%
		mutate(sex="f")

allSD <- bind_rows(ms, fs)

ggplot(sexdiff) +
	geom_freqpoly(aes(x=meanForaging_M, y=stat(density)), binwidth=1)

ggplot(allSD) +
	geom_freqpoly(aes(x=mean))
ggplot(allSD) +
	geom_boxplot(aes(x=factor(coeff), y=meanForaging, fill=sex))


ggplot(sdf) +
	geom_line(aes(x=coeff, y=p))

hs <- bind_rows(null, overlap_swap, overlap_rand) %>%
		group_by(model, hatchSuccess) %>%
		count() %>%
		filter(hatchSuccess == 1) %>%
		mutate(p = n / max(null$iteration)) %>%
		ungroup() %>%
		select(model, p)

all <- bind_rows(null, overlap_swap, overlap_rand)

ms <- all %>%
		select(model, iteration, hatchSuccess, contains("_M")) %>%
		rename_at(.vars=vars(ends_with("_M")),
				  .funs=funs(sub("_M","",.))) %>%
		mutate(sex="m")

fs <- all %>%
		select(model, iteration, hatchSuccess, contains("_F")) %>%
		rename_at(.vars=vars(ends_with("_F")),
				  .funs=funs(sub("_F","",.))) %>%
		mutate(sex="f")

energies <- bind_rows(ms, fs)

M_COLOR = "#ff6961"
F_COLOR = "#61a8ff"

ggplot(subset(energies, hatchSuccess==1)) +
	geom_boxplot(aes(x=model, y=meanForaging, fill=sex))

ggplot(subset(counts, hatchSuccess==1)) +
	geom_boxplot(aes(x=levels(model)-.25, y=endEnergy_M), fill=M_COLOR) +
	geom_boxplot(aes(x=levels(model)+.25, y=endEnergy_F), fill=F_COLOR)

