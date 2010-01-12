crimes <- read.csv('pooled_crimes.csv', header = TRUE, sep = ',')
locations <- crimes$LOCATION
write.table(locations, file = 'locations.csv', row.names = FALSE)
