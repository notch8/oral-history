#!/bin/bash
set -e
if [ -z $PASSENGER_APP_ENV ]
then
    export PASSENGER_APP_ENV=development
fi

rm -rf /home/app/webapp/.ruby*

VOLUMES=('/home/app/webapp/tmp/cache', '/home/app/webapp/public/assets', '/home/app/webapp/public/packs', '/home/app/webapp/public/system', '/home/app/webapp/node_modules')

for volume in "${VOLUMES[@]}"
do
  if [ -d "$volume" ]; then
      /bin/bash -l -c "chown -fR app:app $volume" # mounted volume may have wrong permissions
  fi
done

declare -p | grep -Ev 'BASHOPTS|PWD|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

if [[ $PASSENGER_APP_ENV == "development" ]] || [[ $PASSENGER_APP_ENV == "test" ]]
then
    /sbin/setuser app /bin/bash -l -c 'cd /home/app/webapp && yarn && bundle exec rails db:migrate db:seed db:test:prepare'
fi

if [[ $PASSENGER_APP_ENV == "production" ]] || [[ $PASSENGER_APP_ENV == "staging" ]]
then
    /sbin/setuser app /bin/bash -l -c 'cd /home/app/webapp && bundle exec rake db:migrate db:seed && bundle exec whenever --update-crontab'
fi

exec /usr/sbin/nginx
