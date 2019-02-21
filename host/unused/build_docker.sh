apt-get update
apt-get install -y whiptail
apt-get install -y cron

# for php-7 in ubuntu 18.04.1 LTS 
apt-get install -y software-properties-common
apt-add-repository -y ppa:ondrej/php

cd /host
chmod 755 *.sh
./install_ubuntu.sh docker
cp -R /opt/ihccaptain/data /opt/ihccaptain/dataOrg

cp .bash_aliases /root
cp multiple_process_wrapper.sh /bin
cp run_ihc_captain_in_docker.sh /bin
chmod 755 /bin/multiple_process_wrapper.sh 
chmod 755 /bin/run_ihc_captain_in_docker.sh
