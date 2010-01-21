#!/usr/bin/env python
# encoding: utf-8
"""
EB_Feed_Parser.py

Script to download, parse crime data RSS feed
from EveryBlock.com, then export to CSV file.

Created by Drew Conway on 2010-01-12.
Copyright (c) 2010. All rights reserved.
"""

import sys
import os
import feedparser
from BeautifulSoup import BeautifulSoup
import csv
import sqlite3
from datetime import datetime


def parse_rss(zip_code):
# Uses feedparser to parse crime data
    url_base="http://philly.everyblock.com/rss/locations/zipcodes/"
    url_tail="/?ignore=announcements,business-reviews,city-press-releases,comments,rules,historical-images,local-deals,news-articles,photos,public-works,real-estate-listings,food-inspections,restaurant-inspections,school-reviews,streets-and-services"
    return feedparser.parse(url_base+str(zip_code)+url_tail) 

def parse_date(dispatch_date, dispatch_time):
    #create a string in the format "January 11, 2010 6:26 p.m." then remove 
    #periods which will be parsed by strptime format %B %e, %Y %I:%M %p
    #returns null if we couldn't parse the date
    
    crime_datetime = dispatch_date + ' ' + dispatch_time
    crime_datetime = crime_datetime.replace('.','')
    dateformat = "%B %d, %Y %I:%M %p"
    
    try:
        newdate = datetime.strptime(crime_datetime, dateformat)
    except:
        #correct what we can
        if crime_datetime.find('midnight'):
            crime_datetime = dispatch_date + ' 12:00 am'
        elif crime_datetime.find(':') == -1:
            #we're missing the minutes (this happens sometimes)
            dateformat = "%B %d, %Y %I %p"

        #and give it another go
        try:
            newdate = datetime.strptime(crime_datetime, dateformat)
        except:
            print "Could not import date " + crime_datetime + " for id " + data['id']
            newdate = null    

    return newdate

def is_violent(crime_type):
# Check if crime report is violent
    ct=crime_type.lower()
    if ct.find("assault")>-1 or ct.find("rape")>-1 or ct.find("homicide")>-1:
        return 1
    else:
        return 0

def main():
    # List of all Philadelphia zip codes
    zips=(19102,19103,19104,19106,19107,19111,19112,19114,19115,19116,19118,19119,19120,19121,19122,19123,19124,19125,19126,19127,19128,19129,19130,19131,19132,19133,19134,19135,19136,19137,19138,19139,19140,19141,19142,19143,19144,19145,19146,19147,19148,19149,19150,19151,19152,19153,19154)
    
    # Dictionary for data
    crime_data=dict()
    
    # Record keeping
    entry=0
    col_names=['id','crime_type','crime_desc','location','disp_time','date','zip','violent']
    
    # Collect data on all zips
    for z in zips:
        crime_entries=parse_rss(z)['entries']
        for crime in crime_entries:
        # Parse data and add to dict
            base_id=crime['id'].split('-')[-1]
            details=BeautifulSoup(crime['summary_detail']['value'])
            reports=details.findAll('li','newsitem crimegroup regrouped')
            report_count=0
            for r in reports:
                crime_data[entry]=dict.fromkeys(col_names)
                crime_data[entry]['id']=base_id
                # Get general crime type
                crime_type=r.find("strong","crimetype regrouper").contents[0]
                # Check if it is a violent crime
                violent=is_violent(crime_type)
                crime_data[entry]["violent"]=violent
                crime_data[entry]["crime_type"]=crime_type
                # Get detail on crime
                crime_data[entry]["crime_desc"]=r.find("a","url").contents[0]
                
                # use the last part of the everyblock detail URL as the ID
                # note that the URLs are currently in the format:
                # http://philly.everyblock.com/crime/by-date/2010/1/11/736222/
                # which means our ids will look like this: /2010/1/11/736222/
                crime_data[entry]['id']= r.find("a","url")['href'][43:]
                
                crime_data[entry]["location"]=r.find("span","location").contents[0]
                time_temp=r.find("p","info").contents[0].split(" ")
                crime_data[entry]["disp_time"]=time_temp[2]+" "+time_temp[3]
                crime_data[entry]["date"]=r.find("strong","crimedate").contents[0]
                crime_data[entry]["zip"]=str(z)
                #print "got id: " + crime_data[entry]['id'] + " which is " + crime_data[entry]["crime_type"]
 
                entry+=1
        
        print "Done parsing "+str(z)
    
    # Create CSV writer and export data
    filename="EB_test_pull.csv"
    writer=csv.DictWriter(open(filename,"w"),fieldnames=col_names)
    # Add header
    labels=dict.fromkeys(col_names)
    for k in labels.keys():
        labels[k]=k
    writer.writerow(labels)
    # Write data
    for data in crime_data.values():
        writer.writerow(data)
    print "Output writen to: "+filename
    
    
    #write out to the sqlitedb
    dbname="analyticsx.db"
    conn = sqlite3.connect(dbname)

    print "Beginning database operations to " + dbname
     
    c = conn.cursor()
    
    for data in crime_data.values():

        try:
            newdate = parse_date(data['date'], data['disp_time'])    
            c.execute("insert or replace into everyblock_crimes (id,crime_type,crime_desc,location,date,zip, is_violent) values (?,?,?,?,?,?,?)", 
                      (data['id'],
                      data['crime_type'],
                      data['crime_desc'],
                      data['location'],
                      newdate,
                      data['zip'],
                      is_violent(data['crime_type'])))
        except:
            print "Could not write id %s:%s, %s"% (data['id'], data['crime_desc'],data['location'])
    
    conn.commit()
    c.close()

    print "Completed database operations."
    
if __name__ == '__main__':
    main()

