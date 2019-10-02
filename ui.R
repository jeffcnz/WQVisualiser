#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(leaflet)
#load("data/HbrcWqData.RData")
load("data/HbrcWqSites.RData")

#catchments<-unique(as.character(swQualitySites$ns3.Catchment))

catchments<-sort(unique(swQualitySites$Catchment))


#measurements<-unique(hbrcwqdata$Measurement)
measurements<-c("Dissolved Reactive Phosphorus",
                "Total Phosphorus",
                "Ammoniacal Nitrogen",
                "Nitrate Nitrogen",
                "Nitrite Nitrogen",
                "Nitrate + Nitrite Nitrogen",
                "Total Nitrogen")

siteorder<-c("West-East", "East-West", "North-South", "South-North")
mapstat <- c("Median", "Mean", "95th Percentile")

# Define UI for application that draws a histogram
shinyUI(fluidPage(theme = "bootstrap.css",
  
  # Application title
  titlePanel("Hawke's Bay Surface Water Quality"),
  
  # Sidebar with a slider input for number of bins 
  #sidebarLayout(
    #sidebarPanel(
  fluidRow(
    column(width = 4,
           tabsetPanel(
             tabPanel("Filters",
      
       selectInput("catch",
                   label = "Catchment:",
                   choices = catchments,
                   selected = "Tukituki River"),
       
       selectInput("meas",
                   label = "Measurement:",
                   choices= measurements,
                   selected = "Total Nitrogen"),
       
       selectInput("siteord",
                   label = "Plot Sites Ordered:",
                   choices = siteorder,
                   selected = "West-East"),
       
       dateRangeInput("dates",
                      label = "Date Range:",
                      start = "2004-01-01",
                      end = "2019-01-01",
                      min = "2004-01-01",
                      max = "2019-01-01",
                      format = "dd-M-yyyy",
                      startview = "decade"
                        ),
       selectInput("mapstat",
                   label = "Map Statistic:",
                   choices = mapstat,
                   selected="median")
       
       
           ),
       tabPanel(
         "About",
         p("This application is a proof of concept for the public display, 
           interaction and download of data.")
       ),
       tabPanel(
         "Download", 
         h5("Data is from the HBRC State of the Environment monitoring program."),
         downloadButton('downloadData', 'Download Selected Data')
       )
           )
    ),
    
    # Show a plot of the generated distribution
    #mainPanel(
    column(width = 8,  
      
      tabsetPanel(
       tabPanel("Map", h5(textOutput("maptext"), align = "center"),leafletOutput("map", height=500)),
       tabPanel("Boxplots", h5(textOutput("plottext"), align = "center"), plotOutput("boxPlot", height= 500)),
       tabPanel("Table", h5(textOutput("tabletext"), align = "center"), dataTableOutput("table"))#, height = "auto"
      #textOutput("Debugger")
    )
    )
  )
))
