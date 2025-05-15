# Docker Development Setup

- Install Docker ([macOS](https://docs.docker.com/docker-for-mac/install/)/[Windows](https://docs.docker.com/docker-for-windows/install/)/[Linux](https://docs.docker.com/engine/install/))

- Copy `.env` to `.env.development`
- Run `docker compose up --build`

## Special Linux instructions

If you are running Linux, some additional steps are required to set up a suitable host environment,
due to the current implementation in `Dockerfile` and `docker-compose.yml`.

1. A local user/group on your (host) machine must match the `app` user, with uid/gid 9999.
2. Set the proper permissions inside the `web` container.

This worked, in a Debian (via WSL2) host environment:
```
# Become root, or run each of the following via sudo
sudo bash

# Step 1, from above
# The group and user can be called anything on the host; this uses oh_public for both
# Create a group with gid 9999, to match the web container's app user
groupadd -g 9999 oh_public

# Create a user with uid 9999, also matching web's app user
# Also create home directory, and set bash shell since we're not animals
useradd oh_public -u 9999 -g 9999 -d /home/oh_public -m -s /bin/bash -c "For testing OH public build"

# Add the user to the docker group, assuming you have one,
# since running docker as root on the host is bad
usermod -a -G docker oh_public

# Step 2, from above
# Since the web image is built as root, and some things run in it as root,
# the first run can create some directories inside /home/app/webapp as root
# instead of as the app user.  This means the app user... can't write to them.

# Start the application and monitor logs.  If you see repeated messages like this:

web_1       | /usr/local/rvm/gems/ruby-2.7.7/gems/bootsnap-1.4.9/lib/bootsnap/compile_cache.rb:29:in `permission_error': bootsnap doesn't have permission to write cache entries in '/home/app/webapp/tmp/cache/bootsnap-compile-cache' (or, less likely, doesn't have permission to read '/usr/local/rvm/gems/ruby-2.7.7/gems/railties-6.1.7.3/lib/rails/commands.rb') (Bootsnap::CompileCache::PermissionError)

# Run the following as root.  This only needs to be done once,
# after the initial startup (or if you remove the whole application and start over)
cd /home/oh_public/oral-history # or wherever on the host this application is
chown -R oh_public:oh_public .
```

Load database and import some sample data using the following commands

```
docker compose exec web bundle exec rake db:migrate
docker compose exec web bundle exec rake db:seed
docker compose exec web bundle exec rake full_import[100]
```

If you get an error on the final line, and are using the `zsh` shell, you will need to escape the square brackets.

```
docker compose exec web bundle exec rake full_import\[100\]
```

**Note:** The `100` in `full_import[100]` limits the number of assets initially loaded. You may adjust this as desired.

At this point you should be able to access the application at [http://127.0.0.1:8000/](http://127.0.0.1:8000/)

Sign into the Admin Dashboard

- Navigate to [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin)

The default development username and password are:

- `admin@example.com`
- `testing123`

## Common Developer Recipes:

Drop into a bash console inside docker container:

- `docker compose exec container-name bash`
- Example: `docker compose exec web bash`

Drop into a sh console inside docker container:

- `docker compose exec container-name sh`
- Example: `docker compose exec web sh`

Drop into a rails console:

- `docker compose exec bundle exec rails c`

Drop into a postgresql console:

- `docker compose exec postgres psql --username=postgres`

# Build and Deploy Process

Optional: Contact DevSupport for Argo account for log access

### Application Only Changes

- Create a branch and make changes to the application code.

- Submit a pull and review request. On [**submission** of a pull request](https://github.com/UCLALibrary/oral-history/blob/main/.github/workflows/build-dockerhub.yml), a container image is built and pushed to Docker Hub. Update the pull request and incorporate any change requests required from the review. Any new commits or changes to the pull request will trigger a new container image to be created and pushed to Docker Hub.

- Navigate to [Docker Hub](https://hub.docker.com/repository/docker/uclalibrary/oral-history) (login required) and note the image tag, which is the first 8 characters of the hash.

- In the appropriate `charts/[environment]-oralhistory-values.yaml` file, update the `image: tag` value to the tag copied from Docker Hub in the previous step. This should be the final commit before merging the pull request.

- Update the pull request to reflect the final commit added for the new image created.
  Because a pull request will be updated, another container image build will be triggered -- using this process, the deployed image is always at least one "behind" the most recently submitted pull request.

On merging and pushing this change to `main`, the new `image: tag` value will trigger a new deployment. This process is automatic when updating `[stage,test]-oralhistory-values.yaml`.

For production, `prod-oralhistory-values.yaml` should be updated and DevSupport notified, and is not automatically deployed.

### Chart Changes

If there are changes to files under `templates/`, extra steps are required to propagate the chart changes.

- The `version` field must be incremented in `charts/Chart.yaml`
- Submit a pull request to the [gitops_kubernetes](https://github.com/UCLALibrary/gitops_kubernetes) repository.
- The pull request should increment the `sources : targetRevision` value under the appropriate environment section in the `apps\apps-team-prod-environment-values.yaml` file.
