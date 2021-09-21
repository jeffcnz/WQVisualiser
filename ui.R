#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# This is a Shiny application for interacting with water quality data.
# It has been built as a proof of concept for interactive environmental monitoring data.
#

# Author Jeff Cooke September 2021, generalised from an earlier version originally created in 2016.



library(shiny)
library(ggplot2)
library(leaflet)

# Import the data and configuration

sitedata <- read.csv(file = "data/sitedata.csv", stringsAsFactors = FALSE)
wqdata <- read.csv(file = "data/wqdata.csv", stringsAsFactors = FALSE)
measurementdata <- read.csv(file = "data/WQMeasurements.csv", stringsAsFactors = FALSE)
configData <- read.csv(file = "data/Config.csv", stringsAsFactors = FALSE)

# Combine the water quality data and site information
mergedData <- merge(wqdata, measurementdata, by="Measurement")

# Get a unique list of catchments to populate the drop downs with
catchments<-sort(unique(sitedata$Catchment))

# Get a unique list of measurements
measurements<-unique(mergedData$StdMeasurementName)

# Define the options for the drop downs
siteorder<-c("West-East", "East-West", "North-South", "South-North")
mapstat <- c("Median", "Mean", "95th Percentile")

# Define UI for the application 
shinyUI(fluidPage(theme = "bootstrap.css",
  
  # Application title - from config file
  #titlePanel("Surface Water Quality"),
  titlePanel(configData$Value[configData$Variable == "AppTitle"]),
  
  # Sidebar with a slider input for number of bins 
  #sidebarLayout(
    #sidebarPanel(
  fluidRow(
    column(width = 4,
           tabsetPanel(
             tabPanel("Filters",
                      # The filter panel for the map, plots and table
                      
               # Filter by catchment
               selectInput("catch",
                           label = "Catchment:",
                           choices = catchments,
                           selected = configData$Value[configData$Variable == "DefaultCatchment"]),
                   
               # Filter by measurement
               selectInput("meas",
                           label = "Measurement:",
                           choices= measurements,
                           selected = configData$Value[configData$Variable == "DefaultMeasurement"]),
                   
               # Select the site order for the boxplots
               selectInput("siteord",
                           label = "Plot Sites Ordered:",
                           choices = siteorder,
                           selected = configData$Value[configData$Variable == "DefaultPlotOrder"]),
                   
               # Select the date ranges
               dateRangeInput("dates",
                           label = "Date Range:",
                           start = as.character(min(as.POSIXct(wqdata$DateTime, format="%d/%m/%Y %H:%M")), format="%Y-%m-%d"),
                           end = as.character(max(as.POSIXct(wqdata$DateTime, format="%d/%m/%Y %H:%M")), format="%Y-%m-%d"),
                           min = as.character(min(as.POSIXct(wqdata$DateTime, format="%d/%m/%Y %H:%M")), format="%Y-%m-%d"),
                           max = as.character(max(as.POSIXct(wqdata$DateTime, format="%d/%m/%Y %H:%M")), format="%Y-%m-%d"),
                           format = "dd-M-yyyy",
                           startview = "decade"
                             ),
               # Select the map statistic to use for summarising
               selectInput("mapstat",
                           label = "Map Statistic:",
                           choices = mapstat,
                           selected="median")
       
       
             ),
            tabPanel(
              # A panel describing what the app shows
              "About",
               p(configData$Value[configData$Variable == "AboutText"])
         
             ),
            tabPanel(
              # A panel to allow data to be downloaded
              "Download", 
              h5(configData$Value[configData$Variable == "DownloadText"]),
              downloadButton('downloadData', 'Download Selected Data')
                     )
                  )
           ),
    
    # Show a plot of the generated distribution
    #mainPanel(
    column(width = 8,  
      
      tabsetPanel(
        # The output tabs, a map, boxplot and table.
        tabPanel("Map", h5(textOutput("maptext"), align = "center"),leafletOutput("map", height=500)),
        tabPanel("Boxplots", h5(textOutput("plottext"), align = "center"), plotOutput("boxPlot", height= 500)),
        tabPanel("Table", h5(textOutput("tabletext"), align = "center"), dataTableOutput("table"))#, height = "auto"
      
    )
    )
  )
))
