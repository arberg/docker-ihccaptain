#!/bin/bash

# Prepare host data volume with initial data for first startup
[ ! -f /opt/ihccaptain/data/serverconfig.json ] && cp /opt/ihccaptain/dataOrg/serverconfig.json /opt/ihccaptain/data

# https://docs.docker.com/config/containers/multi-service_container/

SERVICE1=php7.3-fpm
SERVICE2=nginx
SLEEP=2

function startService() {
  service $1 start
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start $1: $status"
    exit $status
  fi
}

startService $SERVICE1
startService $SERVICE2

trap "service $SERVICE1 stop; service $SERVICE2 stop; echo trapped multi >> /var/log/tmplog; exit" TERM

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep $SLEEP; do
  # ps aux |grep $SERVICE1 |grep -q -v grep
  # PROCESS_1_STATUS=$?
  # ps aux |grep $SERVICE2 |grep -q -v grep
  # PROCESS_2_STATUS=$?

  service $SERVICE1 status > /dev/null
  SERVICE_1_STATUS=$?
  service $SERVICE2 status > /dev/null
  SERVICE_2_STATUS=$?

  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $SERVICE_1_STATUS -ne 0  -o $SERVICE_2_STATUS -ne 0 ]; then
    echo "$SERVICE1: service status: $SERVICE_1_STATUS"
    echo "$SERVICE2: service status: $SERVICE_2_STATUS"
    echo "One of the processes has already exited."
    exit 1
  # else
  #     service $SERVICE1 status
  #     service $SERVICE2 status
  #     echo OK
  fi
done