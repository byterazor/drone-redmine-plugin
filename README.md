---
lang: EN_US
---

# drone-redmine

## Description

This repository contains a Containerfile for building a drone plugin to interact with the [Redmine](https://redmine.org) API.

### Alert

This is very early work and may and may not work for you yet.

### PLUGIN Variables

* `REDMINE_URL` - the URL to your redmine server (required)
* `REDMINE_TOKEN` - your Redmine API TOKEN (required)
* `PROJECT_ID` - the project id (required) to work on
* `UPLOAD_FILES` - ("true"|"false") - upload files from build (default: "false")
* `FILES` - space separated list of files to upload in the format PATH:REDMINE_FILENAME:DESCRIPTION:VERSION_ID (optional)

## Supported Architectures

- amd64
- arm64

## Updates

I am trying to update the image weekly as long as my private kubernetes cluster is available. So I do not promise anything and do **not** rely 
your business on this image.


## Source Repository

* https://gitea.federationhq.de/Container/drone-redmine-plugin

## Prebuild Images

* https://hub.docker.com/repository/docker/byterazor/drone-/general

## Authors

* **Dominik Meyer** - *Initial work* 

## License

This project is licensed under the MPLv2 License - see the [LICENSE](LICENSE) file for details.
