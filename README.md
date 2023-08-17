# Docker Development Setup

1. Install Docker ([macOS](https://docs.docker.com/docker-for-mac/install/)/[Windows](https://docs.docker.com/docker-for-windows/install/)/[Linux](https://docs.docker.com/engine/install/))
2. `.env` is populated with good defaults.
3. Install Dory: https://github.com/FreedomBen/dory
4. Configure dory: https://github.com/FreedomBen/dory#config-file
   Add the following to the config-file
```bash
- domain: test
  address: 127.0.0.1
```
5. Run dory:
```bash
dory up
```
6.  Build project and start up
``` bash
docker compose build
docker compose up
```
7. Visit http://oralhistory.test in your browser.
8. Load database and import data
```
docker compose exec web bundle exec rake db:migrate
docker compose exec web bundle exec rake db:seed
docker compose exec web bundle exec rake import[100]
```
9. Sign into the Admin Dashboard
Navigate to https://oralhistory.test/users/sign_in
Login with default the seeded user and password at db/seeds.rb
Note you can add those ENV variable to your .env file to update
the values in one place. But deafults are set so make sure you
update for produciton environment.

10. Common Developer Recipes:
Drop into a bash console inside docker container: `docker compose exec container-name bash`. Example: `docker compose exec web bash`
Drop into a sh console inside docker container: `docker compose exec container-name sh`. Example: `docker compose exec web sh`
Drop into a rails console: `docker compose exec bundle exec rails c`

**Note:** The `100` in `import[100]` limits the number of assets initially loaded. You may adjust this as desired.

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense.
**To avoid this** change `MAKE_WAVES` in your `.env` to false (or delete it).

---

# Automated Build and Deploy

## Testing/Staging

Any push to GitHub of a branch with "test" will build, tag with :test, publish to Docker Hub and push to testing.

Any push to GitHub of a branch other than master, main, or test will build, tag with :staging, publish to Docker Hub and push to staging.

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
