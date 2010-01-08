location.data <- read.csv('locations_with_zipcodes.csv', header = TRUE, sep = '\t')

subset(location.data, is.na(Zipcode))

zipcodes <- with(location.data, as.factor(unique(Zipcode)))

for (z in sort(zipcodes))
{
  print(paste(z, nrow(subset(location.data, Zipcode == z)) / nrow(subset(location.data, !is.na(Zipcode)))))
}
