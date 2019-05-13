library(shiny)

# Define server logic 
shinyServer(function(input, output) {


  output$tilePlot <- renderPlot({
    d <- subset(successes, forg==input$foragingMean)

    ggplot(d) +
      geom_tile(aes(x=min, y=max, fill=prob)) 
  })

})
