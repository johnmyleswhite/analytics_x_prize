#!/bin/sh
cd ~/workspace/analytics_x_prize/sqlite
git pull
python EB_Feed_Parser.py > eb_feed_parser.log
git commit analyticsx.db eb_feed_parser.log EB_test_pull.csv -m "Automated everyblock update."
git push


