# Docker Development Setup

1) Install Docker ([macOS][DAM]/[Windows][DAW]/[Linux][DAL])

2) `.env` is populated with good defaults. `.env.development` and
`.env.production` can be used for local overrides and should not be in the
repo.

3) Confirm or configure git and docker settings.  Substitute your information
for the examples.
``` bash
git config --global user.name example
git config --global user.email example@example.com
docker login
```

4) Create and populate `.env.development`.
   Minimum requirements: `touch .env.development`

5) Build project and start up

``` bash
docker-compose --file docker-compose.yml build
docker-compose --file docker-compose.yml up
```

Then visit http://0.0.0.0:8000 in your browser. You may see a rails error page
suggesting a migration.

6) Load database and import data

```
docker-compose exec web bundle exec rake db:migrate import[100]
```

The `100` limits the number of assets initially loaded. You may adjust this as
desired. 

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense. Change MAKE_WAVES in your .env to false (or delete it).

# Deploy a new release

## Docker tags

There are three common tags in use for Oral History:
- `latest`: Tag Jenkins deploys to production
- `staging`: Tag Jenkins deploys to test
- `date`: (in ISO 8601 format) Allows forcible rollback to a previous version

## Building

To build and apply the Docker tags:

``` bash
docker build \
  -t uclalibrary/oral-history:staging \
  -t uclalibrary/oral-history:latest \
  -t uclalibrary/oral-history:"$(date +%Y.%m.%d)" \
  .
```

## Pushing to Dockerhub

Docker can only push one tag at a time. It is recommended to push all three
tags.

``` bash
for tag in staging latest "$(date +%Y.%m.%d)"; do
  docker push uclalibrary/oral-history:"$tag";
done
```

Deployment is handled by Jenkins.

# Manually deployment to test

In Jenkins, select `docker_swarm_deploy` job. Use `Build with Parameters`. Select `oralhistory_test` from the `TERRA_ENV` dropdown. Start the build.

# Production Notes:

Regarding docker-compose.production.yml: The delayed_job container is for scaling out processing of peaks for all of the audio files.
However, the web container always has one worker. Stopping the delayed_job container will not stop jobs from being run.

<!-- References -->

[DAM]: https://docs.docker.com/docker-for-mac/install/
[DAW]: https://docs.docker.com/docker-for-windows/install/
[DAL]: https://docs.docker.com/engine/install/
