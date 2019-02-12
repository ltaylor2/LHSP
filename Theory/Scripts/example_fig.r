require(lubridate)
require(tidyverse)

setwd("~/Desktop/LHSP/Theory")
data <- read.csv("Data/pit.csv") %>%
          select(date = Date, time=Time, burrow=Burrow, parent=Parent, direction=Direction) %>%
          subset(burrow == 518) %>%
          mutate(datetime = paste(trimws(date), trimws(time), sep=" ")) %>%
          mutate(datetime = dmy_hms(datetime))

# example from burrow 518
# One = 3D9.1C2D700666 = 7901.11390 = M
# Two = 3D9.1C2D674494 = 7901.18763 = F

directionToState <- function(direction) {
  state = "incubating"
  if (direction == "Entrance") {
    state = "foraging"
  }
  return(state)
}

startRec <- min(data$datetime)
endRec <- max(data$datetime)

numMinutes <- ceiling(as.duration(endRec - startRec) / dminutes(1))

record <- data_frame(m = seq(1, numMinutes, by=1)) %>%
          mutate(p = startRec + dminutes(m), oneState=0, twoState=0)

p1 <- data %>% 
        subset(parent == "One") %>%
        mutate(prev = lag(datetime)) %>%
        filter(!is.na(prev)) %>%
        mutate(interval = interval(prev, datetime), state=map(direction, directionToState))

p1I <- p1 %>%
        subset(state == "incubating") %>%
        select(parent, state, interval)

p1F <- p1 %>%
        subset(state == "foraging") %>%
        select(parent, state, interval)


p2 <- data %>% 
        subset(parent == "Two") %>%
        mutate(prev = lag(datetime)) %>%
        filter(!is.na(prev)) %>%
        mutate(interval = interval(prev, datetime), state=map(direction, directionToState))

p2I <- p2 %>%
        subset(state == "incubating") %>%
        select(parent, state, interval)

p2F <- p2 %>%
        subset(state == "foraging") %>%
        select(parent, state, interval)

stateFromPeriod <- function(p, parent) {
  state = 0
  if (parent == "one") {
    tI <- p %within% p1I$interval
    tF <- p %within% p1F$interval

    if (length(which(tI==TRUE) > 0)) {
      state = 0.1
    } else if (length(which(tF==TRUE) > 0)) {
      state = 1
    }
  }
  if (parent == "two") {
    tI <- p %within% p2I$interval
    tF <- p %within% p2F$interval

    if (length(which(tI==TRUE) > 0)) {
      state = -0.1
    } else if (length(which(tF==TRUE) > 0)) {
      state = -1
    }
  }
  return(state)
}

eggState <- function(p1, p2) {
  eggState = ""

  if (p1 + p2 == 0) {
    if (p1 == 0.1) {
      eggState = "both"
    } else {
      eggState = "cold"
    }
  }
  else {
    eggState = "warm"
  }
  return(eggState)
}

record <- record %>%
            mutate(oneState=map2_dbl(p, "one", stateFromPeriod),
                   twoState=map2_dbl(p, "two", stateFromPeriod)) %>%
            filter(oneState != 0 & twoState != 0) %>%
            mutate(eggState = map2_chr(oneState, twoState, eggState))

g <- ggplot(record) +
      geom_line(aes(x=m, y=oneState), size=1) +
      geom_line(aes(x=m, y=twoState), size=1) +
      geom_point(data=subset(record, eggState=="warm" | eggState=="cold"),
                 aes(x=m, y=0, colour=eggState), size=2, shape=1) +
      geom_point(data=subset(record, eggState=="both"), 
                 aes(x=m, y=0, colour=eggState), size=0.8, shape=4) +
      scale_colour_manual(values=c("both"="gray", warm="#BB7784", cold="#7D87B9")) +
      guides(colour=FALSE) +
      xlab("Time") +
      ylab("") +
      scale_y_continuous(breaks=c(-1, -0.1, 0.1, 1),
                         labels=c("Female foraging", "Female incubating",
                                  "Male incubating", "Male foraging")) +
      theme_classic() +
      theme(panel.grid.major=element_blank(),
            panel.grid.minor=element_blank(),
            axis.title.x=element_text(size=10),
            axis.text.y=element_text(size=10),
            axis.text.x=element_blank(),
            axis.ticks.x=element_blank())

ggsave(g, filename="examplePlot.png", width=6, height=3)