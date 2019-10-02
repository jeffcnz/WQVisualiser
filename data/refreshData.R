# The data for the shiny app is stored in a static R data file.
# Inside this file are 2 datasets
# A site list, which is the water quality sites in the WFS and
# Measurements for each site.
# This script provides a method of updating the data for the shiny app.

source("data/wqDataFunctions.R")

devtools::install_github("jeffcnz/hillr")
library("hillr")

allowedProjects <- c("415 01", 
                     "ECOHS", 
                     "MBWS", 
                     "312 704", 
                     "339 301")

# Read the WFS to create the site list.

wfs_MonitoringSites <- "https://hbmaps.hbrc.govt.nz/arcgis/services/emar/MonitoringSiteReferenceData/MapServer/WFSServer?request=GetFeature&service=WFS&typename=MonitoringSiteReferenceData&srsName=urn:ogc:def:crs:EPSG:6.9:4326&Version=1.1.0"

allSites <- readMonitoringSitesWFS(wfs_MonitoringSites)

swQualitySites <- subset(allSites, SWQuality == "Yes")

#save the sites data
save(swQualitySites, file="data/HbrcWqSites.RData")

# For each site read the data

siteList <- swQualitySites$CouncilSiteID

measurementList <- read.csv("data/WQMeasurements.csv", stringsAsFactors = FALSE)

data <- fullGetHilltopData(endpoint = "https://data.hbrc.govt.nz/Envirodata/EMAR.hts?",
                           sites = siteList,
                           measurements = measurementList$Measurements,
                           from = "1/1/2004",
                           to = "1/7/2019",
                           option = "None")

data <- merge(data, measurementList, by.x = 'Measurement', by.y = "Measurements")

# split value prefix and result to new columns
data <- censureHandler(data)
# Change column names
names(data) <- make.names(names(data), unique = TRUE)
# Filter projects
hbrcwqdata <- subset(data, Project.ID %in% allowedProjects)
# save as RData
save(hbrcwqdata, file="data/HbrcWqData.RData")
