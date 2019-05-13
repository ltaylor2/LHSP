library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("Hello Shiny!"),

  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("foragingMean",
                  "Foraging Mean:",
                  min = 100,
                  max = 200,
                  value = 160,
                  step = 20)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("tilePlot")
    )
  )
))
