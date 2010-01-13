models <- 1:5

performance <- data.frame(Model = models)
performance$RMSE <- rep(NA, nrow(performance))

for (m in models)
{
  model <- paste('naive_model_', models[m], sep = '')
  input.file <- paste('predictions/', model, '_predictions.csv', sep = '')
  predicted.homicides <- read.csv(input.file, header = TRUE, sep = '\t')
  true.homicides <- read.csv('true_data/test_data.csv', header = TRUE, sep = '\t')
  
  target.year <- with(predicted.homicides, max(Year))
  
  predicted.values <- subset(predicted.homicides, Year == target.year)
  true.values <- subset(true.homicides, Year == target.year)
  
  if (nrow(predicted.values) != nrow(true.values))
  {
    stop('Faulty predictions: row lengths don\'t match.')
  }
  
  squared.errors <- rep(NA, length(zipcodes))
  
  for (i in 1:length(zipcodes))
  {
    z <- zipcodes[i]
    predicted.value <- with(subset(predicted.values, Zipcode == z), Probability)
    true.value <- with(subset(true.values, Zipcode == z), Probability)
    squared.errors[i] <- (predicted.value - true.value) ^ 2
  }
  
  rmse <- sqrt(mean(squared.errors))
  performance$RMSE[m] <- rmse
}

write.table(performance,
            file = 'rmse.csv',
            sep = '\t',
            row.names = FALSE)
