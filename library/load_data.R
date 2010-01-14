#!/usr/bin/Rscipt

input.file <- paste('input_data/training_data.csv', sep = '')
homicides <- read.csv(input.file, header = TRUE, sep = '\t')
homicides$Zipcode <- as.factor(homicides$Zipcode)
homicides <- subset(homicides, Year < target[['target']])

zipcodes <- with(homicides, unique(Zipcode))

predicted.homicides <- data.frame(Zipcode = zipcodes)
predicted.homicides$Year <- rep(target[['target']], nrow(predicted.homicides))
predicted.homicides$Probability <- rep(NA, nrow(predicted.homicides))
