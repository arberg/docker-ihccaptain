# docker-ihccaptain
Dockerfile for IHC Captain

See 
* https://hub.docker.com/r/arberg/ihccaptain/
* https://www.ihc-user.dk/forum/forums/topic/7151-ihc-captain-p%C3%A5-linux-milj%C3%B8docker/
* http://jemi.dk/ihc/
* Current version: http://jemi.dk/ihc/#changelog

## Running docker-ihccaptain

Note that it may be necessary to change the default port to an unused port on your host system. see run.sh

## How To build docker image again

* Manually update file VERSION
* run build.sh or just release.sh

## How To debug build-process if it fails

Probably its the install.sh that wil be failing. Download (install script)[http://jemi.dk/ihc/files/install] to host/custom_installer/installer.sh, and edit Dockerfile so it uses the downloaded version. See the ADD line. Now we can edit the build-script locally and run build.sh to build it.

Alternatively edit the Dockerfile so it stops at where it fails, and run the container with interactive bash. Search for `how to debug Dockerfile` to learn more, ie. https://www.joyfulbikeshedding.com/blog/2019-08-27-debugging-docker-builds.html
