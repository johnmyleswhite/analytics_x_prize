#!/bin/sh
cd ~/workspace/analytics_x_prize/sqlite
git pull
python EB_Feed_Parser.py > eb_feed_parser.log
python axp_utils.py -g -n 5000 > axp_util_cron.log
git commit analyticsx.db philapd.db eb_feed_parser.log EB_test_pull.csv -m "Automated everyblock and philapd update."
git push


