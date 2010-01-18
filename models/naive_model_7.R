# First, we define a distance metric.
library(spdep)

# Load shapefile of Philadelphia zips
prj<-CRS("+proj=utm +zone=30 +units=km")
shape.data<-readShapeSpatial("shape_files/phila_zipcodes_shp/zipcodes.shp", ID="ZIPCODE", proj4string = prj)

phi.nb<-tri2nb(coordinates(shape.data),row.names=row.names(shape.data)) # Create neighbor object
phi.lw<-nb2listw(phi.nb)    # Create list of weights

#distances <- as.data.frame(expand.grid(zipcodes, zipcodes))
#names(distances) <- c('zipcode.a', 'zipcode.b')
#distances$distance <- rep(NA, nrow(distances))

#for (i in 1:nrow(distances))
#{
#  distances[i,'distance'] <- abs(as.numeric(as.character(distances[i,1])) - as.numeric(as.character(distances[i,2])))
#}

distance.metric <- function(z1, z2)
{
  z1.index <- which(zipcodes == z1)
  z2.index <- which(zipcodes == z2)
  w.index <- which(phi.lw$neighbours[[z1.index]] == z2.index)
  if (length(w.index) > 0)
  {
    distance <- phi.lw$weights[[z1.index]][w.index]
  }
  else
  {
    distance <- 0
  }
  return(distance)
}

for (i in 1:nrow(predicted.homicides))
{
  zipcode <- as.numeric(as.character(predicted.homicides[i,'Zipcode']))
  weights <- c()
  weighted.sum <- 0.0
  a <- 1
  
  for (z in zipcodes)
  {
    p <- with(subset(homicides, Zipcode == z & Year == target[['target']] - 1), Probability)
    weight <- distance.metric(zipcode, as.numeric(as.character(z)))
    #weight <- 1 / (1 + distance.metric(zipcode, as.numeric(as.character(z)))^a)
    weights <- c(weights, weight)
    weighted.sum <- weighted.sum + weight * p
  }
  
  prediction <- weighted.sum / sum(weights)
  predicted.homicides[i,'Probability'] <- prediction
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_7')
