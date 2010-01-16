# First, we define a distance

distances <- as.data.frame(expand.grid(zipcodes, zipcodes))
names(distances) <- c('zipcode.a', 'zipcode.b')
distances$distance <- rep(NA, nrow(distances))

for (i in 1:nrow(distances))
{
  distances[i,'distance'] <- abs(as.numeric(as.character(distances[i,1])) - as.numeric(as.character(distances[i,2])))
}

distance.metric <- function(z1, z2)
{
  return(with(subset(distances, zipcode.a == z1 & zipcode.b == z2), distance))
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
    weight <- 1 / (1 + distance.metric(zipcode, as.numeric(as.character(z)))^a)
    weights <- c(weights, weight)
    weighted.sum <- weighted.sum + weight * p
  }
  
  prediction <- weighted.sum / sum(weights)
  predicted.homicides[i,'Probability'] <- prediction
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_7')
