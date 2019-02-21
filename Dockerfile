FROM ubuntu:18.04
COPY VERSION .
COPY host/.bash_aliases /root
COPY host/install_ubuntu.sh /tmp
COPY host/run_ihc_captain_in_docker.sh /app/
RUN chmod 755 /app/run_ihc_captain_in_docker.sh

# whiptail for IHC Captain install script, in case its executed interactively
RUN apt-get update && apt-get install -y \
	whiptail \
	cron
#RUN useradd pi

# for php-7 in ubuntu 18.04.1 LTS
RUN apt-get update && apt-get install -y software-properties-common
RUN	apt-add-repository -y ppa:ondrej/php

RUN chmod 755 /tmp/*.sh
RUN ["/bin/bash", "-c", "/tmp/install_ubuntu.sh docker"]
# Backup the generated serverconfig.json so we can later mount image with host-mounted /data folder and copy this file into it
RUN cp -R /opt/ihccaptain/data /opt/ihccaptain/dataOrg

EXPOSE 80
EXPOSE 443

CMD /app/run_ihc_captain_in_docker.sh
