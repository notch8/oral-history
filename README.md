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
sc be rake db:migrate import[100]
```

## Development Notes
When performing an import the system will attempt to download and process the audio files to create the peak files. This is very CPU & time intense. Change MAKE_WAVES in your .env to false (or delete it).

# Deploy to Staging

1. Visit [Rancher](https://rancher.notch8.com) (not R2, this is one of the few projects left on the original Rancher set up)

2. At the top left use the drop down menu to select `staging`

3. Expand the Oral Histories containers by pressing the `+` next to `oh`

4. Upgrade the web and worker containers - with the following steps:
- On the right hand side select the Upgrade button, a circle with an arrow pointing up
- The upgrade service will present a form and there is only one field that needs changed - Select Image
- The Select Image field will pull the most recently used image and it will look something like this: registry.gitlab.com/notch8/oral_history:ebbac127
- The letters and numbers after the colon are the commit SHA
- Use the commit SHA from the [most recent commit](https://gitlab.com/notch8/oral_history/-/commits/master/) into the main branch and replace the old commit with the most recent commit SHA
- Then press the Upgrade button at the bottom of the page and Rancher will redirect to the container's page
- Rancher will spin up a new container and when it is ready the circle with the arrow will turn into a checkmark with the help text of 'Finish Upgrade'
- Click 'Finish Upgrade' button and repeat process for worker container

## Production Notes:
Regarding docker-compose.production.yml: The delayed_job container is for scaling out processing of peaks for all of the audio files.
However, the web container always has one worker. Stopping the delayed_job container will not stop jobs from being run.
