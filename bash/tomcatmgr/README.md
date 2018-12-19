# tomcatmgr 

This project is used for managing of multi conteiner configuration of Tomcat.  

**tomcatmgr.sh** - This is a main script.  
This script privide us to specify several configuration options (like: server, port) and actions for container (like: start, stop, restart) in script name.  
This script can read these arguments from command line prompt or can read these arguments from script name, and provide us easy organize management just coping script with required script name.  

**Script's name should be in following format:**  
tomcatmgr.restart_server-8080.sh
tomcatmgr_server-8080.sh
tomcatmgr.start_server-8080.sh
tomcatmgr.stop_server-8080.sh

These scripts are copy of **tomcatmgr.sh** but contains configuration examples in script name.  


