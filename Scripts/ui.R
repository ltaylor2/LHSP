library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("Preliminary LHSP Analysis"),

  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("foragingMean",
                  "Foraging Mean:",
                  min = 130,
                  max = 160,
                  value = 130,
                  step = 3)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("tilePlot")
    )
  )
))
