# docker-ihccaptain
Dockerfile for IHC Captain

See 
* https://hub.docker.com/r/arberg/ihccaptain/
* https://www.ihc-user.dk/forum/forums/topic/7151-ihc-captain-p%C3%A5-linux-milj%C3%B8docker/
* http://jemi.dk/ihc/
* Current version: http://jemi.dk/ihc/#changelog

## Running docker-ihccaptain

Copy `.env.example` to `.env`, adjust the persistent Unraid paths and ports if
needed, then start the stack with `docker compose up -d`. The legacy `run.sh`
and `run_released.sh` entry points remain as compatibility wrappers around
Docker Compose.

The default WebUI is published on port 8100 and the secure port on 9100. The
stack preserves the existing data directories below
`/mnt/user/appdata/ihccaptain/`.

## How To build docker image again

* Manually update file VERSION
* run build.sh or just release.sh
* or `./build.sh; ./run.sh` to build at run the build

## How To debug build-process if it fails

Probably its the install.sh that wil be failing. Download (install script)[http://jemi.dk/ihc/files/install] to host/custom_installer/installer.sh, and edit Dockerfile so it uses the downloaded version. See the ADD line. Now we can edit the build-script locally and run build.sh to build it.

If IHC-captain fails to start, use `run_debug.sh <optional image>` to stop the
main service and open Bash in the Compose debug service.

Alternatively edit the Dockerfile so it stops at where it fails, and run the container with interactive bash. Search for `how to debug Dockerfile` to learn more, ie. https://www.joyfulbikeshedding.com/blog/2019-08-27-debugging-docker-builds.html
