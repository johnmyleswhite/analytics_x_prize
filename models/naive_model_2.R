#!/usr/bin/Rscipt

source('library/target.R')
source('library/load_data.R')
source('library/utilities.R')

for (i in 1:nrow(predicted.homicides))
{
  zipcode <- predicted.homicides[i,'Zipcode']
  data.subset <- subset(homicides, Zipcode == zipcode)
  weights <- 1 / (target[['target']] - data.subset$Year)
  prediction <- sum(weights * data.subset$Probability) / sum(weights)
  predicted.homicides[i,'Probability'] <- prediction
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_2')
