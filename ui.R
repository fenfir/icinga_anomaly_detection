
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)

shinyUI(fluidPage(
  
  # Application title
  titlePanel("Icinga Anomalies"),
  
  # Sidebar with a slider input for number of bins
  sidebarPanel(
    checkboxInput("host_data", "Break down by host", value = TRUE),
    uiOutput("measurement"),
    
    numericInput("max_anoms", "Max percentage of anomalies:", 2, 1, 100),
    
    numericInput("time_length", "Time:", 30, 1, 90),
    selectInput("time_units", 
                "Time units:", 
                c("Seconds" = "s",
                  "Minutes" = "m",
                  "Hours" = "h",
                  "Days" = "d"),
                selected = "d"),
    
    numericInput("interval_length", "Interval:", 60, 1, 90),
    selectInput("interval_units", 
                "Interval units:", 
                c("Seconds" = "s",
                  "Minutes" = "m",                                                  
                  "Hours" = "h",
                  "Days" = "d"),
                selected = "d"),
    
    checkboxInput("residual_only", "Remove trend, then ESD residual", value = FALSE),
    submitButton("Submit")
  ),
  
  # Show a plot of the generated distribution
  mainPanel(
    uiOutput("plots")
  )
))
