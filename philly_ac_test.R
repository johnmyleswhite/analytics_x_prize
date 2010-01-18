# File-Name:       philly_ac_test.R                 
# Date:            2010-01-17                                
# Author:          Drew Conway                                       
# Purpose:         Test for spatial autocorrelation in Philly zips
# Data Used:       zipcodes.shp
# Packages Used:   spdep
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                             
library(spdep)

# Load shapefile of Philadelphia zips
prj<-CRS("+proj=utm +zone=30 +units=km")
shape.data<-readShapeSpatial("shape_files/phila_zipcodes_shp/zipcodes.shp", ID="ZIPCODE", proj4string = prj)
summary(shape.data)

# Load in homicide data
input.file <- paste('input_data/training_data.csv', sep = '')
homicides <- read.csv(input.file, header = TRUE, sep = '\t')
summary(homicides)

# Fucntion to combine homocide probabilities for each year to shape data
homicides.year<-function(year) {
    year.data<-subset(homicides,homicides$Year==year)
    row.names(year.data)<-as.character(year.data$Zipcode)
    shape.data<-spCbind(shape.data,year.data)
    shape.data$Year<-NULL
    shape.data$Zipcode<-NULL
    return(shape.data)
}

# List of shape data frames with homicide data by year
homicide.shapes<-lapply(c(2007:2009),homicides.year)

# Test for spatial correlation in all years
nb<-poly2nb(shape.data)
