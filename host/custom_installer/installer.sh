#!/bin/bash
#
# IHC CAPTAIN INSTALLER - V1.16: Fixed problems with hardcoded php versions when running update/changes on old versions
#
######################################################################################
# Setup variables
######################################################################################
TEMP_DIR=/tmp

#running a custom install not
CUSTOM_INSTALL=false
# automatic try and detect docker - can be forced by launching with docker as a argument
INSIDE_DOCKER=false
# run IHC Captain has this user
USERNAME=pi
# quick lookup are we a raspberry pi or not - actually it checks the os for rasbian
IS_A_PI=false

# destionation dir
DEST_DIR=/opt/ihccaptain

#device info (file does not exist on all unix distros)
DEVICEMODEL=$([[ -f /proc/device-tree/model ]] && (cat /proc/device-tree/model | tr '\0' '\n') || true)


#download file for IHC Captain
DLURL=http://jemi.dk/ihc/files/

# What to download
DLFILE=ihccaptain$DLFILEFIX.tar.gz
if [ "$1" == "test" ] || [ "$2" == "test" ]; then
	DLFILE=ihccaptain-new.tar.gz
fi

# used for adding and removing stuff
CHECKMARK="ihccaptainadded"

# Add to cron info
CRONCMD="find /mnt/ram/ihccaptain/logins/ -type f -mtime +2 -delete 2>&1"
CRONJOB="0 * * * * $CRONCMD"

# colors for prompts
RTXT="\e[0;31m"
GTXT="\e[0;32m"
LGTXT="\e[1;32m"
#no color
BTXT="\e[0m"
#bold white
WTXT="\e[1;37m"

#Skip APT-get install
INSTALLAPT=true

#Global error feedback
GERROR=false

# nginx webserver settings
WEBPORT=80
SSLPORT=443
SSLINSTALL=true
WEBINSTALL=true
LETSENC=false
DNSNAME=false
EXTRASSL=/etc/ssl/certs/dhparam.pem

SSLCERT1=/etc/ssl/certs/ssl-cert-snakeoil.pem
SSLCERT2=/etc/ssl/private/ssl-cert-snakeoil.key
CERTFILE=/etc/ssl/snakeoil.pem

#INSIDE DOCKER then we dont ask a lot of questions
if [[ -f /.dockerenv ]] || grep -Eq '(lxc|docker)' /proc/1/cgroup || [[ $@ == *"docker"* ]]; then
	echo "IHC Captain custom installer for Docker..."
	INSIDE_DOCKER=true;
	USERNAME=root

	# Wrapper functions for automatic installs
	function whiptail {
		INPUTSTR="$@"
		if ( grep --quiet "msgbox" <<< "$INPUTSTR" ); then
			TITLE=$(sed 's/.*--title \(.*\) --.*/\1/' <<< "$INPUTSTR")
			MSG=$(sed 's/.*--msgbox \(.*\)/\1/' <<< "$INPUTSTR")
			echo
			echo "[$TITLE]"
			echo "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
			echo $MSG | sed 's/\\n/\n/g'
			echo
			echo "-------------------------------------------------------------------------"
			echo
		else
			echo "#########################################################################"
			echo "### ERROR: $*"
			echo "#########################################################################"
		fi
	}
	function clear {
		# avoid printing error 'Term'
		echo
		echo
		echo
	}
	function tput {
		# avoid error
		echo
	}
fi

#CUSTOM INSTALL OPTIONS if requested or running inside docker from the above
if [ "$1" == "custominstall" ]  || $INSIDE_DOCKER ; then
	CUSTOM_INSTALL=true

	#INSIDE DOCKER then we dont ask a lot of questions
	if ! $INSIDE_DOCKER ; then
		clear
		echo "IHC Captain custom installer..."
		echo "Tast det brugernavn du vil have ihccaptain til at køre under og tryk enter"
		read USERNAME
	fi

	# strip bad chars to improve input
	USERNAME=$(echo "$USERNAME" | tr -dc '[:alnum:]\n\r')

	# validate username
	if [ -z $USERNAME ]; then
		echo "Blank username is bad... bye!"
		exit 0;
	fi
fi

# find homedir for the user and check it okay
HOMEDIR=$(awk -F: -v v="$USERNAME" '{if ($1==v) print $6}' /etc/passwd)
if [ ! -d "${HOMEDIR}" ] ;  then
	echo Fatal error - homedir not found or unable to check for user \"$USERNAME\"
	exit 0
fi

######################################################################################
#Version check for OS etc
######################################################################################
SILENTUPDATE=false
if [ "$1" == "webupdate" ]; then
	SILENTUPDATE=true
fi
DIST_NAME="Ukendt"
DIST_VERSION=0
if [[ -r /etc/os-release ]]; then
	DIST_NAME=$(grep "^ID=" /etc/os-release| cut -c 4-)
	DIST_VERSION=$(grep "^VERSION_ID=" /etc/os-release| cut -c 12-)
	DIST_VERSION="${DIST_VERSION%\"}"
	DIST_VERSION="${DIST_VERSION#\"}"

	if ! $CUSTOM_INSTALL && [[ $DIST_NAME != raspbian ]]; then
		if ($SILENTUPDATE) ; then
			echo Failed to find OS/distribution:
			echo $DIST_NAME
			echo $DIST_VERSION
			echo
			exit 1
		fi
		whiptail --backtitle "IHC Captain" --title "Ukendt OS/distribution" --msgbox "Din Linux distributioner ikke en raspbian distribution.\nID: $DIST_NAME / $DIST_VERSION" $WT_HEIGHT $WT_WIDTH
		exit 1
	fi
else
	if ($SILENTUPDATE) ; then
		echo "Failed to find OS/distribution - unable to read \"/etc/os-release\""
		exit 1
	fi
	whiptail --backtitle "IHC Captain" --title "Ukendt OS/distribution" --msgbox "Kunne ikke genkende din Linux distribution/OS - kunne ikke finde filen:\n\"/etc/os-release\"" $WT_HEIGHT $WT_WIDTH
	exit 1
fi

if ! $CUSTOM_INSTALL && [[ $DIST_VERSION -lt 9 ]]; then
	if ($SILENTUPDATE) ; then
		echo "Failed to find right debian distribution - should be stretch"
		exit 1
	fi
	whiptail --backtitle "IHC Captain" --title "Ukendt OS/distribution" --msgbox "Kunne ikke genkende din Linux distribution/OS ($DIST_NAME / $DIST_VERSION)" $WT_HEIGHT $WT_WIDTH
	exit 1
fi

# make lookups easier later on
if [ $DIST_NAME == "raspbian" ]; then
	IS_A_PI=true
fi

# Calc windows sizes
WT_HEIGHT=17
WT_WIDTH=$(tput cols)

if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
	WT_WIDTH=80
fi
if [ "$WT_WIDTH" -gt 178 ]; then
	WT_WIDTH=120
fi
WT_MENU_HEIGHT=$(($WT_HEIGHT-7))

######################################################################################
# install IHC Captain files
######################################################################################
install_ihccaptain() {
	if [ ! -d "$DEST_DIR" ]; then
		run_command "mkdir $DEST_DIR" "Opretter mappen $DEST_DIR"
	fi
	cd $DEST_DIR
	run_command "wget -Nq $DLURL$DLFILE" "Henter IHC Captain($DLFILE)"
	run_command "tar -xpszf $DLFILE" "Udpakker IHC Captain"
	rm $DLFILE > /dev/null 2>&1
}

######################################################################################
# service install function
######################################################################################
install_service() {
	#install the script and set the path
	cp "${DEST_DIR}/installer/service.tpl" /etc/init.d/ihccaptain
	sed -i -e "s|_INSTALLDIR_|$DEST_DIR|g" /etc/init.d/ihccaptain
	#make the script executeable
	chmod +x /etc/init.d/ihccaptain

	#add to autostart
	run_command "update-rc.d ihccaptain defaults" "Installation af IHC autostart service"

	# Install af services for setting using boot
	cp "${DEST_DIR}/installer/change_hostname" /etc/init.d/
	cp "${DEST_DIR}/installer/change_password" /etc/init.d/
	cp "${DEST_DIR}/installer/create_ssl" /etc/init.d/
	chmod +x /etc/init.d/change_hostname
	chmod +x /etc/init.d/change_password
	chmod +x /etc/init.d/create_ssl

	if [ ! -f "/boot/ihccaptain-hostname.txt" ]; then
		touch "/boot/ihccaptain-hostname.txt"
	fi
	if [ ! -f "/boot/ihccaptain-password.txt" ]; then
		touch "/boot/ihccaptain-password.txt"
	fi
	if [ ! -f "/boot/ihccaptain-network.txt" ]; then
		cp "${DEST_DIR}/installer/ihccaptain-network.txt" /boot/
	fi

	if (! grep --quiet $CHECKMARK /etc/network/interfaces); then
		echo "# $CHECKMARK-start" >> /etc/network/interfaces
		echo "source /boot/ihccaptain-network.txt" >> /etc/network/interfaces
		echo "# $CHECKMARK-end" >> /etc/network/interfaces
	fi

	run_command "update-rc.d change_hostname defaults" "Installation af change_hostname"
	run_command "update-rc.d change_password defaults" "Installation af change_password"
	run_command "update-rc.d create_ssl defaults" "Installation af create_ssl"

}

######################################################################################
# nginx install website
######################################################################################
setup_nginx() {
	# automatic install or not -
	AUTOINS=false

	# docker: Docker cant show any fancy ui so it uses defaults
	if ! $INSIDE_DOCKER ; then
		if [ -z ${2} ]; then
			webserversetup
		else
			AUTOINS=true
			WEBINSTALL=${2}
			WEBPORT=${3}
			SSLINSTALL=${4}
			SSLPORT=${5}
			if [ -z ${6} ];then
				LETSENC=false
				DNSNAME=_
			else
				LETSENC=true
				DNSNAME=${6}
			fi
		fi
	else
		# docker: Ports defined at top of script so we use these for docker
		AUTOINS=true
		WEBINSTALL=true
		SSLINSTALL=false
	fi

	if($LETSENC);then
		SSLINSTALL=true
	fi

	# Redirect port 80 - todo allow this in the configuration/too
	REDIRECT80=false
	if ($REDIRECT80); then
		WEBINSTALL=false
		# remove the comment
		REDIR80RPL=""
	else
		# comment it out
		REDIR80RPL="#"
	fi

	TEMPDEST=/tmp/nginx.tpl
	FINALDEST=/etc/nginx/sites-available/ihccaptain
	PHPSOCK=$(ls /var/run/php/php*.sock 2>/dev/null | sed -n '1 p');
	# If this script installs php it also sets version
	if [ ! -z $PHPVER ] ; then
		if ! $INSIDE_DOCKER && [ -z "$PHPSOCK" ]; then
			echo "Unable to find PHP Socket fatal error"
			exit 1
		fi
		PHPVER=$(echo $PHPSOCK| cut -d/ -f5| cut -c4-6)
	fi

	# fix find my pi and server config
	cp "${DEST_DIR}/installer/findmypi.sh" ${DEST_DIR}/tools/findmypi.sh
	cp "${DEST_DIR}/installer/serverconfig.json" ${DEST_DIR}/data/serverconfig.json
	chown www-data:www-data ${DEST_DIR}/data/serverconfig.json

	#install the script and set the path
	rm /etc/nginx/sites-enabled/ihccaptain > /dev/null 2>&1
	rm /etc/nginx/sites-enabled/default > /dev/null 2>&1
	cp "${DEST_DIR}/installer/nginx.tpl" $TEMPDEST

	sed -i -e "s|_INSTALLDIR_|$DEST_DIR|g" $TEMPDEST

	# set php socket and more php
	sed -i -e "s|_PHPSOCK_|$PHPSOCK|g" $TEMPDEST
	sed -i -e "s|_WEBPORT_|$WEBPORT|g" $TEMPDEST
	sed -i -e "s|_WEBPORT_|$WEBPORT|g" ${DEST_DIR}/data/serverconfig.json
	sed -i -e "s|_SSLPORT_|$SSLPORT|g" $TEMPDEST
	sed -i -e "s|_SSLPORT_|$SSLPORT|g" ${DEST_DIR}/data/serverconfig.json

	sed -i -e "s|_WEBPORT_|$WEBPORT|g" ${DEST_DIR}/tools/findmypi.sh
	sed -i -e "s|_SSLPORT_|$SSLPORT|g" ${DEST_DIR}/tools/findmypi.sh

	if ($WEBINSTALL);then
		sed -i -e "s|_WEBINSTALL_||g" $TEMPDEST
		sed -i -e "s|_WEBINSTALL_|true|g" ${DEST_DIR}/data/serverconfig.json
	else
		sed -i -e "s|_WEBINSTALL_|#|g" $TEMPDEST
		sed -i -e "s|_WEBINSTALL_|false|g" ${DEST_DIR}/data/serverconfig.json
	fi

	if ($SSLINSTALL);then
		sed -i -e "s|_SSLINSTALL_||g" $TEMPDEST
		# lets encrypt has proper SSL
		if($LETSENC);then
			# Set servername
			sed -i -e "s|_LETSENCDNS_|$DNSNAME|g" $TEMPDEST
			# Build extende security
			# if [ ! -f "$EXTRASSL" ];then
			#	if ($AUTOINS);then
			#		openssl dhparam -out $EXTRASSL 2048 > /dev/null 2>&1
			#	else
			#		run_command "openssl dhparam -out $EXTRASSL 2048 > /dev/null 2>&1" "Bygger udvidet SSL sikkerhed - dette kan tage flere minutter"
			#	fi
			# fi
			#sed -i -e "s|#_XTRASSL_|ssl_dhparam $EXTRASSL;|g" $TEMPDEST

			# set lets encrypt SSL keys
			sed -i -e "s|_SSLCERT1_|/etc/letsencrypt/live/$DNSNAME/fullchain.pem|g" $TEMPDEST
			sed -i -e "s|_SSLCERT2_|/etc/letsencrypt/live/$DNSNAME/privkey.pem|g" $TEMPDEST

			# todo call lets encrypt here
		else
			# set servername to basic
			sed -i -e "s|_LETSENCDNS_|_|g" $TEMPDEST
			# set fake SSL
			sed -i -e "s|_SSLCERT1_|$SSLCERT1|g" $TEMPDEST
			sed -i -e "s|_SSLCERT2_|$SSLCERT2|g" $TEMPDEST

			# build fake certs
  			if [ ! -f $SSLCERT2 ] || [ ! -s $SSLCERT2 ] || [ ! -f $SSLCERT1 ] || [ ! -s $SSLCERT1 ] || [ ! -f $CERTFILE ] || [ ! -s $CERTFILE ]; then
  				if ($AUTOINS); then
      				make-ssl-cert generate-default-snakeoil --force-overwrite
      			else
      				run_command "make-ssl-cert generate-default-snakeoil --force-overwrite" "Bygger selfsigned SSL certifikater"
      			fi
      			cat $SSLCERT2 $SSLCERT1 > $CERTFILE
			fi
		fi
		# update server config file
		sed -i -e "s|_SSLINSTALL_|true|g" ${DEST_DIR}/data/serverconfig.json
	else
		# disable SSL
		sed -i -e "s|_SSLINSTALL_|#|g" $TEMPDEST
		# set servername to basic
		sed -i -e "s|_LETSENCDNS_|_|g" $TEMPDEST
		# update server config file
		sed -i -e "s|_SSLINSTALL_|false|g" ${DEST_DIR}/data/serverconfig.json
	fi

	# enable/disable port redirect
	sed -i -e "s|_REDIRECT80_|$REDIR80RPL|g" $TEMPDEST

	cp $TEMPDEST $FINALDEST > /dev/null 2>&1
	rm $TEMPDEST > /dev/null 2>&1
	chown www-data:www-data $FINALDEST > /dev/null 2>&1
	ln -s $FINALDEST /etc/nginx/sites-enabled/  > /dev/null 2>&1

	# fix cgi.fix_pathinfo=0
	echo cgi.fix_pathinfo=0 > "/etc/php/$PHPVER/fpm/conf.d/90-ihccaptain.ini"

	# docker: we dont do find my pi on docker images
	if ! $INSIDE_DOCKER ; then
		if ($AUTOINS);then
			$DEST_DIR/tools/findmypi.sh -q
		else
			run_command "$DEST_DIR/tools/findmypi.sh -q" "Tilføjer/opdatere Raspberry Pi til http://jemi.dk/findmypi/"
		fi
	fi
}

######################################################################################
# cronjob install website
######################################################################################
install_cronjob(){
	# check it exists - if not then append else just add
	if (crontab -l > /dev/null 2>&1);then
		( crontab -l | grep -v -F "$CRONCMD" ; echo "$CRONJOB" ) | crontab -
	else
		echo "$CRONJOB" | crontab -
	fi
}

######################################################################################
# Makelogin welcome
######################################################################################
makeLogin(){
	TEXT="# IHC Captain welcome BEGIN - $CHECKMARK-start"
	TEXT+=$'\n'
	TEXT+=$(< ${DEST_DIR}/installer/welcome.txt)
	TEXT+=$'\n'
	TEXT+="# IHC Captain welcome END - $CHECKMARK-end"
	# append to rc.local
	if (! grep --quiet $CHECKMARK /etc/rc.local); then
		sed -i 's@exit 0@@' /etc/rc.local
		echo "$TEXT" >> /etc/rc.local
		echo 'exit 0' >> /etc/rc.local
	fi

	# bash login
	if [[ ! -f $HOMEDIR/.bashrc ]]; then
		touch $HOMEDIR/.bashrc
	fi
	if (! grep --quiet $CHECKMARK $HOMEDIR/.bashrc); then
		echo "$TEXT" >> $HOMEDIR/.bashrc
	fi
}

######################################################################################
# Run a command function
# $1 = Command to execut
# $2 = Program/taks description
# $3 = Should we run in the background and wait?
# $4 = If set will allow this return code to validate as ok return status
######################################################################################
run_command(){
	if [ "$3" == "wait" ]; then
		ERROR=$( { bash -c "$1" > /dev/null; } 2>&1 ) & pid=$!
		spinner $pid "$2"
		wait $pid
		local result=$?
	else
		ERROR=$( { bash -c "$1" > /dev/null; } 2>&1 ) & pid=$!
		wait $pid
		local result=$?
	fi

	# ignore handler
	if [ "$4" == $result ]; then
		result=0
	fi

	#error handler
	if [ $result == 0 ]; then
		echo -e "[  ${GTXT}OK${BTXT}  ] $2"
	else
		echo -e "[ ${RTXT}Fejl${BTXT} ] $2"
		echo -e "├──────\u25BA Fejl kommando: $1"
		echo -e "├──────\u25BA Fejl kode: $result"
		echo -e "└──────\u25BA Fejl tekst: $ERROR"
		echo
		GERROR=true
	fi
}
######################################################################################
# Wait for a programs
# $1 = program pid to wait for
# $2 = program/taks description
######################################################################################
spinner()
{
	# docker: we dont display spinners
	if $INSIDE_DOCKER ; then
		echo "${2}..."
		return 0
	fi
	hideinput
	local delay=0.35
	local curpos=-1;
	local filchar="${GTXT}\u25A0${BTXT}"
	local mark="${WTXT}\e[1m\u25A0\e[0${BTXT}"
	local tdirect=true
	local prstr=
	# fix layout and cursors
	tput civis
	echo -n "[      ]"
	tput cuf 1
	# write program name/description
	echo -n "$2"
	# place cursor for updates
	tput cub $(( ${#2} + 8 ))

	#wait for process and draw progress bar while waiting
	while $(kill -0 $1 > /dev/null 2>&1); do
		if [ $curpos -gt 4 ]; then
			tdirect=false
		fi
		if [ $curpos -le 0 ]; then
			tdirect=true
		fi
		if ($tdirect);then
			let curpos++
		else
			let curpos--
		fi

		# build the string
		prstr=
		local x=0
		while [ $x -lt $curpos ];	do
			prstr="${filchar}${prstr}"
			x=$(( $x + 1 ))
		done
		prstr="${prstr}%s"
		while [ $x -le 4 ];	do
			prstr="${prstr}${filchar}"
			x=$(( $x + 1 ))
		done

		# print it
		printf -v echostr "$prstr" "${mark}"
		echo -en $echostr
		sleep $delay
		tput cub 6
	done
	echo -en "${mark}${mark}${mark}${mark}${mark}${mark}"
	sleep 0.3
	tput cub 6
	echo -en "${filchar}${filchar}${filchar}${filchar}${filchar}${filchar}"
	sleep 0.2
	tput cub 6
	echo -en "${mark}${mark}${mark}${mark}${mark}${mark}"
	sleep 0.3
	tput cub 6
	echo -en "${filchar}${filchar}${filchar}${filchar}${filchar}${filchar}"
	sleep 0.2
	tput cub 7
	cleanup nonewline
}

######################################################################################
# disable input stuff
######################################################################################
hideinput()
{
  if [ -t 0 ]; then
	 stty -echo -icanon time 0 min 0
  fi
}

cleanup()
{
  tput cnorm
  if [ -t 0 ]; then
	stty sane
  fi
  if [ "$1" != "nonewline" ]; then
	echo
  fi
}


askforport()
{
	NEWPORT=$(whiptail --backtitle "IHC Captain" --nocancel --inputbox "Hvilken port ønsker du at IHC Captain webservice skal køre på? Standard er 80" $WT_HEIGHT $WT_WIDTH $WEBPORT --title "IHC Captain web port" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
    	re='^[0-9]+$'
		if ! [[ $NEWPORT =~ $re ]] ; then
		  	whiptail --title "Fejl!" --msgbox "Web porten skal være et heltal" $WT_HEIGHT $WT_WIDTH
		  	askforport
		fi
		WEBPORT=$NEWPORT
	fi
}

askforsslport()
{
	NEWPORT=$(whiptail --backtitle "IHC Captain" --nocancel --inputbox "Hvilken port ønsker du at SSL IHC Captain webservice skal køre på? Standard er 443" $WT_HEIGHT $WT_WIDTH $SSLPORT --title "IHC Captain SSL port" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
    	re='^[0-9]+$'
		if ! [[ $NEWPORT =~ $re ]] ; then
		  	whiptail --backtitle "IHC Captain" --title "Fejl!" --msgbox "SSL porten skal være et heltal" $WT_HEIGHT $WT_WIDTH
		  	askforsslport
		fi
		SSLPORT=$NEWPORT
	fi
}

webserversetup()
{

	whiptail --backtitle "IHC Captain" --nocancel --title "Webserver installation" --checklist --separate-output "Hvilke webservices skal installeres?" $WT_HEIGHT $WT_WIDTH 2 "HTTP" "Standard http webserver " ON "SSL" "HTTPS/SSL webserver " ON 2>results
	webinstok=false
	SSLINSTALL=false
	WEBINSTALL=false
	while read choice
	do
	case $choice in
		HTTP) askforport;webinstok=true;WEBINSTALL=true
		;;
		SSL) askforsslport;webinstok=true;SSLINSTALL=true;
		;;
		*)
		;;
	esac
	done < results
	if (! $webinstok); then
		whiptail --title "Fejl!" --msgbox "Der skal installeres minimum en webservice for at IHC Captain kan fungere korrekt." $WT_HEIGHT $WT_WIDTH
		webserversetup
	fi
	rm results
	sleep 5
}

######################################################################################
# Make sure www-data is in control
######################################################################################
fixRights(){
	if [[ $(id -u) != 0 ]]; then
		echo "Not root - so unable to fix the rights :("
		exit 1
	fi
	run_command "chmod -x $DEST_DIR/* -R" "Rydder op i rettigheder"
	run_command "find $DEST_DIR -name '*.sh' -exec chmod +x {} +" "Sætter execute rettigheder"
	run_command "chmod +x $DEST_DIR/installer/install" "Sætter install rettigheder"
	run_command "chmod ug=rwX,o=rX $DEST_DIR -R" "Sætter gruppe og mappe rettighederne"
	run_command "chown www-data:www-data $DEST_DIR -R" "Sætter rettighederne for www-data"
}

######################################################################################
# Cleanup user data
######################################################################################
if [ "$1" == "-cleanup" ] || [ "$1" == "cleanup" ]; then
	clear
	echo "Trying to cleanup user data..."
	if [[ $(id -u) != 0 ]]; then
		echo "Not root - so unable to cleanup :("
		exit 1
	fi
	run_command "rm -rf $SSLCERT2 $SSLCERT1 $CERTFILE /etc/ssl/snakeoil.programmer $CERTFILE" "Sletter SSL certs"
	run_command "rm -rf $DEST_DIR/data/*" "Sletter bruger data"
	run_command "rm -rf /opt/ihccaptain/monitor/*.pid" "Slette monitor PID"
	exit 0
fi


######################################################################################
# Help
######################################################################################
if [[ $@ == *"help"* ]]; then
	echo "Usage:"
	echo "debug     : Show debug information"
	echo "update    : Update IHC Captain";
	echo "service   : Just update IHC Captain service";
	echo "nginx     : Just install the nginx IHC Captain config";
	echo "fixrights : Fix user and file rights";
	echo "cleanup   : Remove all user data";
	exit 0
fi

######################################################################################
# Debug IHC Captain
######################################################################################
if [[ $@ == *"debug"* ]]; then
	clear
	echo
	echo "-[Debug af installer]------------------------------------"
	echo
	echo "Install dir      : $DEST_DIR"
	echo "Run as user      : $USERNAME"
	echo "Homedir          : $HOMEDIR"
	echo "Download file    : $DLURL$DLFILE"
	echo "APT install      : $INSTALLAPT"
	echo "Distro name      : $DIST_NAME"
	echo "Distro version   : $DIST_VERSION"
	echo "HW info          : $DEVICEMODEL"
	echo "Running raspbian : $IS_A_PI"
	echo "Custom install   : $CUSTOM_INSTALL"
	echo "Inside docker    : $INSIDE_DOCKER"
	echo
	exit 1
fi

######################################################################################
# Fix rights
######################################################################################
if [[ $@ == *"fixrights"* ]]; then
	clear
	cd $DEST_DIR
	echo "Fixing rights..."
	fixRights
	exit 1
fi

######################################################################################
# Update IHC Captain
######################################################################################
if [ "$1" == "update" ] || [ "$1" == "webupdate" ]; then
	clear
	echo
	echo Opdatering af IHC Captain
	echo
	install_ihccaptain
#	if [ -x "/etc/init.d/ihccaptain" ]; then
#		install_service
#	fi
	if ($GERROR) ; then
		cleanup
		echo "Opdatering af IHC Captain fejlede"
		echo
		exit 1
	else
		# add to findmypi
		run_command "$DEST_DIR/tools/findmypi.sh -q" "Tilføjer Raspberry Pi til http://jemi.dk/findmypi/"
		cleanup
		echo "Opdatering af IHC Captain gennemført"
		echo
		exit 0
	fi
fi


######################################################################################
# Commandline update of nginx
######################################################################################

if [ "$1" == "updatenginx" ]; then
	setup_nginx "$@"
	sudo /usr/sbin/service nginx restart
	PHPFPM=$(ls /etc/init.d/php*-fpm 2>/dev/null | sed -n '1 p');
	PHPFPM=${PHPFPM##*/}
	if [ -z "$PHPFPM" ]; then
		echo Unable to restart the php-fpm service
	else
		sudo /usr/sbin/service $PHPFPM restart
	fi
	exit 0
fi

######################################################################################
#Are we root?
######################################################################################
clear
if [[ $(id -u) != 0 ]]; then
	whiptail --backtitle "IHC Captain" --title "Du er ikke root/superuser" --msgbox "Du skal være root/superuser for at køre scriptet\n\nKør install med sudo -s $0 $1" $WT_HEIGHT $WT_WIDTH
	exit 1
fi

#disable input
trap cleanup EXIT
trap hideinput CONT

######################################################################################
# Removal
######################################################################################
if [ "$1" == "uninstall" ] || [ "$1" == "remove" ]; then
	if (! whiptail --backtitle "IHC Captain" --title "Fjernelse af IHC Captain" --yesno "Er du sikker på du ønsker at fjerne IHC Captain?" --yes-button "Ja" --no-button "Nej" $WT_HEIGHT $WT_WIDTH) then
		clear
		echo "Pheewww :)"
		exit 0
	fi
	REMOVEFILES=false
	if (whiptail --backtitle "IHC Captain" --title "Slet alle filer" --yesno "Skal alle filer slettes? Hvis ikke efterlades de i mappen \"$DEST_DIR\"" --yes-button "Ja" --no-button "Nej" $WT_HEIGHT $WT_WIDTH ) then
		REMOVEFILES=true
	fi
	clear
	echo
	echo Fjernelse af IHC Captain...
	echo

	# remove symlink
	rm /usr/bin/ihccapmon -f

	#remove from autostart
	run_command "update-rc.d ihccaptain remove" "Fjernelse af IHC autostart service"
	if ($GERROR) ; then
		cleanup
		echo "Fjernelse af autostart service fejlede!"
		echo
		exit 1
	fi

	#remove from autostart
	run_command "update-rc.d change_hostname remove" "Fjernelse af change_hostname"
	if ($GERROR) ; then -
		cleanup
		echo "Fjernelse af change_hostname service fejlede!"
		echo
		exit 1
	fi

	#remove from autostart
	run_command "update-rc.d change_password remove" "Fjernelse af change_password"
	if ($GERROR) ; then
		cleanup
		echo "Fjernelse af change_password service fejlede!"
		echo
		exit 1
	fi

	#remove from autostart
	run_command "update-rc.d create_ssl remove" "Fjernelse af create_ssl"
	if ($GERROR) ; then
		cleanup
		echo "Fjernelse af create_ssl service fejlede!"
		echo
		exit 1
	fi

	# remove welcome prompts
	sed -i "/$CHECKMARK-start/,/$CHECKMARK-end/d" /etc/rc.local
	sed -i "/$CHECKMARK-start/,/$CHECKMARK-end/d" $HOMEDIR/.bashrc

	# Remove service files
	rm /etc/init.d/ihccaptain > /dev/null 2>&1
	rm /etc/init.d/change_hostname > /dev/null 2>&1
	rm /etc/init.d/change_password > /dev/null 2>&1
	rm /etc/init.d/create_ssl > /dev/null 2>&1

	# remove websites
	rm /etc/nginx/sites-available/ihccaptain > /dev/null 2>&1
	rm /etc/nginx/sites-enabled/ihccaptain > /dev/null 2>&1

	# remove crontab job
	( crontab -l | grep -v -F "$CRONCMD" ) | crontab -

	run_command "/etc/init.d/nginx restart" "Webserver genstart"
	if ($GERROR) ; then
		cleanup
		echo "Genstart af webserver fejlede"
		echo
		exit 1
	fi

	if ($REMOVEFILES) ; then
		echo
		echo "Du skal selv slete filerne med:"
		echo "sudo rm -rf $DEST_DIR"
		echo
	fi
	exit 0
fi

######################################################################################
# Only install the service
######################################################################################
if [ "$1" == "service" ] || [ "$1" == "autostart" ]; then
	clear
	echo
	echo Installation af IHC Captain som autostart service...
	echo
	install_service
	cleanup
	if ($GERROR) ; then
		echo "Installation af autostart service fejlede!"
		echo
		exit 1
	else
		echo "Installation af autostart service færdig"
		echo
		exit 0
	fi
fi

######################################################################################
# Only install the nginx service
######################################################################################
if [ "$1" == "nginx" ]; then
	clear
	echo
	echo Installation af IHC Captain nginx service
	echo
	setup_nginx "$@"
	run_command "/etc/init.d/nginx restart" "Webserver genstart"
	PHPFPM=$(ls /etc/init.d/php*-fpm 2>/dev/null | sed -n '1 p');
	PHPFPM=${PHPFPM##*/}
	if [ -z "$PHPFPM" ]; then
		echo "Unable to restart the php-fpm service"
	else
		run_command "/usr/sbin/service $PHPFPM restart" "$PHPFPM genstart"
	fi
	# cleanup session to force relogin
	find /var/lib/php/sessions/ -type f -delete > /dev/null 2>&1
	# restart service if running
	/etc/init.d/ihccaptain restart > /dev/null 2>&1
	rm /mnt/ram/ihccaptain/logins/* > /dev/null 2>&1
	cleanup
	if ($GERROR) ; then
		echo "Installation af nginx service fejlede!"
		echo
		exit 1
	else
		if [ -z $ ]; then
			whiptail --backtitle "IHC Captain" --title "Nginx webserver installeret" --msgbox "Du skal logge ud og ind igen af IHC Captain i browseren hvis du har ændret porten." $WT_HEIGHT $WT_WIDTH
			echo
		fi
		exit 0
	fi
fi

######################################################################################
# Only install the cronjob
######################################################################################
if [ "$1" == "cronjob" ]; then
	clear
	echo
	echo Installation af IHC Captain cronjob
	echo
	install_cronjob
	exit 0
fi


######################################################################################
# Info dialog
######################################################################################
# docker: dont show!
if ! $INSIDE_DOCKER; then
	if (whiptail --backtitle "IHC Captain" --title "Velkommen..." --yesno "Velkommen til installation af IHC Captain\nDenne installation anbefales til \"rene\" Raspberry Pi installationer.\nDe nødvendige programmer for at kunne køre IHC Captain bliver installeret.\n\nØnsker du at installere programmerne manuelt tryk Afbryd nu.\nDer findes vejledning til manuel installation på http://jemi.dk/ihc/" --yes-button "Fortsæt" --no-button "Afbryd" $WT_HEIGHT $WT_WIDTH) then
		#do nothing :)
		:
	else
		clear
		echo
		echo Farvel og tak \:\)
		cleanup
		exit 0
	fi
fi

######################################################################################
# Ask for service
######################################################################################
# docker: dont show!
if $INSIDE_DOCKER; then
	SERVICESTART=false
else
	if (whiptail --backtitle "IHC Captain" --title "Installer autostart" --yesno "Skal IHC Captain automatisk starte op ved genstart af Raspberry Pi?" --yes-button "Ja" --no-button "Nej" $WT_HEIGHT $WT_WIDTH ) then
		SERVICESTART=true
	else
		SERVICESTART=false
	fi
fi

# Start the normal installer
clear
echo -e "$GTXT\u25BA$GTXT\u25BA$LGTXT\u25BA ${BTXT}IHC Captain$BTXT"
echo
echo Starter installationen - vent venligst, det kan tage lang tid...
echo


######################################################################################
# Update and install packages
######################################################################################
if ($INSTALLAPT); then
	export DEBIAN_FRONTEND=noninteractive
	# PHPVER must correspand to directory name in /etc/php
	PHPVER="7.3"
	run_command "apt-get -mqqy update" "Opdatering af software arkiv" "wait"
	run_command "apt-get -qqyf install ssl-cert certbot python-certbot-nginx lsof libnss-mdns sed screen unzip zip curl wget ca-certificates binutils" "Installere ekstra programmer" "wait"
	run_command "apt-get -qqyf install nginx" "Installere webserver, nginx" "wait"
	run_command "apt-get -qqyf install php7.3-fpm php7.3-curl php7.3-soap php7.3-mbstring php7.3-xml php7.3-mysql" "Installere PHP 7.3" "wait"
	run_command "apt-get -qqy autoclean" "Oprydning af software arkiv" "wait"
	run_command "apt-get -qqyf autoremove" "Fjerner gamle programmer" "wait"
fi

######################################################################################
#allow us and the www-data user to play with the dirs
######################################################################################
run_command "usermod -a -G www-data $USERNAME" "Tilføjer $USERNAME brugeren til www-data gruppen"

## Allow www-data to control the device on raspians
if $IS_A_PI ;then
	echo "www-data ALL=NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown, /usr/sbin/service" > /etc/sudoers.d/ihccaptain
	## all the webserver to see GPU temp
	sudo usermod -aG video www-data
fi


######################################################################################
#Download IHC captain and install it and clean up
######################################################################################
install_ihccaptain


######################################################################################
#Start webserver
######################################################################################
setup_nginx
run_command "/etc/init.d/nginx restart" "Webserver genstart"
PHPFPM=$(ls /etc/init.d/php*-fpm 2>/dev/null | sed -n '1 p');
PHPFPM=${PHPFPM##*/}
if [ -z "$PHPFPM" ]; then
	echo "Unable to restart the php-fpm service"
else
	run_command "/usr/sbin/service $PHPFPM restart" "$PHPFPM genstart"
fi

# Change the users/rights for the folders
fixRights

#Install cronjob
install_cronjob

# make symlink shortcut for monitor tool
ln -s $DEST_DIR/tools/showmonitor.sh /usr/bin/ihccapmon

######################################################################################
#Install the IHC captain service
######################################################################################
if ($SERVICESTART) ; then
	install_service
fi

if ! $INSIDE_DOCKER ; then
	makeLogin
fi

######################################################################################
#All done
######################################################################################
#Handle any errors found or else show a nice
if ($GERROR) ; then
	echo
	echo "Der var en eller flere fejl - se ovenstående for en forklaring."
	cleanup
else
	if $CUSTOM_INSTALL ; then
		echo
		echo '
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
           IHC Captain installationen er færdig!
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
';
		echo
		echo "Bemærk at den beror på de to services 'nginx' og 'php7.3-fpm'"
		echo
		echo "IHC Captain kan tilgåes på http://localhost:$WEBPORT/"
		echo
	else
		# Add to findmypi
		run_command "$DEST_DIR/tools/findmypi.sh -q" "Tilføjer Raspberry Pi til http://jemi.dk/findmypi/"
		# Show result
		echo '
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
           IHC Captain installationen er færdig!
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

Åbn http://jemi.dk/findmypi/ i din browser og følg guiden.

Det anbefales at du genstarter din Raspberry Pi nu - dette gøres med:
 sudo reboot';
		echo
		echo "... og det var http://jemi.dk/findmypi/ du skulle åbne i din browser :)"
		echo

	fi
	cleanup
fi