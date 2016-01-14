# setwd("/DIR OF LHSP SRC/")
setwd("LHSP/src")
system("make clean")
system("make")
system("./lhsp")

results.df <- read.csv("Results.txt", header = FALSE)
colnames(results.df) = c("Male_PC", "Male_RC", "Female_PC", "Female_RC", "Breeding_Success")
# install.packages(c("ggplot2", "dplyr"))
library(ggplot2)
library(dplyr)

maleStats <- results.df %>%
                group_by(Male_PC, Male_RC) %>%
                summarise(Percent_Success = mean(Breeding_Success) * 100)

femaleStats <- results.df %>%
                group_by(Female_PC, Female_RC) %>%
                summarise(Percent_Success = mean(Breeding_Success) * 100)

ggplot(maleStats, aes(x = Male_PC, y = Male_RC)) +
  geom_tile(aes(fill = Percent_Success)) +
  scale_x_continuous(breaks = seq(0, 1, .25), labels = seq(0, 1, .25))

ggplot(femaleStats, aes(x = Female_PC, y = Female_RC)) +
  geom_tile(aes(fill = Percent_Success)) +
  scale_x_continuous(breaks = seq(0, 1, .25), labels = seq(0, 1, .25))
