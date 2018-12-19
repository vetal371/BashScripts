#!/bin/sh

export JAVA_HOME=/usr/java/jdk1.7.0_71

export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.rmi.port=8986 -Dcom.sun.management.jmxremote.port=8986 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -XX:-UseLoopPredicate -XX:+UnlockDiagnosticVMOptions -XX:-LoopLimitCheck -XX:SurvivorRatio=3 -XX:NewRatio=1 -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=50 -XX:+ScavengeBeforeFullGC -XX:+CMSScavengeBeforeRemark -Dsun.net.inetaddr.ttl=60 -XX:+HeapDumpOnOutOfMemoryError"

# These variables defined in this script below, because the variables are set programmatically
  # export CATALINA_BASE
  # export CATALINA_HOME
  # export CATALINA_PID


 #Bash only
# COLOREND="\e[0m"
# BLACK="\e[30m"; BG_BLACK="\e[40m";
# RED="\e[31m"; BG_RED="\e[41m";
# GREEN="\e[32m"; BG_GREEN="\e[42m";
# BROWN="\e[33m"; BG_BROWN="\e[43m";
# BLUE="\e[34m"; BG_BLUE="\e[44m";
# PURPLE="\e[35m"; BG_PURPLE="\e[45m";
# CYAN="\e[36m"; BG_CYAN="\e[46m";
# L_GRAY="\e[37m"; BG_L_GRAY="\e[47m";

#echo -en "${BLACK}This is TEXT!!!!!!!!!${COLOREND}"
#echo -en "${RED}This is TEXT!!!!!!!!!${COLOREND}"



# tput sgr0    # return color to normal state
COLOREND="\033[0m"    #All attributes by default



#
# Font Types
#

FT_BOLD="\033[1m"
FT_D_GRAY="\033[2m"
FT_UNDERLINE="\033[4m"
FT_BLINKING="\033[5m"
FT_INVERSION="\033[7m"

FT_INTENSITY="\033[22m"    # Set normal intensity
FT_UNDOUNDERLINE="\033[24m"
FT_UNDOBLINKING="\033[25m"
FT_UNDOINVERSION="\033[27m"



#
# Font colors
#

F_BLACK="\033[30m"
F_RED="\033[31m"
F_GREEN="\033[32m"
F_YELLOW="\033[33m"
F_BLUE="\033[34m"
F_MAGENTA="\033[35m"
F_CYAN="\033[36m"
F_GRAY="\033[37m"



#
# Background colors
#

BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_GRAY="\033[47m"



#echo "${F_BLACK}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${FT_BOLD}${FT_UNDERLINE}${F_RED}${BG_BLUE}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${FT_BOLD}${F_GREEN}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${F_YELLOW}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${F_BLUE}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${F_MAGENTA}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${F_CYAN}This is a text!!!!!!!!!!!!!!!${COLOREND}"
#echo "${F_GRAY}This is a text!!!!!!!!!!!!!!!${COLOREND}"

##echo -en "\033[37;1;41m Some text \033[0m"
#echo "\033[37;1;41m Sime text \033[0m"

showErrorMSG() {
  echo ""
  echo "${FT_BOLD}${BG_RED} ERROR: ${COLOREND}"
  echo ""
  echo "${FT_BOLD}${F_RED}${1}${COLOREND}"
  echo ""
}

showUsageMSG() {
  echo ""
  echo "${FT_BOLD}${BG_GREEN} USAGE: ${COLOREND}"
  echo ""
}


grep --version >> /dev/null

if [ $? -eq 127 ]; then
  showErrorMSG "grep not found. Please install grep utility"
  exit
fi


expr --version >> /dev/null

if [ $? -eq 127 ]; then
  showErrorMSG "expr not found. Please install expr utility"
  exit
fi


#which -a >> /dev/null

#if [ $? -eq 127 ]; then
#  showErrorMSG "which not found. Please install which utility"
#  exit
#fi

# 
# grep
# expr
# which
# 
# sed
# awk
# cut
# cat
# 
# 
# dirname
# basename
# readlink 
# 
# 



SCRIPT_ARG1=$1
SCRIPT_ACTION=""

SCRIPT_ARG2=$2
CONTAINER_PATH=""
ABSOLUTE_CONTAINER_PATH=""

CONTAINER_CONFIG=""


checkiScriptAction() {
  if echo $1 | grep -q -E "^\-\-start$" -o; then
    SCRIPT_ACTION="start"
  elif echo $1 | grep -q -E "^\-\-stop$" -o; then
    SCRIPT_ACTION="stop"
  elif echo $1 | grep -q -E "^\-\-restart$" -o; then
    SCRIPT_ACTION="restart"
  elif echo $1 | grep -q -E "^\-\-restart\-nocls$" -o; then
    SCRIPT_ACTION="restart-nocls"
  elif echo $1 | grep -q -E "^\-\-clear\-work$" -o; then
    SCRIPT_ACTION="clear-work"
  elif echo $1 | grep -q -E "^\-\-clear\-temp$" -o; then
    SCRIPT_ACTION="clear-temp"
  elif echo $1 | grep -q -E "^\-\-clear\-work-temp$" -o; then
    SCRIPT_ACTION="clear-work-temp"
  elif echo $1 | grep -q -E "^\-\-clear\-logs$" -o; then
    SCRIPT_ACTION="clear-logs"
  else
    showErrorMSG "Script was called with incorrect commandline arguments. Please check command line prompt"
    exit 1
  fi
}

checkiScriptActionInFileName() {
  if echo "$1" | grep -q -E "^tomcatmgr.start" -o; then
    SCRIPT_ACTION="start"
    SCRIPT_ACTION_IN_FILENAME=1
  elif echo "$1" | grep -q -E "^tomcatmgr.stop" -o; then
    SCRIPT_ACTION="stop"
    SCRIPT_ACTION_IN_FILENAME=1
  elif echo "$1" | grep -q -E "^tomcatmgr.restart" -o; then
    SCRIPT_ACTION="restart"
    SCRIPT_ACTION_IN_FILENAME=1
  elif echo "$1" | grep -q -E "^tomcatmgr.restart-nocls" -o; then
    SCRIPT_ACTION="restart-nocls"
    SCRIPT_ACTION_IN_FILENAME=1
  else
    showErrorMSG "Incorrect script name. Please check action in scriptname"
    exit 1
  fi
}

checkContainerPath() {
  tmpPATH=`echo $1 | sed 's/\.//g'`
  tmpCONTAINER_PATH="${SCRIPTPATH}/${tmpPATH}"
  CONTAINER_PATH=`echo ${tmpCONTAINER_PATH}|sed 's/\/\//\//g'` 
  
  

  if [ ! -d ${CONTAINER_PATH} ]; then
    #showErrorMSG "Container directory ${CONTAINER_PATH} not found"
    ABSOLUTE_CONTAINER_PATH=`echo $1|sed 's/\.//g'`
    if [ ! -d ${ABSOLUTE_CONTAINER_PATH} ]; then
      showErrorMSG "Container directory ${CONTAINER_PATH} or ${ABSOLUTE_CONTAINER_PATH=} not found"
      exit 1
    else
      CONTAINER_PATH=$ABSOLUTE_CONTAINER_PATH
    fi
  fi
}

checkContainerConfig() {
  tmpCONTAINER_CONFIG="${CONTAINER_PATH}/conf/server.xml"
  CONTAINER_CONFIG=`echo ${tmpCONTAINER_CONFIG}|sed 's/\/\//\//g'`

  if [ ! -f ${CONTAINER_CONFIG} ]; then
    showErrorMSG "${CONTAINER_CONFIG} not found"
    exit 1
  fi
  
}

checkTomcatServer() {

  if [ ! -f $1/bin/catalina.sh ]; then
    showErrorMSG "$1/bin/catalina.sh not found. Please check installed Tomcat server, or application container path in commandline prompt"
    exit 1
  fi

}

############################################################
#                    base script body                      #
############################################################

if echo $1 | grep -q -E "\-\-help" -o; then
  showUsageMSG
  exit 0
fi


ABSOLUTE_SCRIPTNAME=`readlink -e "$0"`
SCRIPTPATH=`dirname $ABSOLUTE_SCRIPTNAME`
SCRIPTNAMEFULL=`basename $ABSOLUTE_SCRIPTNAME`
SCRIPTNAME=`basename $SCRIPTNAMEFULL .sh`

CONTAINERDIRNAME=""
#CONTAINERDIRNAME=`echo $SCRIPTNAME|cut -f2 -d "_"`
CONTAINERDIRNAME=`echo $SCRIPTNAME|awk -F "_" '{print $2}'`

#if [ $CONTAINERDIRNAME -z ]; then
if [ $CONTAINERDIRNAME ]; then
  CONTAINERDIRNAME_IN_FILENAME=1
else
  CONTAINERDIRNAME_IN_FILENAME=0
fi



SCRIPT_ACTION_IN_FILENAME=0

#
# Get script action from filename and check commandline arguments
#
if echo "$SCRIPTNAMEFULL" | grep -q -E "^tomcatmgr.sh" -o; then
  # Check tomcatmgr.sh in filename

  checkiScriptAction ${SCRIPT_ARG1}
  CONTAINER_PATH=$SCRIPT_ARG2

  if [ -z $SCRIPT_ARG2 ]; then
    CONTAINER_PATH=$SCRIPTPATH
  fi
  
  checkContainerPath $CONTAINER_PATH
  checkContainerConfig
  
elif echo "$SCRIPTNAME" | grep -q -E "^tomcatmgr_" -o; then
  # Check tomcatmgr_ in filename
  checkiScriptAction ${SCRIPT_ARG1} 
  
  CONTAINER_PATH="$SCRIPTPATH/${CONTAINERDIRNAME}"
  checkContainerPath $CONTAINER_PATH
  checkContainerConfig


elif echo "$SCRIPTNAME" | grep -q -E "^tomcatmgr." -o; then
  # Check tomcatmgr. in filename
  checkiScriptActionInFileName $SCRIPTNAME

  CONTAINER_PATH="$SCRIPTPATH/${CONTAINERDIRNAME}"
  checkContainerPath $CONTAINER_PATH
  checkContainerConfig

else
  showErrorMSG "Incorrect script name"
  showUsageMSG
  exit 1
fi


#checkContainerPath $SCRIPT_ARG2
#checkContainerConfig



export CATALINA_BASE=`echo ${CONTAINER_PATH}| sed "s/\/$//g"`

export CATALINA_PID=`echo "${CONTAINER_PATH}/tomcat-app.pid"|sed 's/\/\//\//g'`

export CATALINA_HOME=`dirname ${CONTAINER_PATH}`

#
#checkTomcatServer $CATALINA_HOME
#



startContainer() {
  checkTomcatServer $CATALINA_HOME
  
  if [ -f $CATALINA_PID ]; then
    showErrorMSG "Tomcat already running. Or delete $CATALINA_PID manualy and try again"
    exit 1
  else
    if [ ! -f $CATALINA_HOME/bin/startup.sh ]; then
      showErrorMSG "$CATALINA_HOME/bin/startup.sh not found"
      exit 1
    else
      $CATALINA_HOME/bin/startup.sh
    fi
  fi
}



stopContainer() {
  checkTomcatServer $CATALINA_HOME
  
  APP_PID=`cat $CATALINA_PID`

  if [ ! -f $CATALINA_HOME/bin/shutdown.sh ]; then
    showErrorMSG "$CATALINA_HOME/bin/shutdown.sh not found"
    exit 1
  else
    $CATALINA_HOME/bin/shutdown.sh
  fi

  if [ -f $CATALINA_PID ]; then
    sleep 120
  fi

  if [ -f $CATALINA_PID ]; then
    kill -9 $APP_PID
    echo "Tomcat application with $APP_PID PID has been killed"
    rm -f $CATALINA_PID
  else
    echo "Tomcat application with $APP_PID PID has been stoped"
  fi

}



isStartedContainer() {
  checkTomcatServer $CATALINA_HOME

  if [ -f $CATALINA_PID ]; then
    showErrorMSG "Tomcat is running. Please stop Tomcat before this action and try again"
    exit 1
  fi
}



clearDirectory() {
  checkTomcatServer $CATALINA_HOME

  isStartedContainer
  
  if [ -d $1 ]; then
    rm -rf $1/*
  else
    showErrorMSG "Directory $1 not found"
    #exit 1
  fi
}

clearWork() {

  checkTomcatServer $CATALINA_HOME

  echo ""
  DIR_to_WORK=`echo "$CATALINA_BASE/work"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_WORK}"
  clearDirectory "${DIR_to_WORK}"

}



clearTemp() {

  checkTomcatServer $CATALINA_HOME

  echo ""
  DIR_to_TEMP=`echo "$CATALINA_BASE/temp"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_TEMP}"
  clearDirectory "${DIR_to_TEMP}"

}



clearWorkTemp() {

  checkTomcatServer $CATALINA_HOME

  echo ""
  DIR_to_WORK=`echo "$CATALINA_BASE/work"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_WORK}"
  clearDirectory "${DIR_to_WORK}"

  echo ""
  DIR_to_TEMP=`echo "$CATALINA_BASE/temp"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_TEMP}"
  clearDirectory "${DIR_to_TEMP}"


}



clearLogs() {

  checkTomcatServer $CATALINA_HOME

  echo ""
  DIR_to_LOGS=`echo "$CATALINA_BASE/logs"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_LOGS}"
  clearDirectory "${DIR_to_LOGS}"

}



restartContainer() {
  
  checkTomcatServer $CATALINA_HOME

  stopContainer
  
  echo ""
  DIR_to_WORK=`echo "$CATALINA_BASE/work"|sed 's/\/\//\//g'`
  echo "Clearing ${DIR_to_WORK}"
  clearDirectory "${DIR_to_WORK}"

  echo ""

  DIR_to_TEMP=`echo "$CATALINA_BASE/temp"|sed 's/\/\//\//g'`
  echo "Clearing $DIR_to_TEMP"
  clearDirectory "${DIR_to_TEMP}"

  startContainer  
}

restartContainerNoCLS() {
  
  checkTomcatServer $CATALINA_HOME

  stopContainer
  startContainer

}



showVariables() {
  echo ""
  echo "ABSOLUTE_SCRIPTNAME:          $ABSOLUTE_SCRIPTNAME"
  echo "SCRIPTPATH                    $SCRIPTPATH"
  echo "SCRIPTNAMEFULL                $SCRIPTNAMEFULL"
  echo "SCRIPTNAME                    $SCRIPTNAME"
  echo "CONTAINERDIRNAME              $CONTAINERDIRNAME"
  echo "SCRIPT_ACTION                 $SCRIPT_ACTION"
  echo "SCRIPT_ACTION_IN_FILENAME     $SCRIPT_ACTION_IN_FILENAME"
  echo "CONTAINERDIRNAME_IN_FILENAME  $CONTAINERDIRNAME_IN_FILENAME"
  echo "CONTAINER_PATH                $CONTAINER_PATH"
  echo "CONTAINER_CONFIG              $CONTAINER_CONFIG"
  echo ""
  echo "CATALINA_BASE                 $CATALINA_BASE"
  echo "CATALINA_PID                  $CATALINA_PID" 
  echo "CATALINA_HOME                 $CATALINA_HOME"
  
  echo ""
}

if echo $@ | grep -q -E "\-\-show\-variables" -o; then
  showVariables
fi



case "$SCRIPT_ACTION" in
  "start")
    echo "Starting..."
    startContainer
    ;;
  "stop")
    echo "Stoping... This may take about two minutes"
    stopContainer
    ;;
  "restart")
    echo "Restarting..."
    restartContainer
    ;;
  "restart-nocls")
    echo "Restarting without temp and work directory clearing..."
    restartContainerNoCLS
    ;;
  "clear-work")
    echo "Clearing work directory..."
    clearWork
    ;;
  "clear-temp")
    echo "Clearing temp directory..."
    clearTemp
    ;;
  "clear-work-temp")
    echo "Clearing work and temp directories..."
    clearWorkTemp
    ;;
  "clear-logs")
    echo "Clearing log files..."
    clearLogs
    ;;
  #":")
  #  echo "No argument"
  #  ;;
  *)
    echo "default code"
    ;;
esac



