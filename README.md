# drone-redmine

## Description

This is a [Drone CI](https://www.drone.io/) plugin to interact with a [Redmine](https://redmine.org).

At the moment the following tasks are supported:

- updating branch build status information 
- updating branch build artifacts
- updating release stati
- updating release artifacts
- creating projects together with one issue category per repository
- ensuring that a release version exists in redmine and closing it
- updating issues referenced in commit messages

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
* `ACTION` - which action to perform (updateBranchStatus, updateReleaseStatus, updateBranchArtifacts, updateReleaseArtifacts, createProject, createVersion, updateIssues)

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

#### createProject

Creates the project if it does not exist yet and ensures that one issue category per repository exists in it. The action is idempotent, so it can run on every pipeline.

* `PROJECT_ID` - the identifier of the redmine project to create (required)
* `PROJECT_NAME` - the name of the project (optional, defaults to the project identifier)
* `CATEGORY` - the issue category to create in the project (optional, defaults to DRONE_REPO_NAME; set it to an empty value to skip category creation)
* `PROJECT_PARENT` - the numeric id of the parent project (optional, only applied when the project is actually created)
* `PROJECT_PUBLIC` - make the project public instead of private (optional; any value except `false`/`0` enables it, only applied when the project is actually created)

#### createVersion

Ensures that the given version exists in the project and closes it. Meant to run on tag pushes, so the release version exists in redmine when the release pipeline finishes.

* `PROJECT_ID` - the project id of the redmine project (required)
* `RELEASE` - the version to create and close (optional, defaults to DRONE_TAG)

#### updateIssues

Parses the commit messages of the current build for issue references and updates the referenced redmine issues. Keywords are case-insensitive and need a blank or a colon before the `#` (e.g. `fixes #123`, `closes: #456`); one keyword can reference several issues (`fixes #1, #2`).

* `close`, `closes`, `closed`, `closing` set the issue status to `Closed`
* `fix`, `fixes`, `fixed`, `fixing` set the issue status to `Fixed`
* all other reference keywords (`ref`, `refs`, `references`, `relates`, ...) only add a note

Every update adds a note in the form `commit <short-sha> <subject> (<link to commit>)`. If an issue is referenced by multiple commits, the strongest keyword wins (close > fix > ref). A single failing issue does not abort the run; the action fails at the end if any issue could not be updated.

* `PROJECT_ID` - the project id of the redmine project (required)
* the commit range is derived automatically: on tag builds all commits since the previous tag, otherwise the commits between DRONE_COMMIT_BEFORE and DRONE_COMMIT (or just DRONE_COMMIT)

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
