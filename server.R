
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
source("influx.R")

options(shiny.host="0.0.0.0")
options(shiny.port=6102)

shinyServer(function(input, output) {
  db = "icinga"
  con = NULL
  host_data = FALSE
  
  if(is.null(con)) ({
    con <- connectToHost("localhost", 8086, "root", "root", db)
  })
  
  output$measurement <- renderUI({
    host_data = input$host_data
    measurements <- getMeasurements(con, db)
    
    
    if(is.null(input$measurement))
      selectInput("measurement", "Measurement", as.list(measurements))
    else 
      selectInput("measurement", "Measurement", as.list(measurements), selected = input$measurement)
    
  })
  
  output$plots <- renderUI({
    if(is.null(input$measurement)) 
      return()
    
    time = paste(input$time_length, input$time_units, sep = "")
    max_anoms = input$max_anoms / 100
    
    if(input$host_data) {
      measurement = input$measurement
      res <- checkAnomaliesForServiceHosts(con, db,  measurement, time, max_anoms)
      
      plot_output_list <- lapply(1:length(res), function(i) {
        local({
          my_i <- i
          if(length(res[[my_i]]$anoms$anoms) == 0)
            return()
          
          plotname <- paste("plot", my_i, sep = "")
          headername <- paste(plotname, "descrip", sep = "")
          header <- paste(length(res[[my_i]]$anoms$anoms), "anomalies detected")

          outputs = list(wellPanel(
            plotOutput(plotname, height = 280),
            textOutput(headername)
          ))
          
          output[[headername]] <- renderText({
            header
          })
          
          output[[plotname]] <- renderPlot({
            res[[my_i]]$plot
          })
          
          do.call(tagList, outputs)
        })
      })
      
      do.call(tagList, plot_output_list)
    }
    else {
      measurement = input$measurement
      res <- checkAnomaliesForService(con, db, measurement, time, max_anoms)
      outputname = "anomalyOutput"
      plotname = "distPlot"
      headername <- paste(plotname, "descrip", sep = "")
      header <- paste(length(res$anoms$anoms), " anomalies detected")
      
      outputs = list(wellPanel(
        plotOutput(plotname, height = 280),
        textOutput(headername)
      ))
      
      output[[plotname]] <- renderPlot({ 
        print(res$plot)
      })
      
      output[[headername]] <- renderText({
        header
      })
      
      do.call(tagList, outputs)
    }
  })
})