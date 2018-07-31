# Docker development setup

1) Install Docker.app

2) gem install stack_car

3) We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

4) sc up

``` bash
gem install stack_car
sc up

```

5) Load database and import data

``` bash
sc be rake db:migrate import[100]
```

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense. Change MAKE_WAVES in your .env to false (or delete it).

# Deploy a new release

``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deployes those tags to the server
```

Releaese and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image


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
