---
title: Water Quality Visualiser
description: A Shiny R application for visualising summaries of water quality data.
---

## water-quality-visualiser

---
A Shiny R application for visualising water quality data.
The data is provided from csv files in order to make it generic and easy to configure.

Summaries of catchment water quality data can be viewed on a map, as boxplots, or in a table.  

## Features

## Usage

## Requirements
Initial datasets are provided with the package so that it will work.

It is designed to be easy to customise for other data without needing to edit R code.

In the data directory there are 4 csv files.  2 provide the data and 2 are configuration files.

### Data Files

These files provide the data for the app to show.

#### wqdata.csv

Provides the water quality data that is summarised by the app.


|  FieldName  |  Data Type  |  Comments  |
|------------------|---------------|-----------------------------------------------------|
| Measurement | string | The measurement name.  These will need to be mapped to standard or display measurement names in a separate csv. |
| Site | string | The site name (displayed on table and boxplot).  Must match the name in the sitedata.csv file. |
| DateTime | string, format dd/mm/yyyy hh:mm | The date and time of the sample, used for filtering. |
| Prefix | string | “<” or “=” this field is not currently used, so can be left blank if required. |
| Value | number | The numeric part of the result, ie without <, or >.  Can be a string, but must only be numeric. |
| Units | string | The measurement units, used to display on the plot axis and map pop-ups. |
| Method | string | The method used to derive the result. This field is not currently used so can be blank. |
| QualityCode | string | The quality code of the result. Not currently used so can be left blank.  If you only want to use good data then filter your data before generating the csv. |


#### sitedata.csv

Provides the site locations and associates each site with a catchment.

|  FieldName  |  Data Type  |  Comments  |
|------------------|---------------|-----------------------------------------------------|
| Site | string | The site name (displayed on table and boxplot).  Must match the name in the wqdata.csv file. |
| Catchment | string | The catchment that the site is in.  Used for setting the display options and data summaries. |
| Latitude | number | The latitude of the site (required for map display). |
| Longitude | number | The longitude of the site (required for map display). |


### Configuration Files

These files allow some customisation of the app.

#### WQMeasurements.csv

This file maps the measurement names to standard or display names.  It also sets the band dividers for the map display, along with the colour scheme and size of the dots.

|  FieldName  |  Data Type  |  Comments  |
|------------------|---------------|-----------------------------------------------------|
| Measurement | string | The measurement names from the wqdata file.  They must match exactly. |
| StdMeasurementName | string | A standard or display name for each measurements.  Allows measurements to be combined, eg pH (lab) and pH (field) could both have a StdMeasurementName of pH.  These are the names that will be displayed in the dropdown selection boxes. |
| RadiusFactor | number | A scaling factor for the map display markers. Helps determine the size of the marker.  Use a small number for data that has large numeric results (such as E Coli), and a larger number for results that are smaller. |
| BandMin | number | The lowest value expected for the measurement, often 0. |
| Band1 | number | The first banding boundary for the measurement. |
| Band2 | number | The second banding boundary for the measurement. |
| Band3 | number | The third banding boundary for the measurement. |
| Band4 | number | The fourth banding boundary for the measurement. |
| BandMax | number | The highest value expected for the measurement |
| Brewer_Pallette | string | The R Color Brewer pallette to use for the map.  [Details.](https://www.r-graph-gallery.com/38-rcolorbrewers-palettes.html) |


#### Config.csv

This file provides the configurations for some of the text and options.

|  FieldName  |  Data Type  |  Comments  |
|------------------|---------------|-----------------------------------------------------|
| Variable | string | The variable name.  Do not edit, if you do you may need to edit where it is used in the script in order to get the app to run. |
| Value | string | The display text, or default value that will display. |

The variables are:

- AppTitle - The title to display.
- DefaultCatchment - The default catchment to display for the options drop down list, the initial data that will show.
- DefaultMeasurement - The default measurement to display for the options drop down list, the initial data that will show.
- DefaultPlotOrder - The default plot order to display for the options drop down list, the initial plot order for the box plots.
- AboutText - The text to display on the about tab.
- DownloadText - The text to display on the downloads tab.

## Installation
Download and unpack the zip file and then run the Shiny Application

## Project Status

## Goals/Roadmap

## Getting Help or Reporting an Issue

## How to Contribute



## License

MIT

