library(shiny)

# Define server logic 
shinyServer(function(input, output) {


  output$tilePlot <- renderPlot({
    d <- subset(raw, foragingMean==input$foragingMean)

    ggplot(d) +
      geom_tile(aes(x=minEnergyThresh, y=maxEnergyThresh, fill=hatchRate)) +
      scale_fill_continuous(limits=c(0,1)) 
  })

})
