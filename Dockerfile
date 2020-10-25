FROM ubuntu:18.04
RUN apt-get update && apt-get install -y cron
# for php-7 in ubuntu 18.04.1 LTS
RUN apt-get update && apt-get install -y software-properties-common
RUN	apt-add-repository -y ppa:ondrej/php

COPY VERSION .
COPY host/.bash_aliases /root
# Current version of installer is broken for docker
#ADD http://jemi.dk/ihc/files/install /tmp/install
ADD host/custom_installer/installer.sh /tmp/install
RUN chmod 755 /tmp/install
RUN ["/bin/bash", "-c", "/tmp/install docker"]
# Backup the generated serverconfig.json so we can later mount image with host-mounted /data folder and copy this file into it
RUN cp -R /opt/ihccaptain/data /opt/ihccaptain/dataOrg

COPY host/run_ihc_captain_in_docker.sh /app/
RUN chmod 755 /app/run_ihc_captain_in_docker.sh

# Clean up APT when done. Don't delete /tmp/install as we use it to backup installer afterwards during build-process
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/*

EXPOSE 80
# SSL not installed inside IHC captain docker config
#EXPOSE 443

CMD /app/run_ihc_captain_in_docker.sh
