library('yaml')

target <- yaml.load_file('config/target.yml')
models <- yaml.load_file('config/models.yml')
db.configuration <- yaml.load_file('config/database.yml')
