#
# This is a Shiny application for interacting with water quality data.
# It has been built as a proof of concept for interactive environmental monitoring data.
#
# 
#
# Author Jeff Cooke September 2021, generalised from an earlier version originally created in 2016.

library(shiny)
library(ggplot2)
library(plyr)
library(leaflet)
library(RColorBrewer)

# Import the data.

wqdata <- read.csv(file = "data/wqdata.csv", stringsAsFactors = FALSE)
# Convert datetime from string 
wqdata$DateTime <- as.POSIXct(wqdata$DateTime, format = "%d/%m/%Y %H:%M")
# Make sure that the Value field is numeric
wqdata$Value <- as.numeric(wqdata$Value)

sitedata <- read.csv(file = "data/sitedata.csv", stringsAsFactors = FALSE)

# Make sure that the latitude and longitude fields are numberic
sitedata$Latitude <- as.numeric(sitedata$Latitude)
sitedata$Longitude <- as.numeric(sitedata$Longitude)

measurementdata <- read.csv(file = "data/WQMeasurements.csv", stringsAsFactors = FALSE)

# Merge the data into a single dataset
mergedData <- merge(wqdata,sitedata, by="Site")

mergedData <- merge(mergedData, measurementdata, by="Measurement")


shinyServer(function(input, output) {
  #This function was required when the Measurement was stored differently than how 
  #it should be displayed, it is now redundant, but left in case it is useful later.
  #dfmeas <- reactive({
  #  if(input$meas=="Total Phosphorus"){return("Total Phosphorus[Total Phosphorus]")}else{return(as.character(input$meas))}
  #})
  
  # Reactive expression to filter the data based on user options and create the subset for display
  # Filters the data by catchment, measurement and date range.
  datasubset <- reactive({
      mergedData[mergedData$Catchment==input$catch & 
                   mergedData$StdMeasurementName ==input$meas & 
                   mergedData$DateTime >= as.POSIXct(input$dates[1]) & 
                   mergedData$DateTime <= as.POSIXct(input$dates[2]),]

      })

    
    # Reorder the factors for plotting based on user input.  
    # Reorders the sites for the boxplot.
    reordered<- reactive({
      tempdf<-datasubset()
      if(input$siteord=="West-East") {tempdf$Site<- factor(tempdf$Site, levels = unique(tempdf$Site[order(tempdf$Longitude, decreasing=FALSE)]))
        return(tempdf)
      }else if(input$siteord=="East-West"){tempdf$Site<- factor(tempdf$Site, levels = unique(tempdf$Site[order(tempdf$Longitude, decreasing=TRUE)]))
        return(tempdf)
      }else if(input$siteord=="North-South"){tempdf$Site<- factor(tempdf$Site, levels = unique(tempdf$Site[order(tempdf$Latitude, decreasing=FALSE)]))
      return(tempdf)
      }else{tempdf$Site<- factor(tempdf$Site, levels = unique(tempdf$Site[order(tempdf$Latitude, decreasing=TRUE)]))
      return(tempdf)
      }
    })
    
    #Create a title for the table and graphs based on user input
    texttitle<- reactive({
      paste("Summary Of",input$meas, 
            "Results In The", input$catch, 
            "Catchment Between",format(input$dates[1], format="%d %B %Y"),
            "And",format(input$dates[2], format="%d %B %Y"),".")
    })
    
    maptitle <- reactive({
      paste(input$mapstat,input$meas,
            "Concentrations In The",input$catch,
            "Catchment Between",format(input$dates[1], format="%d %B %Y"),
            "And",format(input$dates[2], format="%d %B %Y"),".")
    })
    
    #Create a dataframe of summary statistics for each site based on user input.
    # The summary stats are minimum, 25th percentile, mean, median, 75th percentile, 95th percentile and maximum
    # The quartiles are calculated using R type 5, which is equivalent to the Hazen method.
    summarydata <- reactive({
      ddply(datasubset(), c("Site"), summarise,
            min = min(Value), 
            lowerquartile = quantile(Value, c(0.25), type = 5),
            mean = mean(Value), 
            median=median(Value),
            upperquartile = quantile(Value, c(0.75), type = 5),
            percentile95 = quantile(Value, c(0.95), type = 5),
            max = max(Value))
    })
    
    # Create a dataframe of summarised data for showing on the map.
    # The summary stats are mean, median, 95th percentile and maximum.
    # The quartiles are calculated using R type 5, which is equivalent to the Hazen method.
    # The additional fields are to allow banding and colour options to be set from the measurements.csv file.
    
    mapsummary <- reactive({
      ddply(datasubset(), c("Site", "Units", "StdMeasurementName", "RadiusFactor", "BandMin", "Band1", "Band2", "Band3", "Band4", "BandMax", "Brewer_Pallette"), summarise,
            mean = mean(Value), 
            median=median(Value),
            percentile95 = quantile(Value, c(0.95), type = 5),
            max = max(Value))
    })
    
    # Create bins so that map colours can be set.
    # The bin boundaries are set in the measurements.csv file and propogated through the map summary.
    bins <- reactive({
      
      return(c(min(mapsummary()$BandMin),
               min(mapsummary()$Band1),
               min(mapsummary()$Band2),
               min(mapsummary()$Band3), 
               min(mapsummary()$Band4), 
               min(mapsummary()$BandMax)))
    })
    
    # Set the colours for the bins.
    # The colour scale is set from the measurements.csv file.
    binpal <- reactive({
      st<-mapstats()
      # pallette<-rev(brewer.pal(length(bins()), "RdYlBu"))
      pallette<-rev(brewer.pal(length(bins()), min(mapsummary()$Brewer_Pallette)))
      colorBin(pallette, summarywithlocation()[[st]], bins(), pretty = FALSE)
      
    })
    
    #Add locations to the summary information so that the data can be plotted on a map
    summarywithlocation <- reactive({
      merge(mapsummary(),sitedata, by="Site")
    })
    
    # Convert the UI statistics names to match the server names.
    mapstats<-reactive({
      if(input$mapstat=="95th Percentile"){return("percentile95")}else{return(tolower(as.character(input$mapstat)))}
    })
    
    # Make the site names wrap over multiple lines, so that they plot nicer.
    wrapped<-reactive({
      tdf<-datasubset()
      tdf$Site<-sapply(strwrap(as.character(tdf$Site), width=25, simplify=FALSE), paste, collapse="\n")
      tdf$Site<-factor(tdf$Site)
    })
    
    #set the download output, currently just the data without any site location information
    output$downloadData <- downloadHandler(
         filename = function() {
           paste('data-', Sys.Date(), '.csv', sep='')
         },
         content = function(con) {
           write.csv(datasubset(), con)
         }
       )
  # Output the titles for the map, plot and table  
  output$plottext <- renderText({
    texttitle()
  })
  
  output$tabletext <- renderText({
    texttitle()
  })
  
  output$maptext <- renderText({
    maptitle()
  })
  
  # Basic error message in case no data available for boxplot.   
  output$boxPlot <- renderPlot({
    validate(
      need(length(reordered()$Site) > 0, "No results for that measurement in this area.")
    )
   #create the boxplot
    
    ggplot(reordered() , aes(Site, Value)) + 
      geom_boxplot(fill="#b8e186") + 
      xlab("Site") +
      ylab(paste(input$meas, " (", min(reordered()$Units), ")")) +
      theme_bw() +
      theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5)) 
      
    
  })
  
  # Create the output table
  output$table <- renderDataTable({
    validate(
      need(length(summarydata()$Site) > 0, "No results for that measurement in this area.")
    )
    format(summarydata(), digits=3)
    
  }, options = list(
    columnDefs = list(list(className = 'dt-center', targets = 5))))
  
  # Create the output map.
  output$map <- renderLeaflet({
    validate(
      need(length(summarywithlocation()$Site) > 0, "No results for that measurement in this area.")
    )
    pal<-binpal()
    st<-mapstats()
    leaflet() %>%
      addTiles() %>%
      addCircleMarkers(data = summarywithlocation(), 
                       # Modify the size of the circle based on the value and a scaling factor from measurements.csv
                       radius = 5+as.numeric(summarywithlocation()$RadiusFactor)*sqrt(as.numeric(summarywithlocation()[[st]])),
                       weight = 2, color = "#777777",
                       # Use the bin pallette fill colours
                       fillColor = pal(summarywithlocation()[[st]]), fillOpacity = 0.9,
                       # Add a pop up
                       popup = paste(summarywithlocation()$Site,"<br/> ",
                                     input$mapstat," ",input$meas," ",
                                     summarywithlocation()[[st]]," (", summarywithlocation()$Units, ")",sep="")) %>%
      clearBounds() %>%
      
      addLegend(position = "bottomright",
                pal = pal, values = summarywithlocation()[[st]]
      )
      
  })
  
})
