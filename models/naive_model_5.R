#!/usr/bin/Rscipt

source('library/target.R')
source('library/load_data.R')
source('library/utilities.R')

model.fit <- lm(Probability ~ Zipcode + Zipcode:Year, data = homicides)

predicted.homicides$Probability <- predict(model.fit, predicted.homicides)

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_5')