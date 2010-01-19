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

# Load in homicide data
input.file <- paste('input_data/training_data.csv', sep = '')
homicides <- read.csv(input.file, header = TRUE, sep = '\t')

# Fucntion to combine homocide probabilities for each year to shape data
homicides.year<-function(year) {
    year.data<-subset(homicides,homicides$Year==year)
    row.names(year.data)<-as.character(year.data$Zipcode)
    shape.data<-spCbind(shape.data,year.data)
    shape.data$Zipcode<-NULL
    return(shape.data)
}

# List of shape data frames with homicide data by year
homicide.shapes<-lapply(c(2007:2009),homicides.year)

# Get spatial weights among zip codes
phi.nb<-tri2nb(coordinates(shape.data),row.names=row.names(shape.data)) # Create neighbor object
phi.lw<-nb2listw(phi.nb,style="B")    # Create list of weights

# Test for spatial correlation of homicide probability with Moran's I and Geary's C
MN<-lapply(1:3,function(x) moran.test(homicide.shapes[[x]]$Probability, listw=phi.lw, randomisation=FALSE))
MR<-lapply(1:3,function(x) moran.test(homicide.shapes[[x]]$Probability, listw=phi.lw, randomisation=TRUE))
GN<-lapply(1:3,function(x) geary.test(homicide.shapes[[x]]$Probability, listw=phi.lw, randomisation=FALSE))
GR<-lapply(1:3,function(x) geary.test(homicide.shapes[[x]]$Probability, listw=phi.lw, randomisation=TRUE))
corr.stats<-list(MoranN=MN,MoranR=MR,GearyN=GN,GearyR=GR)

# Report Stats
stat.report<-function(s) {
    stat.obj<-corr.stats[[s]]
    est<-lapply(1:3,function(x) cbind(stat.obj[[x]]$estimate))
    est<-cbind(est[[1]],est[[2]],est[[3]])
    colnames(est) <- c(2007:2009)
    rownames(est) <- paste(s,c("statistic","expectation","variance"),sep=".")
    return (est)
}

stat.mat<-lapply(c("MoranN","MoranR","GearyN","GearyR"), stat.report)
print(stat.mat)

# Note: For Moran's I the stat is \in[-1,1], where I>0 is  positive spatial
# autocorrelation, and for Geary's C the stat is \in[0,2], where C<1 means 
# positive autocorrelation.
#
# The above tests; therefore, confirm positive spatial autocorrelation for 
# the probability of homicide among all zip codes.  Also, though not 
# reported, all tests are statistically significant at the 99% level.

png("phi_dep.png")
plot(shape.data,border="grey20")
plot(phi.lw,coordinates(shape.data),add=TRUE,col="red")
dev.off()