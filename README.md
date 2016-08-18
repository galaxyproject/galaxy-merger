# Galaxy Merger

Creates issues and/or PRs to ensure Galaxy is merged forward.

## Instructions for Jenkins

(Could also be setup with cron.)

* Create an ssh key for galaxybot and add it to Github.
* Create a free-style project targetting the github repository of this project.
* Run the job every 15 minutes(?) in addition to on-updates to this repository.
* The job should just run merge_all.bash in project root.
* Once it works once, change the job to set UPSTREAM_GITHUB_ACCOUNT=galaxyproject merge_all.bash, wipe the workspace, and rerun.
