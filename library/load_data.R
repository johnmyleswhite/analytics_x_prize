#!/usr/bin/Rscipt

input.file <- paste('input_data/', target.year - 1, '_data.csv', sep = '')
homicides <- read.csv(input.file, header = TRUE, sep = '\t')
homicides$Zipcode <- as.factor(homicides$Zipcode)

zipcodes <- with(homicides, unique(Zipcode))

predicted.homicides <- data.frame(Zipcode = zipcodes)
predicted.homicides$Year <- rep(target.year, nrow(predicted.homicides))
predicted.homicides$Probability <- rep(NA, nrow(predicted.homicides))
