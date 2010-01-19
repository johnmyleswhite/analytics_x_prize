# File-Name:       naive_model_8.R                 
# Date:            2010-01-19                                
# Author:          Drew Conway                                       
# Purpose:         Use a SAR model specification to predict 
# Data Used:       homicides
# Packages Used:   spdep
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
library(spdep)

# Load shapefile of Philadelphia zips
prj<-CRS("+proj=utm +zone=30 +units=km")
shape.data<-readShapeSpatial("shape_files/phila_zipcodes_shp/zipcodes.shp", ID="ZIPCODE", proj4string = prj)

# Load homicide data from previous year
homicide.2009<-subset(master.datasets[["homicides"]],master.datasets[["homicides"]]$datetime>=2009)

# Create new data frame that matches raw homicide counts to zip codes
raw.homicides<-cbind(sapply(levels(homicides$Zipcode),function(x) nrow(subset(homicide.2009,homicide.2009$zip==x))))
colnames(raw.homicides)<-"Homicides"
raw.data<-as.data.frame(raw.homicides)

# Add homicide data to shape data
shape.data<-spCbind(shape.data,raw.data)

# Get spatial weights among zip codes
phi.nb<-tri2nb(coordinates(shape.data),row.names=row.names(shape.data)) # Create neighbor object
phi.lw<-nb2listw(phi.nb,style="B")    # Create list of weights

# NOTE: Row standardized and globally standardized weightings were
# tested, but a simple binary distance weighting performed the
# best for predicted probability RMSE

# Create a lagged-SAR using spatial weights. and predict homicides
lag.sar<-lagsarlm(Homicides ~ NULL, shape.data,phi.lw)
lag.pred<-predict.sarlm(lag.sar)
pred.data<-cbind(lag.pred[names(lag.pred)])

# NOTE: because there are no ind vars all model types return same
# predicted values, so I only specify a lagged-SAR

# Build Predictions
predicted.homicides<-cbind(as.character(shape.data$ZIPCODE),as.numeric(2009),as.numeric(pred.data/sum(pred.data)))
colnames(predicted.homicides)<-c("Zipcode","Year","Probability")
rownames(predicted.homicides)<-1:length(shape.data$ZIPCODE)

# Output the data
write.data(predicted.homicides, 'naive_model_8')



