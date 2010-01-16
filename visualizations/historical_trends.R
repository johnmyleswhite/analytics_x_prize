source('library/boot.R')

mean.homicides <- sapply(zipcodes, function (z) {with(subset(homicides, Zipcode == z), mean(Probability))})
 
threshold <- 0.05

most.dangerous.zipcodes <- zipcodes[which(mean.homicides > threshold)]

worst.homicides <- subset(homicides, Zipcode %in% most.dangerous.zipcodes)

worst.homicides$Zipcode <- as.factor(as.character(worst.homicides$Zipcode))

jpeg('visualizations/Homicide Trends in Philly\'s Most Dangerous Zipcodes.jpg')
print(qplot(Year, Probability,
            data = worst.homicides,
            color = Zipcode,
            geom = 'line',
            main = 'Homicide Trends by Zipcode'))
dev.off()

