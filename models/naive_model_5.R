#!/usr/bin/Rscipt

model.fit <- lm(Probability ~ Zipcode + Zipcode:Year, data = homicides)

predicted.homicides$Probability <- predict(model.fit, predicted.homicides)

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_5')
