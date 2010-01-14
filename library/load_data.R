#!/usr/bin/Rscipt

input.file <- paste('input_data/training_data.csv', sep = '')

homicides <- read.csv(input.file, header = TRUE, sep = '\t')
homicides$Zipcode <- as.factor(homicides$Zipcode)
homicides <- subset(homicides, Year < target[['target']])

zipcodes <- with(homicides, unique(Zipcode))

db.driver <- dbDriver('SQLite')
connection <- dbConnect(db.driver, dbname = 'sqlite/analyticsx.db')

max.n <- 100000

master.datasets <- list()

for (table.name in datasets[['tables']])
{
  sql <- paste('SELECT * FROM ', db.escape(table.name), sep = '')
  
  result.set <- dbSendQuery(connection,  sql)
  
  df <- fetch(result.set, n = max.n)
  
  master.datasets[[table.name]] <- df
  
  dbClearResult(result.set)
}

predicted.homicides <- data.frame(Zipcode = zipcodes)
predicted.homicides$Year <- rep(target[['target']], nrow(predicted.homicides))
predicted.homicides$Probability <- rep(NA, nrow(predicted.homicides))
