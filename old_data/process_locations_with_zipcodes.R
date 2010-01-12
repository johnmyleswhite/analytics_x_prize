zipcodes <- read.csv('locations_with_zipcodes.csv', header = TRUE, sep = '\t')
crimes <- read.csv('pooled_crimes.csv', header = TRUE, sep = ',')

# Sanity check to see that no location has multiple zipcodes.
for (l in with(zipcodes, Location))
{
  if (length(with(subset(zipcodes, Location == l), unique(Zipcode))) > 1)
  {
    print(l)
  }
}

locations <- c()
dates <- c()
zips <- c()

for (i in 1:nrow(crimes))
{
  crime.location <- as.character(crimes[i,'LOCATION'])
  crime.date <- as.character(crimes[i,'DISPATCH_DATE_TIME'])
	crime.zip <- with(subset(zipcodes, Location == crime.location), unique(Zipcode))
	if (! is.na(crime.zip))
	{
	  locations <- c(locations, crime.location)
	  dates <- c(dates, crime.date)
	  zips <- c(zips, crime.zip)
	}
	else
	{
	  print(paste('Problem with ', crime.location, sep = ''))
	}
}

clean.crimes <- data.frame(Location = locations, Timestamp = dates, Zipcode = zips)

write.table(clean.crimes,
            file = paste('crime_data.csv', sep = ''),
            sep = "\t",
            row.names = FALSE)

