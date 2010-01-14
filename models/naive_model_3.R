#!/usr/bin/Rscipt

source('library/target.R')
source('library/load_data.R')
source('library/utilities.R')

for (i in 1:nrow(predicted.homicides))
{
  zipcode <- predicted.homicides[i,'Zipcode']
  data.subset <- subset(homicides, Zipcode == zipcode)
  model.fit <- lm(Probability ~ Year, data = data.subset)
  prediction <- coef(model.fit)[1] + coef(model.fit)[2] * target[['target']]
  predicted.homicides[i,'Probability'] <- prediction
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_3')
