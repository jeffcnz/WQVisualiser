library(XML)
library(RCurl)

# Function to read a LAWA monitoring sites reference data WFS and return a dataframe
# Based on original scripts provided by Sean Hodges at Horizons Regional Council.

readMonitoringSitesWFS <- function(url){
  # Dealing with https:
  if(substr(url,start = 1,stop = 5)=="http:"){
    getSites.xml <- xmlInternalTreeParse(url)
  } else {
    tf <- getURL(url, ssl.verifypeer = FALSE)
    
    getSites.xml <- xmlParse(tf)
  }
  
  ds <- xmlToDataFrame(getNodeSet(getSites.xml, "//emar:MonitoringSiteReferenceData"))
  
  
  # Determining whether delimiter is a space or a comma and creating a vector  
  if(grepl(pattern = ",",x = as.character(ds$SHAPE))[1]==TRUE){
    #Comma
    latlon <- sapply(strsplit(as.character(ds$SHAPE),","),as.numeric)
  } else{
    #assume a space
    latlon <- sapply(strsplit(as.character(ds$SHAPE)," "),as.numeric)
  }
  
  
  # assigning lat and lon fields
  if(latlon[1,1]<0){
    ds$Lat <- latlon[1,]
    ds$Lon <- latlon[2,]    
  } else{
    ds$Lat <- latlon[2,]
    ds$Lon <- latlon[1,]
  }
  ds
}

censureHandler <- function(df) {
  censuredlt <- subset(df, substring(df$Value,1,1)=="<")
  if (length(censuredlt$Value) > 0) {
    censuredlt$valueprefix<-"<"
    censuredlt$result<-as.numeric(substring(censuredlt$Value,2,nchar(censuredlt$Value)))
    #censured$trendresult<-censured$result/2
  }
  
  censuredgt <- subset(df, substring(df$Value,1,1)==">")
  if (length(censuredgt$Value) > 0) {
    censuredgt$valueprefix<-">"
    censuredgt$result<-as.numeric(substring(censuredgt$Value,2,nchar(censuredgt$Value)))
    #censured$trendresult<-censured$result/2
  }
  
  nocensure <- subset(df, substring(df$Value,1,1)!="<" & substring(df$Value,1,1)!=">")
  if (length(nocensure$Value) > 0) {
    nocensure$valueprefix<-"="
    nocensure$result <- as.numeric(nocensure$Value)
    #nocensure$trendresult<-nocensure$result
  }
  output <- rbind(censuredlt, censuredgt, nocensure)
  output
}

