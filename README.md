# Docker Development Setup

1. Install Docker ([macOS](https://docs.docker.com/docker-for-mac/install/)/[Windows](https://docs.docker.com/docker-for-windows/install/)/[Linux](https://docs.docker.com/engine/install/))
2. `.env` is populated with good defaults. `.env.development` and `.env.production` can be used for local overrides and should not be in the repo.
3. Confirm or configure Github and Dockerhub settings. (Substitute your information for the examples.)
    + Set up your Gitgub configuration if it is not already set up
``` bash
git config --global user.name example
git config --global user.email example@example.com
```
    + Login in to Dockerhub (you will need your username and password)
``` bash
docker login
```
4. Create and populate `.env.development`.
   Minimum requirements is that it exists. `touch .env.development`
5.  Build project and start up
``` bash
docker-compose --file docker-compose.yml build
docker-compose --file docker-compose.yml up
```
6. Visit http://0.0.0.0:8000 in your browser. *You may see a rails error page suggesting a migration.*
7. Load database and import data
```
docker-compose exec web bundle exec rake db:migrate import[100]
```
**Note:** The `100` in `import[100]` limits the number of assets initially loaded. You may adjust this as desired.

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense.  
**To avoid this** change `MAKE_WAVES` in your `.env` to false (or delete it).

---

# Automated Build and Deploy

## Testing/Staging

Any push to GitHub of a branch other than master or main will build, tag with :staging, publish to Docker Hub and push to testing.

## Production

Any push to GitHub of the master or main branch will build, tag with :lastest, and publish to Docker Hub. It is up to Apps team or DevSupport to push to production.

# Manually Deploy a new release

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

## Manual deployment to test

In Jenkins, select `docker_swarm_deploy` job. Use `Build with Parameters`. Select `oralhistory_test` from the `TERRA_ENV` dropdown. Start the build.

## Production Notes:

Regarding `docker-compose.production.yml`: The delayed_job container is for scaling out processing of peaks for all of the audio files.  
However, the web container always has one worker.  
Stopping the delayed_job container will not stop jobs from being run.
