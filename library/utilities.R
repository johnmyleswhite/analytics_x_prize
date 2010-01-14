write.data <- function(predicted.homicides, model.name)
{
  write.table(predicted.homicides,
              file = paste('predictions/', model.name, '_predictions.csv', sep = ''),
              sep = "\t",
              row.names = FALSE)
}

normalize.data <- function(predicted.homicides)
{
  predicted.homicides$Probability <- predicted.homicides$Probability / sum(predicted.homicides$Probability)
  return(predicted.homicides)
}

db.escape <- function(name)
{
  return(paste('`', name, '`', sep = ''))
}
