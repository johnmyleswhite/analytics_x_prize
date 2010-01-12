require 'CGI'
require 'open-uri'

def get_google_result(search_text)
  url = 'http://www.google.com/search?q=' + CGI::escape(search_text)
  connection = open(url)
  return connection.read()
end

locations = File.open('locations.csv', 'r') {|f| f.readlines()}

locations.each do |location|
  location_text = location[1,location.length - 3]
  if location_text.match(/ BLOCK /)
    location_text.sub!(/ BLOCK /, ' ')
  end
  search_text = location_text + ' ' + 'Philadelphia'
  result = get_google_result(search_text)
  #result.match(/(\d{5})/)
  #result.match(/(\d{5}).*<cite>maps\.google\.com<\/cite/)
  result.match(/(\d{5})<\/b><\/a><\/h3><br><cite>maps\.google\.com<\/cite/)
  zipcode = $1
  puts "#{location.chomp}\t#{zipcode}"
  sleep(5)
end
