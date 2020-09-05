#!/usr/bin/env bash

# Configure XVFB
Xvfb :10 -ac &
export DISPLAY=:10

# Arbitrary sleep to wait for other containers and xvfb to start if this was the first
for i in {1..10}
do
  echo "Waiting so other processes can start"
  sleep 1s
done

echo "Waiting for Mongo to start"
/usr/local/bin/wait-for-it --strict -t 0 db:27017

echo "Waiting for Redis to start"
/usr/local/bin/wait-for-it --strict -t 0 queue:6379

# Always create new indexes in case the models have changed
cd /opt/openstudio/server && bundle exec rake db:mongoid:create_indexes

# The memfix-controller seems to have causes some issues with NRCan, need to revisit.
# https://github.com/NREL/OpenStudio-server/issues/348
#ruby /usr/local/lib/memfix-controller.rb start

# AP hack for now to ensure both resque and nginx/rails are running on web.
# Note that this will only run the analysis background queue as it is set in the docker-compose env file.
bundle exec rake environment resque:work &

/opt/nginx/sbin/nginx &

# Always create new indexes in case the models have changed
cd /opt/openstudio/server && bundle exec rspec --tag algo; (( exit_status = exit_status || $? ))
cd /opt/openstudio/server && bundle exec rake rubocop:run; (( exit_status = exit_status || $? ))

exit $exit_status
