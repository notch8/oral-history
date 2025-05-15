#!/bin/bash

# Ensure log directory exists and is writable
mkdir -p /home/app/webapp/log
chown app:app /home/app/webapp/log

# Run delayed_job properly
cd /home/app/webapp
exec /sbin/setuser app bundle exec rake jobs:work RAILS_ENV=development >> /home/app/webapp/log/worker.log 2>&1
