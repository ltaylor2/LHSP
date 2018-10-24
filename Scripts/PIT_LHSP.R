### OLD CODE ALERT! From young Liam in 2015. Will fix when the project actually starts. ###

setwd("C://Users//Liam//Documents//LHSP")

require(lubridate)
require(tidyverse)
require(gridExtra)

init <- read.csv("Data/spit.csv", header = TRUE, stringsAsFactors = FALSE)

init$Date <- dmy(init$Date)
init <- unite(init, Datetime, Date, Time, sep = " ")
init$Datetime <- ymd_hms(init$Datetime)
init <- unite(init, Individual, Burrow, Parent, sep = "_")

# Finding all raw incubation periods --------------------------------------

init$Individual <- factor(init$Individual)

birds <- levels(init$Individual)

incLengths <- c()
julianDate <- c()
endDatetime <- c()
fLengths <- c()
incIndividuals <- c()
fIndividuals <- c()
fjulianDate <- c()
fendDatetime <- c()

for (i in 1:length(birds)) {
  tmp <- subset(init, Individual == birds[i])
  for (r in 1:nrow(tmp)) {
    if (tmp$Direction[r] == "Entrance") {
      startIncPeriod <- tmp$Datetime[r]
      if (r > 1) {
        fLengths <- c(fLengths, tmp$Datetime[r] - startFPeriod)
        fIndividuals <- c(fIndividuals, birds[i])
        fjulianDate <- c(fjulianDate, yday(tmp$Datetime[r]))
        fendDatetime <- append(fendDatetime, tmp$Datetime[r])
      }
    }
    else if (tmp$Direction[r] == "Exit") {
      startFPeriod <- tmp$Datetime[r]
      if (r > 1) {
        incLengths <- c(incLengths, tmp$Datetime[r] - startIncPeriod)
        incIndividuals <- c(incIndividuals, birds[i])
        julianDate <- c(julianDate, yday(tmp$Datetime[r]))
        endDatetime <- append(endDatetime, tmp$Datetime[r])
      }
    }
  }
}

## raw incubation lists
incubations <- bind_cols(as.data.frame(incLengths), as.data.frame(incIndividuals), as.data.frame(julianDate), as.data.frame(endDatetime))
foragings <- bind_cols(as.data.frame(fLengths), as.data.frame(fIndividuals), as.data.frame(fjulianDate), as.data.frame(fendDatetime))

######TODO FIX THIS DUMB FIX, only one foraging length is in hours-->make it days
foragings$fLengths[18] <- foragings$fLengths[18] / 24

g1 <- ggplot(incubations) + 
		geom_freqpoly(aes(x=incLengths, y=stat(count / sum(count))), binwidth=1) +
		ylab("Density") +
		xlab("Incubation Bout Length (Days)") + 
		scale_x_continuous(limits=c(0, 10), breaks=0:10) +
		scale_y_continuous(limits=c(0, 0.4), breaks=seq(0, 0.4, by=0.1)) +
		theme_classic()


g2 <- ggplot(foragings) + 
		geom_freqpoly(aes(x=fLengths, y=stat(count / sum(count))), binwidth=1) +
		ylab("") +
		xlab("Foraging Bout Length (Days)") + 
		scale_x_continuous(limits=c(0, 10), breaks=0:10) +
		scale_y_continuous(limits=c(0, 0.4), breaks=seq(0, 0.4, by=0.1)) +
		theme_classic()

plots <- arrangeGrob(g1, g2, nrow=1, ncol=2)

ggsave(filename="Output/Proposal_Fig_2.png", plot=plots, width=6, height=3)