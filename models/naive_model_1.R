#!/usr/bin/Rscipt

last.year <- with(homicides, max(Year))

for (i in 1:nrow(predicted.homicides))
{
  zipcode <- predicted.homicides[i,'Zipcode']
  data.subset <- subset(homicides, Zipcode == zipcode & Year == last.year)
  predicted.homicides[i,'Probability'] <- with(data.subset, Probability)
}

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_1')
