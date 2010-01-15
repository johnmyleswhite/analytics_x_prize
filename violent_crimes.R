everyblock.crimes <- master.datasets[['everyblock_crimes']]

violent.crime.probabilities <- data.frame(Zipcode = as.factor(zipcodes))
violent.crime.probabilities$Year <- rep(2010, nrow(violent.crime.probabilities))
violent.crime.probabilities$Probability <- rep(NA, nrow(violent.crime.probabilities))

for (z in zipcodes)
{
	violent.crime.probabilities$Probability[violent.crime.probabilities$Zipcode == z] <- nrow(subset(everyblock.crimes, is_violent == 1 & zip == z)) / nrow(subset(everyblock.crimes, is_violent == 1))
}

write.table(violent.crime.probabilities, file = 'violent_crimes.csv', row.names = FALSE)
