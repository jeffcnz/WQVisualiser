#
# This is a Shiny application for interacting with water quality data.
# It has been built as a proof of concept for interactive environmental monitoring data.
#
# 
#

library(shiny)
library(ggplot2)
library(plyr)
library(leaflet)
library(RColorBrewer)

load("data/HbrcWqData.RData")
load("data/HbrcWqSites.RData")

mergedData<-merge(hbrcwqdata,swQualitySites, by.x="Site", by.y="ns3.CouncilSiteID")


shinyServer(function(input, output) {
  #This function was required when the Measurement was stored differently than how 
  #it should be displayed, it is now redundant, but left in case it is useful later.
  dfmeas <- reactive({
    if(input$meas=="Total Phosphorus"){return("Total Phosphorus[Total Phosphorus]")}else{return(as.character(input$meas))}
  })
  
  #reactive expression to filter the data based on user options
  datasubset <- reactive({
      mergedData[mergedData$ns3.Catchment==input$catch & 
                   mergedData$Measurement==input$meas & 
                   mergedData$Time >= as.POSIXct(input$dates[1]) & 
                   mergedData$Time <= as.POSIXct(input$dates[2]),]

      })

    
    #reorder the factors for plotting based on user input
    reordered<- reactive({
      tempdf<-datasubset()
      #tempdf<-wrapped()
      if(input$siteord=="West-East") {tempdf$Site<- factor(tempdf$Site, levels = tempdf$Site[order(tempdf$long, decreasing=FALSE)])
        return(tempdf)
      }else if(input$siteord=="East-West"){tempdf$Site<- factor(tempdf$Site, levels = tempdf$Site[order(tempdf$long, decreasing=TRUE)])
        return(tempdf)
      }else if(input$siteord=="North-South"){tempdf$Site<- factor(tempdf$Site, levels = tempdf$Site[order(tempdf$lat, decreasing=FALSE)])
      return(tempdf)
      }else{tempdf$Site<- factor(tempdf$Site, levels = tempdf$Site[order(tempdf$lat, decreasing=TRUE)])
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
    
    #Create a dataframe of summary statistics for each site based on user input
    summarydata <- reactive({
      ddply(datasubset(), c("Site"), summarise,
            min = min(result), 
            lowerquartile = quantile(result, c(0.25)),
            mean = mean(result), median=median(result),
            upperquartile = quantile(result, c(0.75)),
            max = max(result))
    })
    
    mapsummary <- reactive({
      ddply(datasubset(), c("Site"), summarise,
            mean = mean(result), median=median(result),
            percentile95 = quantile(result, c(0.95)),
            max = max(result))
    })
    
    bins <- reactive({
      if(regexpr('Nitrogen', input$meas)==-1){
        return(c(0,0.05,0.1,0.5,1,2))
      }else{
          return(c(0,0.1,0.4,0.8,2,6))
        }
    })
    
    binpal <- reactive({
      st<-mapstats()
      pallette<-rev(brewer.pal(length(bins()), "RdYlBu"))
      colorBin(pallette, summarywithlocation()[[st]], bins(), pretty = FALSE)
      
    })
    
    #Add locations to the summary information so that the data can be plotted on a map
    summarywithlocation <- reactive({
      merge(mapsummary(),swQualitySites, by.x="Site", by.y="ns3.CouncilSiteID")
    })
    
    mapstats<-reactive({
      if(input$mapstat=="95th Percentile"){return("percentile95")}else{return(tolower(as.character(input$mapstat)))}
    })
    
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
    
  output$plottext <- renderText({
    texttitle()
  })
  
  output$tabletext <- renderText({
    texttitle()
  })
  
  output$maptext <- renderText({
    maptitle()
  })
     
  output$boxPlot <- renderPlot({
   #create the boxplot
    #tdf<-reordered()
    #levels(tdf$Site) <- function(levels(tdf$Site),20){as.character(sapply(levels(tdf$Site),FUN=function(x){paste(strwrap(x,width=20), collapse="\n")}))}
    
    #wrapped<-sapply(strwrap(as.character(reordered()$Site), width=25, simplify=FALSE), paste, collapse="\n")
    #ggplot(wrapped(), aes(Site, result)) +
    ggplot(reordered() , aes(Site, result)) + 
      geom_boxplot(fill="#b8e186") + 
      xlab("Site") +
      ylab(paste(input$meas,"(mg/l)")) +
      theme_bw() +
      theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5)) 
      
    
    
      #coord_flip()
    
  })
  
  output$table <- renderDataTable({
    
    format(summarydata(), digits=3)
    
  }, options = list(
    columnDefs = list(list(className = 'dt-center', targets = 5))))
  
  output$map <- renderLeaflet({
    pal<-binpal()
    st<-mapstats()
    leaflet() %>%
      addTiles() %>%
      addCircleMarkers(data = summarywithlocation(), 
                       radius = 5+5*sqrt(as.numeric(summarywithlocation()[[st]])),
                       weight = 2, color = "#777777",
                       fillColor = pal(summarywithlocation()[[st]]), fillOpacity = 0.9,
                       popup = paste(summarywithlocation()$Site,"<br/> ",
                                     input$mapstat," ",input$meas," Concentration ",
                                     summarywithlocation()[[st]]," mg/l",sep="")) %>%
      
      fitBounds(min(summarywithlocation()$long), 
                min(summarywithlocation()$lat), 
                max(summarywithlocation()$long), 
                max(summarywithlocation()$lat)) %>%
      addLegend(position = "bottomright",
                pal = pal, values = summarywithlocation()[[st]]
      )
      
  })
  
})
