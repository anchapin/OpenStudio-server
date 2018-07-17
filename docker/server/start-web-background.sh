#!/usr/bin/env bash

echo "Waiting for Mongo to start"
/usr/local/bin/wait-for-it --strict db:27017

echo "Waiting for Redis to start"
/usr/local/bin/wait-for-it --strict queue:6379

cd /opt/openstudio/server && bundle exec rake environment resque:work
