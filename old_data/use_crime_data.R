crimes <- read.csv('crime_data.csv', header = TRUE, sep = '\t')
crimes$Timestamp <- as.POSIXct(strptime(crimes$Timestamp, '%m/%d/%Y %I:%M:%S %p'))

valid.zipcodes <- c(19102, 19103, 19104, 19106, 19107, 19111, 19112, 19114,
                    19115, 19116, 19118, 19119, 19120, 19121, 19122, 19123,
                    19124, 19125, 19126, 19127, 19128, 19129, 19130, 19131,
                    19132, 19133, 19134, 19135, 19136, 19137, 19138, 19139,
                    19140, 19141, 19142, 19143, 19144, 19145, 19146, 19147,
                    19148, 19149, 19150, 19151, 19152, 19153, 19154)

crimes <- subset(crimes, Zipcode %in% valid.zipcodes)

years <- c(2007, 2008, 2009)

crimes.by.year <- list()
crimes.by.year[[2007]] <- subset(crimes, Timestamp >= as.POSIXct('2007-01-01') & Timestamp < as.POSIXct('2008-01-01'))
crimes.by.year[[2008]] <- subset(crimes, Timestamp >= as.POSIXct('2008-01-01') & Timestamp < as.POSIXct('2009-01-01'))
crimes.by.year[[2009]] <- subset(crimes, Timestamp >= as.POSIXct('2009-01-01') & Timestamp < as.POSIXct('2010-01-01'))

probabilities <- as.data.frame(expand.grid(Zipcode = valid.zipcodes, Year = years))
probabilities$Probability <- rep(NA, nrow(probabilities))

for (y in years)
{
  for (z in valid.zipcodes)
  {
    p <- nrow(subset(crimes.by.year[[y]], Zipcode == z)) / nrow(crimes.by.year[[y]])
    probabilities$Probability[probabilities$Year == y & probabilities$Zipcode == z] <- p
  }
}

# Sanity checks
with(subset(probabilities, Year == 2007), sum(Probability))
with(subset(probabilities, Year == 2008), sum(Probability))
with(subset(probabilities, Year == 2009), sum(Probability))

probabilities$Zipcode <- as.factor(probabilities$Zipcode)

for (y in years)
{
  write.table(subset(probabilities, Year <= y),
              file = paste(y, '_data.csv', sep = ''),
              sep = "\t",
              row.names = FALSE)
}
