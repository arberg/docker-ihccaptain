
DEST_DIR=/opt/ihccaptain

#http://jemi.dk/ihc/files/ihccaptain.tar.gz
DLFILEFIX=""
if [ "$1" == "test" ] || [ "$2" == "test" ]; then
	DLFILEFIX=-new
fi
#download file for IHC Captain
DLURL=http://jemi.dk/ihc/files/
DLFILE=ihccaptain$DLFILEFIX.tar.gz


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

download_ihccaptain() {
	run_command "wget -Nq $DLURL$DLFILE" "Henter IHC Captain"
}

install_ihccaptain() {
	if [ ! -d "$DEST_DIR" ]; then
		run_command "mkdir $DEST_DIR" "Opretter mappen $DEST_DIR"
	fi
	cd $DEST_DIR
	download_ihccaptain
	run_command "tar -xpszf $DLFILE" "Udpakker IHC Captain"
	rm $DLFILE > /dev/null 2>&1
}

download_ihccaptain