#!/usr/bin/env ruby

require 'rubygems'
require 'active_record'
require 'yaml'

dbconfig = YAML::load_file('../config/database.yml')

ActiveRecord::Base.establish_connection(dbconfig)

require 'models/everyblock_crime'
require 'models/homicide'
require 'models/pooled_crime'
