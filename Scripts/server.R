library(shiny)
library(gridExtra)

# Define server logic 
shinyServer(function(input, output) {


  output$tilePlot <- renderPlot({
    dF <- subset(rawF, foragingMean==input$foragingMean)

    g1 <- ggplot(dF) +
      geom_tile(aes(x=minEnergyThresh, y=maxEnergyThresh, fill=hatchRate)) +
      scale_fill_continuous(limits=c(0,1)) +
      ggtitle("Focal Female")

    dM <- subset(rawM, foragingMean==input$foragingMean)

    g2 <- ggplot(dM) +
      geom_tile(aes(x=minEnergyThresh, y=maxEnergyThresh, fill=hatchRate)) +
      scale_fill_continuous(limits=c(0,1)) +
      ggtitle("Focal Male")

    grid.arrange(grobs=list(g1, g2), nrow=1)
  })

})
