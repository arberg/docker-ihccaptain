CURRENT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
HOST_PORT=8100
HOST_SSLPORT=3100
NAME=ihccaptain_build

# sudo docker stop ihccaptain_build
# sudo docker rm ihccaptain_build
# # Fully automated install, but creates bash prompt at end, so container can be investigated
# sudo docker run -it -v "$CURRENT_DIR/host:/host" --name ihccaptain_build -p $HOST_PORT:80 -p $HOST_SSLPORT:443 ubuntu:18.04 bash -c "cd /host; . build_docker.sh; bash"

docker build -t ihccaptain:ihccaptain_1.14_1 .
