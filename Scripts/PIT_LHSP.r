# Older code (c. 2015) to read-in formatted passive integrated transponder data
readPITData <- function() {
  require(lubridate)
  require(tidyverse)

  init <- read.csv("Data/pit.csv", header = TRUE, stringsAsFactors = FALSE)

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

  # Format final data
  realIncBouts <- data_frame(boutLength=incLengths, 
                             individual=incIndividuals,
                             julianDate=julianDate,
                             endDatetime=endDatetime) %>%
                  mutate(model="real",
                         state="incubating")

  realForagingBouts <- data_frame(boutLength=fLengths,
                                  individual=fIndividuals,
                                  julianDate=fjulianDate,
                                  endDatetime=fendDatetime) %>%
                       mutate(model="real",
                              state="foraging")


  realForagingBouts$boutLength[18] <- realForagingBouts$boutLength[18] / 24

  realBouts <- bind_rows(realIncBouts, realForagingBouts) %>%
                select(model, state, boutLength)

  return(realBouts)
}
