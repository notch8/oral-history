# Docker development setup

1) Install Docker.app

2) Install SC
``` bash
gem install stack_car
```

3) We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

4) Confirm or configure settings.  Sub your information for the examples.
``` bash
git config --global user.name example
git config --global user.email example@example.com
docker login registry.gitlab.com
```

5) Build project and start up

``` bash
sc build
sc up
```

Then visit http://0.0.0.0:8000 in your browser.  You should see a rails error page suggesting a migration.

6) Load database and import data

``` bash
sc be rake db:migrate import
```

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense. Change MAKE_WAVES in your .env to false (or delete it).

# Deploy a new release

``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deployes those tags to the server
```

Releaese and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image

# Manually deploy to staging
In Rancher, run an Upgrade on the web and worker containers and make sure to update the branch name at the end of the strings in the "Select Image*" text box and in the TAG text box. (update with the new branch name that you would like to deploy)

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
