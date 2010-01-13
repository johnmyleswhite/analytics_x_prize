#!/usr/bin/Rscipt

source('library/target.R')
source('library/load_data.R')
source('library/utilities.R')

library('lme4')

model.fit <- lmer(Probability ~ (1 + Year | Zipcode), data = homicides)

predicted.homicides$Probability <- predict(model.fit, predicted.homicides)

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_6')
