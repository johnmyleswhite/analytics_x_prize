"""
Utillities of use for the AnalyticsX project
Originally created by Steven R. Mocarski
2010-01-20
"""
import sys
import getopt
import urllib2, urllib
import logging
import xml.parsers.expat
import logging.config
import csv
import sqlite3
import time

from datetime import date
from datetime import timedelta
from datetime import datetime
from optparse import OptionParser
from BeautifulSoup import BeautifulSoup

logging.config.fileConfig("axp_py_logging.conf")
class GeoData:
    """
    The GeoData class was written to improve the geocoding of
    Philadelphia crime data for the NYC AnalyticsX project.
    
    The primary usage is:
     
    x = GetData("248 Race Street", "Philadelphia", "PA")
    
    or:
    
    x = GetData()
    x.geocode_address("248 Race Street", "Philadelphia", "PA")
    
    the results of the geocoding are placed in a dict called 
    geoinfo, which looks like this:
    
    x.geoinfo = {
        City = Philadelphia   
        Zip = 19106                #the simple zipcode result returned
        Country = US            
        PlusFour = 1917            #the +4 part of zip+4
        results = 1                #how many results were returned.  if this isnt 1, you have a problem
        Longitude = -75.144200     #longitude of the resulting address
        precision = address        #should be "address" or the data might not be accurate
        State = PA
        Latitude = 39.953827       #latitude of the resulting address
    }
    
    You can experiment a bit by running the command interactively.  
    
        python axp_utils.py --address "248 Race Street"
        
    """
    address = None
    geoinfo = dict()
    retries = 5  #the number of times we're allowed to hit the yahoo api 
    xml = None
    parser = None
    _geocodeparser_activetag = None
    
    def __init__(self, street_address=None, city=None, state=None, retries = None):
        """
        If we pass the constructor the default values, assume we 
        want to geocode immediately.
        """
        if retries:
            self.retries = retries
            
        if street_address is not None:
            if city is None:
                city = "Philadelphia"
            if state is None:
                state = "PA"
            
            self.geocode_address(street_address, city, state)
        
            
        
    def geocode_address(self, street_address, city=None, state=None):
        """
        Uses the Yahoo local api to get ZIP+4 and long/lat
        REST service is in the format
        http://local.yahooapis.com/MapsService/V1/geocode?appid=YD-9G7bey8_JXxQP6rxl.fBFGgCdNjoDMACQA--&street=6700 Block Trinity St&city=Philadelphia&state=PA
    
        Since this is for the Philadelphia based analiticsx project,
        we assume Philadelphia, PA unless told otherwise.
        
        street_address is the address string
        city is a string specifying the city
        state is the US state 2 letter code
        """
        try:
            street_address = "".join(street_address)
        except:
            pass
        #validate the parameters
        if state is None:
            state = "PA"
        elif state.__len__() != 2:
            return False
    
        if city is None:
            city = "Philadelphia"
        
        #reset member variables, we dont want lingering zip/long/lat values    
        self.address = street_address
        self.longitude = None
        self.latitude = None
        self.zip = None
        self.plus_four = None
        self.xml = None
        self.geoinfo.clear()
        
        url = "http://local.yahooapis.com/MapsService/V1/geocode?appid=YD-9G7bey8_JXxQP6rxl.fBFGgCdNjoDMACQA--&"
        geoparams = {'street' : street_address,
            'city' : city,
            'state' : state }
        url = url + urllib.urlencode(geoparams)    
        self.geoinfo.clear()
        
        #if we havent reached our limit yet
        if self.retries > 0:
            try:
                #print "opening " + url
                self.retries = self.retries - 1
                self.xml = urllib2.urlopen(url).read()
            except urllib2.HTTPError, e:
                print "HTTP error: %d.  Probably too busy, so going to wait a bit and retry." % e.code
                time.sleep(2)
                return self.geocode_address(street_address, city, state)
            
            except urllib2.URLError, e:
                print "Network error: %s" % e.reason.args[1]
                return False
        
            #TODO: Add some error checking here to parse result tag
            self.parser = xml.parsers.expat.ParserCreate()
            self.parser.StartElementHandler = self.geocode_start_handler
            self.parser.EndElementHandler = self.geocode_end_handler
            self.parser.CharacterDataHandler = self.geocode_char_handler
            
            self.parser.Parse(self.xml)
        
        #Make sure we have the stuff we expect
        if "Zip" not in self.geoinfo:
            self.geoinfo['Zip'] = None
        if "PlusFour" not in self.geoinfo:
            self.geoinfo['PlusFour'] = None
        if "Latitude" not in self.geoinfo:
            self.geoinfo['Latitude'] = None
        if "Longitude" not in self.geoinfo:
            self.geoinfo['Longitude'] = None
        if "results" not in self.geoinfo:
            self.geoinfo['results'] = 0
        if "precision" not in self.geoinfo:
            self.geoinfo['precision'] = None
        if "Country" not in self.geoinfo:
            self.geoinfo['Country'] = None
        if "City" not in self.geoinfo:
            self.geoinfo['City'] = None
        if "State" not in self.geoinfo:
            self.geoinfo['State'] = None

        
        if self.geoinfo['results'] == 1 and self.geoinfo['precision'] == "address":
            return True
        elif street_address.find("BLOCK") != -1:
            #edit the address and try again
            street_address = street_address.replace("BLOCK","")
            print "street address is now: " + street_address
            return self.geocode_address(street_address, city, state)
        elif self.retries <= 0:
            return False  #fail silently, we expect this to happen a lot
        else:
            print "retries is %d"%self.retries
            logging.warn("Returned %d results for address %s when 1 expected."%(self.geoinfo['results'],self.address))
            return False
        
        
    def geocode_start_handler(self, name, attrs):
        self._geocodeparser_activetag = name
        if name == "Result":
            if "results" not in self.geoinfo:
                self.geoinfo['results'] = 1
                for a, v in attrs.items():
                    self.geoinfo[a] = v
                #if self.geoinfo['precision'] != "address":
                #    logging.warn("Address failure for address [%s].  Using precision %s."%(self.address,self.geoinfo['precision']))
            else:
                for a, v in attrs.items():
                    self.geoinfo[a] = v
                self.geoinfo['results'] = self.geoinfo['results'] + 1

    def geocode_char_handler(self, data):
        tag = self._geocodeparser_activetag
        if tag in ("Longitude", "Latitude", "Zip", "City", "State", "Country"):
            self.geoinfo[tag] = data
        if tag == "Zip":
            self.geoinfo['Zip'] = data[:5] 

            try:
                (zip, plusfour) = data.split("-")
                self.geoinfo['PlusFour'] = plusfour
            except:
                self.geoinfo['PlusFour'] = ""
                
    def geocode_end_handler(self, name):    
        pass


class PhilaCrimeParser:
    url = None
    dbname="analyticsx.db"
    conn = None
    geocoder = GeoData()
    
    #crime types is a dictionary that contains the Philadelphia 
    #police department classification, the ID, and whether or not
    #it is considered a violent crime.
    crime_types = {
        'Homicides' : ("10", True),                                                                                                                                                                                                                                          
        'Criminal Homicide' : ("11", True),
        'Justifiable Homicide' : ("12", True),                                                                                                                                                                                                                             
        'Manslaughter Gross Negligence' : ("13", True),
        'Rapes' : ("20", True),                                                                                                                                                                                                                            
        'Robberies' : ("30", True),                                                                                                                                                                                                                                         
        'Robberies w/ Gun' : ("31", True),                                                                                                                                                                                                                                               
        'Robberies no Gun' : ("32", True),                                                                                                                                                                                                                                        
        'Agg Assaults' : ("40", True),                                                                                                                                                                                                                           
        'Agg Assault w/ Gun' : ("41", True),                                                                                                                                                                                                                                            
        'Agg Assault No Gun' : ("42", True),                                                                                                                                                                                                                                     
        'Burglaries' : ("50", False),                                                                                                                                                                                                                         
        'Residential Burglaries' : ("51", False),                                                                                                                                                                                                                                         
        'Residentail Burglaries - Day' : ("52", False),                                                                                                                                                                                                                                  
        'Residential Burglaries - Night' : ("53", False),                                                                                                                                                                                                                            
        'Commercial Burglaries' : ("54", False),                                                                                                                                                                                                                                       
        'Thefts' : ("60", False),
        'Theft from Auto' : ("61", False),                                                                                                                                                                                                                                            
        'Theft Other' : ("62", False),                                                                                                                                                                                                         
        'Purse Snatchings' : ("63", True),                                                                                                                                                                                                                              
        'Pick Pockets' : ("64", False),                                                                                                                                                                                                                               
        'Bicycle Thefts' : ("65", False),                                                                                                                                                                                                                             
        'Retail Theft' : ("66", True),                                                                                                                                                                                                                           
        'Vehicle Stickers/Tags' : ("67",False),                                                                                                                                                                                                                                
        'Stolen/Recovered Vehicles' : ("70", False),                                                                                                                                                                                                                     
        'Stolen Vehicles' : ("71", False),                                                                                                                                                                                                                              
        'Recovered Vehicles' : ("72", False)                                                                                                                                                                                                                                        
    }
    to_date = None 
    from_date = None
    
    def get_ppd_url(self, start, end, crime_id):
        url = "http://citymaps.phila.gov/CrimeMap/ExportCSV.aspx?crimetype=" 
        url = url + crime_id + "&to=" + end.strftime("%m/%d/%Y") + "&from=" 
        url = url + start.strftime("%m/%d/%Y") + "&bounds=2616935.5%2C211682%2C2801795.5%2C289682"
        return url

    def import_crime_data_string(self, start, end, crime_type = None):
        return self.import_crime_data(datetime.strptime(start, "%m/%d/%Y"),datetime.strptime(end, "%m/%d/%Y"),crime_type)
    
    def import_crime_data(self, start, end, crime_type = None):
        delta = end - start
        
        #break up the date range into 30 day chunks
        if delta > timedelta(30):
            temp_start = start
            temp_end = start 
            temp_end = temp_start + timedelta(days = 29)
            while temp_end < end:
                self.import_crime_data(temp_start, temp_end, crime_type)
                temp_start = temp_end
                temp_end = temp_start + timedelta(days = 29)
            if end - temp_start > timedelta(0):
                self.import_crime_data(temp_start, end, crime_type)
            return True
        
        #loop through all the crime types as appropriate
        if crime_type is None:
            for crime_name, (crime_type, is_violent) in self.crime_types.items():
                self.import_crime_data(start, end, crime_name)
        else:
            (crime_id, is_violent) = self.crime_types[crime_type]
            if is_violent:
                violent = "violent"
            else:
                violent = "non-violent"
            print "Importing %s crime data %s:%s from %s to %s"%(violent, crime_id, crime_type, start, end)
            #do the real work
            self.process_crime_url(crime_id, crime_type, is_violent, start, end)
        return True
    
    def process_crime_url(self, crime_id, crime_type, is_violent, start, end):
        """
        Pull the data from the site
        """
        
        filename = "phillydata.csv"
        url = self.get_ppd_url(start, end, crime_id)
        f = urllib.urlretrieve(url, filename)
        self.import_csv_data(filename, crime_type, is_violent)
    
    def open_db(self, dbname = None):
        if dbname is not None:
            self.dbname = dbname
            
        self.conn = sqlite3.connect(self.dbname)

    print "Beginning database operations to " + dbname

    def import_csv_data(self, filename, crime_type = None, is_violent = None):
        f= csv.DictReader(open(filename, "rb"))
        #print "opening " + filename

        c = self.conn.cursor()
        loc_cursor = self.conn.cursor()

        try:
            while True:
                data = f.next()
                sqlstart = "insert or replace into philapd_crimes (is_violent"
                sqlend = " values ("
                if is_violent == True:
                    sqlend = sqlend + "1"
                elif is_violent == False:
                    sqlend = sqlend + "0"
                else:
                    sqlend = sqlend + "null"
                sqlgeo = ""
                sqlgeoend = ""
                geotuple = ()
                valuetuple = ()
                
                for a, b in data.items():
                    if a == "LOCATION":
                        try:
                            loc_cursor.execute("insert into location_info (location) values (?)",(b,))
                        except:
                            pass #we expect this to fail anytime there is a dup
                        
                    sqlstart = sqlstart + "," + a 
                    sqlend = sqlend + ",?"
                    
                    if a.find("DATE") != -1:
                        valuetuple = valuetuple + (datetime.strptime(b,"%m/%d/%Y %I:%M:%S %p"),)
                    else:
                        valuetuple = valuetuple + (b,) 
                
                sqlstart = sqlstart + sqlgeo + ")" + sqlend + sqlgeoend + ")"
                #print sqlstart
                #print valuetuple
                #run the query
               # try:
                c.execute(sqlstart, valuetuple + geotuple)
             #   except:
              #      print "Could not write %s, %s."%valuetuple[:2]
            
        except StopIteration:
            pass
        c.close()
        loc_cursor.close()
        self.conn.commit()
        
    
    def geocode_and_import(self):
        #loop through the location values without info
        c = self.conn.cursor()
        c.execute("select location from location_info where zip is null limit %d"%self.geocoder.retries)
        emptylist = c.fetchall()
        for loc in emptylist:
            #fix them
            #lets geocode this mofo
            self.geocoder.geocode_address(loc)
            
            geotuple = (self.geocoder.geoinfo['Latitude'],
                                    self.geocoder.geoinfo['Longitude'],
                                    self.geocoder.geoinfo['precision'],
                                    self.geocoder.geoinfo['Zip'],
                                    self.geocoder.geoinfo['PlusFour'],) + loc
            sql = "update location_info set lat = '%s', long = '%s', precision = '%s', zip = '%s', plusfour = '%s' where location = '%s'"%geotuple
            c.execute(sql)
            print sql
            print geotuple
            sql = "update philapd_crimes set lat = '%s', long = '%s', address_precision = '%s', zip = '%s', plus_four = '%s' where location = '%s'"%geotuple
            c.execute(sql)
        self.conn.commit()
        c.close()

    
    def __init__(self, start = None, end = None):
        self.open_db()

        if start:
            self.import_crime_data_string(start, end)

    
def main(argv=None):
    usage = "usage: %prog -h for help"
    did_something = False
    
    parser = OptionParser(usage)
    parser.add_option("-a", "--address", dest="address",
                      help="return geocoded data for a given address")
    parser.add_option("-x", "--xml",
                      action="store_true", dest="xml", help="include raw XML")
    parser.add_option("-s", "--startdate", dest="start_date",
                      help="starting date in format M/D/YYYY")
    parser.add_option("-e", "--enddate", dest="end_date",
                      help="end date in format M/D/YYYY")
 
    parser.add_option("-p", "--policedata", action="store_true", dest="police_data", 
                      help="pull crime data from the Philadelphia police department website")
    
    parser.add_option("-i", "--policeimport", dest="police_filename", 
                      help = "import or reimport the file given by police_filename")
    parser.add_option("-g", "--geocode",
                      action="store_true", dest="geocode", help="Geocode empty locations")
    
    (options, args) = parser.parse_args()
    
    if options.address:
        did_something = True
        print "using address %s"%options.address
        t = GeoData(options.address)
        
        if options.xml:
            print BeautifulSoup(t.xml).prettify()
                    
        for a, b in t.geoinfo.items():
            print "%s = %s"%(a, b) 

    if options.police_filename:
        did_something = True
        t = PhilaCrimeParser()
        t.import_csv_data(options.police_filename)
    if options.police_data:
        did_something = True
        t = PhilaCrimeParser(options.start_date, options.end_date)

    if options.geocode:
        did_something = True
        t = PhilaCrimeParser()
        t.geocode_and_import()
        print "finished geocoding"
        
    if did_something == False:
        print parser.get_usage()
        
if __name__ == "__main__":
    sys.exit(main())

        
        
        
        
        
        
        
