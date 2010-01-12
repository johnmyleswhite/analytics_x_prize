header = "DC_KEY,UCR,UCR_TEXT,LOCATION,DISPATCH_DATE_TIME,DC_DIST,SECTOR,PREMISE_TEXT,X_COORD,Y_COORD"
data_rows = []

files = Dir.glob('*.csv')

files.each do |file|
  lines = File.open(file) {|f| f.readlines()}
  lines.shift
  lines.each do |line|
    data_rows << line.chomp
  end
end

output_file = File.new('../pooled_crimes.csv', 'w')
output_file.puts header
output_file.puts data_rows.join("\n")
output_file.close()
