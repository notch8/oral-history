#!/bin/bash

# Ensure log directory exists and is writable
mkdir -p /home/app/webapp/log
chown app:app /home/app/webapp/log

# Run the delayed job worker and log output in a writable location
exec /sbin/setuser app /bin/bash -l -c 'cd /home/app/webapp && ./bin/delayed_job run >> /home/app/webapp/log/worker.log 2>&1'
