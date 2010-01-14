#!/usr/bin/Rscipt

model.fit <- lm(Probability ~ Year + Zipcode, data = homicides)

predicted.homicides$Probability <- predict(model.fit, predicted.homicides)

predicted.homicides <- normalize.data(predicted.homicides)

write.data(predicted.homicides, 'naive_model_4')
