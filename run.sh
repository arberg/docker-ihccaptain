CURRENT_DIR="$( cd "$(dirname "$0")" ; pwd -P )" 
HOST_PORT=8100
HOST_SSLPORT=9100
DOCKER_NAME=ihccaptain

sudo docker stop $DOCKER_NAME
sudo docker rm $DOCKER_NAME
sudo docker run -d --name $DOCKER_NAME -p $HOST_PORT:80 -p $HOST_SSLPORT:443 -v $CURRENT_DIR/data:/opt/ihccaptain/data/ -v $CURRENT_DIR/host:/host/ ihccaptain

