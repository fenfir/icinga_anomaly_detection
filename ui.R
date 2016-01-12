
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
    tags$head(tags$style(type="text/css", "
             #loadmessage {
               position: fixed;
               top: 0px;
               left: 0px;
               width: 100%;
               padding: 5px 0px 5px 0px;
               text-align: center;
               font-weight: bold;
               font-size: 100%;
               color: #000000;
               background-color: #CCFF66;
               z-index: 105;
             }
          ")),
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
    submitButton("Submit"),
    conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                     tags$div("Loading...",id="loadmessage"))
  ),
  
  # Show a plot of the generated distribution
  mainPanel(
    uiOutput("plots")
  )
))
