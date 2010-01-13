#! /bin/sh
# Pre-processes an CSV so it works with mysqlite import
# Changes the commas in a given field to semi-colons (close enough, right?) 
# and then yanks all the double quotes and the header.  
#
# Usage: scrub_csv infile outfile
#  
# Once you run this, you should be clear to run the sqlite command .import <file> <tablename>

gawk -F\" -v OFS=\" -- "{ for(i=2;i<=NF;i+=2){gsub(\",\",\";\",\$i) }; print }" $1 | sed 's/"//g' | sed '1d' > $2


