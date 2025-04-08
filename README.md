# drone-redmine

## Description

This is a [Drone CI](https://www.drone.io/) plugin to interact with a [Redmine](https://redmine.org).

At the moment the following tasks are supported:

- updating branch build status information 
- updating branch build artifacts
- updating release stati
- updating release artifacts

In the future more tasks are planned.

### Requirements
    - redmine
    - drone
    - the project within redmine needs to have wiki activated as it creates wiki pages

### Working

This plugin will parse you build data and create wiki pages in the project of your wiki.

releases -> release_name -> artifacts_...

branches -> branch_name -> artifacts...


### Alert

This is very early work and may and may not work for you yet.

### Settings Variables

* `REDMINE_URL` - the URL to your redmine server (required)
* `REDMINE_TOKEN` - your Redmine API TOKEN (required) best provided by a secret
* `PROJECT_ID` - the project id of the redmine project (required)
* `ACTION` - which action to perform (updateBranchStatus, updateReleaseStatus, updateBranchArtifacts, updateReleaseArtifacts)

#### updateBranchStatus

* `BRANCH`- the branch name to use. best taken from DRONE_BRANCH (keep in mind DRONE_BRANCH is not available in all DRONE_EVENTS)
* `BUILD_STATUS` - the build status of the build. Can also be taken from DRONE_BUILD_STATUS, or by yourself manually

#### updateReleaseStatus

* `RELEASE` - the release to use (can be taken from DRONE_TAG)

#### updateBranchArtifacts

* `BRANCH`- the branch name to use. best taken from DRONE_BRANCH (keep in mind DRONE_BRANCH is not available in all DRONE_EVENTS)
* `ARTIFACT_GROUP` - artifacts are organized into groups, just select one suitable for you
* `ARTIFACTS` - space separated list of artifacts (**at the moment no special characters or spaces are supported**)

#### updateReleaseArtifacts

* `RELEASE` - the release to use (can be taken from DRONE_TAG)
* `ARTIFACT_GROUP` - artifacts are organized into groups, just select one suitable for you
* `ARTIFACTS` - space separated list of artifacts (**at the moment no special characters or spaces are supported**)

## Supported Architectures
- amd64
- arm64

## Updates

I am trying to update the image weekly as long as my private Kubernetes cluster is available. So I do not promise anything and do **not** rely 
your business on this image.


## Source Repository

* https://gitea.federationhq.de/Container/drone-redmine-plugin

## Project Homepage

* https://rm.byterazor.de/projects/drone-redmine-plugin

## Prebuild Images

* https://hub.docker.com/repository/docker/byterazor/drone-redmine/general

## Authors

* **Dominik Meyer** - *Initial work* 

## License

This project is licensed under the MPLv2 License - see the [LICENSE](LICENSE) file for details.
