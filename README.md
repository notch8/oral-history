# Docker development setup

1) Install Docker.app

2) We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

3) Confirm or configure settings.  Sub your information for the examples.
``` bash
git config --global user.name example
git config --global user.email example@example.com
docker login
```
4) Create and populate `.env.development`

5) Build project and start up

``` bash
docker-compose --file docker-compose.yml build
docker-compose --file docker-compose.yml up
```

Then visit http://0.0.0.0:8000 in your browser.  You should see a rails error page suggesting a migration.

6) Load database and import data

``` bash
docker-compose exec web bundle exec rake db:migrate import[100]
```

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense. Change MAKE_WAVES in your .env to false (or delete it).

# Deploy a new release

``` bash
docker build -t uclalibrary/oral-history:staging -t uclalibrary/oral-history:latest -t uclalibrary/oral-history:$(date +%Y.%m.%d) .
docker push uclalibrary/oral-history:staging uclalibrary/oral-history:latest uclalibrary/oral-history:$(date +%Y.%m.%d)
```

Deployment is handled by Jenkins.

# Manually deploy to staging
In Jenkins, select `docker_swarm_deploy` job. Use `Build with Parameters`. Select `oralhistory_test` from the `TERRA_ENV` dropdown. Start the build.

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Production Notes:
Regarding docker-compose.production.yml: The delayed_job container is for scaling out processing of peaks for all of the audio files.
However, the web container always has one worker. Stopping the delayed_job container will not stop jobs from being run.
