# setwd("/DIR OF LHSP SRC/")
system("make clean")
system("make")
system("./lhsp")

results.df <- read.csv("Results.txt", header = FALSE)
colnames(results.df) = c("Male_PC", "Male_RC", "Female_PC", "Female_RC", "Breeding_Success")

# install.packages("ggplot2")
library(ggplot2)

ggplot(results.df, aes(x = Male_PC, y = Male_RC)) +
  geom_tile(aes(fill = results.df$Breeding_Success))

ggplot(results.df, aes(x = Female_PC, y = Female_RC)) +
  geom_tile(aes(fill = results.df$Breeding_Success))

