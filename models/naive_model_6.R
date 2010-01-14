#!/usr/bin/Rscipt

source('library/load_config.R')
source('library/load_data.R')
source('library/utilities.R')

library('lme4')

model.fit <- lmer(Probability ~ (1 + Year | Zipcode), data = homicides)

for (i in 1:nrow(predicted.homicides))
{
  z <- predicted.homicides[i, 'Zipcode']
  y <- predicted.homicides[i, 'Year']
  
  main.intercept <- fixef(model.fit)
  zip.intercept <- ranef(model.fit)$Zipcode[which(zipcodes == z), 1]
  zip.slope <- ranef(model.fit)$Zipcode[which(zipcodes == z), 2]
  
  prediction <- main.intercept + zip.intercept + zip.slope * y
  predicted.homicides$Probability[predicted.homicides$Zipcode == z & predicted.homicides$Year == y] <- prediction
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_6')
