# logistics
library(Rcpp)
library(tidyverse)

setwd("~/LHSP")
Sys.setenv("PKG_CXXFLAGS"="-std=c++11")

# Src C++ functions and call models. 
# See hpp and main.cpp files for details
scriptFiles <- list.files("Scripts/")
file.remove(scriptFiles[grep(".o", scriptFiles)])

Rcpp::sourceCpp("Scripts/main.cpp")
main()

# Read in output data
null <- read_csv("Output/null_output.txt") %>%
			mutate(model = "null")

overlap <- read_csv("Output/overlap_output.txt") %>%
		    	mutate(model = "overlap")

# Summarize and prelim analysis
d <- bind_rows(null, overlap) 

counts <- d %>%
			group_by(model, hatchSuccess) %>%
			count() %>%
			mutate(p = n / max(null$iteration))	 # TODO SEND ITERATIONS FROM R

counts