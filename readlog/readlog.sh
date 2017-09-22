#/bin/bash

function printERROR () {
	echo "ERROR:"
	echo "  $1"
}

function showHelp () {
	echo "USAGE:"
	echo "  readlog.sh /path/to/logfile.log"
	echo "  readlog.sh --help"
}

function isRunningMySelf () {
	ABSOLUTE_SCRIPTNAME=`readlink -e $0`
	SCRIPTNAME=`basename $ABSOLUTE_SCRIPTNAME|sed s/\.sh$//g`
	SCRIPT_DIR=`dirname $ABSOLUTE_SCRIPTNAME`
	PIDFILE=${SCRIPT_DIR}/${SCRIPTNAME}.pid

	case $1 in 
		"check")
			if [ -f $PIDFILE ]; then
				PID=`cat $PIDFILE`
				printERROR "Script already running. PID: ${PID}. Please check or remove pid file"
				exit 1
			else
				echo $$ > ${SCRIPT_DIR}/${SCRIPTNAME}.pid
			fi
			;;
		"exit")
			rm -f ${SCRIPT_DIR}/${SCRIPTNAME}.pid
			exit 0
			;;
	esac	
}

function startReading () {
	isRunningMySelf "check"

	FILE=$1
	
	if [ ! -f $FILE ]; then
		printERROR "Log file not found"
        	exit 1
	fi

	iDOWN=0
	iUP=0

	tail -f $FILE | while read LINE; do
		
		COLUMN4=`echo $LINE | awk '{print $4}'`

		if [ $COLUMN4 -gt 10 ]; then
			iUP=0
			(( iDOWN++ ))

			if [ $iDOWN -eq 3 ]; then
				#echo "NOTIFICATION: DOWN"
				mail -s "NOTIFICATION: DOWN" admin@domain.com < /dev/null
			fi
		fi 

		if [ $COLUMN4 -le 10 ]; then
			iDOWN=0
			(( iUP++ ))
			
			if [ $iUP -eq 3 ]; then
				#echo "NOTIFICATION: UP"
				mail -s "NOTIFICATION: UP" admin@domain.com < /dev/null
			fi
		fi
	done
}

if [ $# -ne 1 ]; then
	printERROR "Incorrect command line arguments"
	showHelp
	exit 1
fi

LOGFILE=$1

#trap 'printERROR "To stop script, use: kill SIGTERM pid "' SIGHUP, SIGINT, SIGQUIT, SIGSTOP, SIGTSTP
trap 'isRunningMySelf "exit"' SIGHUP SIGINT SIGQUIT SIGSTOP SIGTSTP SIGTERM 

case "$1" in
	"--help") 
		showHelp
		;;
	*)
		startReading $LOGFILE
		;;
esac
