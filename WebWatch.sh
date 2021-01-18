#!/bin/bash
################################################################################
# Tool Name: WebWatch                                                       #
# Tool to check the SAP Web Dispatcher status and start if it is down          #
#        on the SAP SSO systems                                                #
# Version - 01 (Designed for SAP-SSO Systems)                                  #
# Release Date - 01/23/2020                                                    #
# For support please contact Sudhanshu Shekhar                                 #
# Note: Use this tool in SAP-SSO Systems Only, as we have different standards#
#       in other landscapes for webdispatcher SID & installation directory     #
################################################################################
# Usage: WebWatch SAPSID WEBSID WEBNUM JAVANUM                              #
#                                                                              #
# Example WebWatch S1P WEB 90 00                                            #
################################################################################


#==================================================
# Current Tool version
#==================================================
tool_version="1.0"
tool_scope="(Designed for SAP SSO System Webdispatcher Only, Tested On - SUSE Linux)"
#==================================================

#==================================================
# Source environment variables in the shell
  echo "Sourcing environment variables for the execution of the tool $0 now."  > ${LOGGER}
  . /home/`whoami`/.sapenv_`hostname`.csh
#==================================================

#==================================================
# Set Global Variables for the tool & its functions
#==================================================
TOOL_NAME=$0
SAPSID=`echo $1 | tr "[a-z]" "[A-Z]"`
WEBSID=`echo $2 | tr "[a-z]" "[A-Z]"`
WEBNUM=$3
JAVANUM=$4
NUMBER_INPUTS="$#"
LOGGER="/tmp/sapssowebdisp.log"
MAILER="sudhanshu.shekhar@company.com"
WEBWATCH_DIR=`pwd`
STARTTIME=`date +%s`
#SAPCONTROL=`which sapcontrol`
SAPCONTROL="/usr/sap/`echo $2`/SYS/exe/uc/linuxx86_64/sapcontrol"
export LD_LIBRARY_PATH="/usr/sap/`echo $2`/SYS/exe/run"
#==================================================

#==================================================
# Function: tool_help()
# Purpose: provide a detailed usage instruction to the user
tool_help()
{
    echo ""
    echo -e "\e[33mNAME:\e[0m WebWatch - ${tool_version} \e[31m ${tool_scope} \e[0m"
    echo -e "\e[33mDESCRIPTION:\e[0m This tool is used for monitoring the webdispatcher of the SAP SSO Systems."
    echo ""
    echo ""
    echo -e "\e[33mFeatures:\e[0m --->"
    echo -e "\e[33m01:\e[0m WebWatch will keep monitoring the webdispatcher of the SSO system every 10 minutes."
    echo -e "\e[33m02:\e[0m If the WebWatch finds out that the Java Server & SSO applications are running & webdispatcher is down, it will restart the webdispatcher & notify."
    echo -e "\e[33m02:\e[0m If the WebWatch finds out that the Java Server & SSO applications are down & webdispatcher is running, it will shutdown the webdispatcher & notify."
    echo -e "\e[33m02:\e[0m If the WebWatch finds out that the Java Server & SSO applications are running & webdispatcher is also running, it will just chill & wait for its next run after 10 minutes."
    echo ""
    echo ""
    echo -e "\e[33mBelow is the right way to execute this tool:\e[0m --->"
    echo -e "\e[33m Please execute me as the webadm user only."
    echo -e "\e[33m Adhoc execution --> ./WebWatch S1Q WEB 90 00"  
    echo -e "\e[33m Cron execution --> "
    echo -e "\e[33m#-----------------------------------------------------------------------------------------------------------------------------------------#"
    echo -e "\e[33m#       ****  Script to check the SAP Web Dispatcher status and start if it is down, kill it if Java or SLS services are down ****        #"
    echo -e "\e[33m#-----------------------------------------------------------------------------------------------------------------------------------------#"
    echo -e "\e[33m 00,10,20,30,40,50 * * * * /sap_binary/Basis_Scripts/SSOWebWatch S2P WEB 90 00 > /dev/null 2>&1"
    echo -e "\e[33m#-----------------------------------------------------------------------------------------------------------------------------------------#" 
    echo ""
    echo ""
    echo -e "\e[33mAUTHOR:\e[0m Sudhanshu Shekhar"
    echo -e "\e[33mEMAIL:\e[0m sudhanshu.shekhar@company.com"
    echo ""
    exit 0
}
# END OF FUNCTION
#==================================================

#==================================================
# Function: tool_version()
# Purpose: Tool version page display
tool_version()
{
    clear
    echo ""
    echo -e "\e[33mCurrent Version:\e[0m ${tool_version} \e[31m ${tool_scope} \e[0m"
    echo ""
    echo -e "\e[33mChange History:\e[0m"
    echo "  Jan 10, 2020, version 0.0, Initial thought flow and development, basic version on scribe."
    echo "  Jan 13, 2020, version 0.1, Incremented with application monitoring & Java & SCS checks."
    echo "  Jan 14, 2020, Version 0.2, Added logging, emailing & mailreceiver logic."
    echo "  Jan 14, 2020, Version 0.2, Added logging, emailing & mailreceiver logic."
    echo "  Jan 21, 2020, Version 0.3, Tested for adhoc executions in various SSO systems."
    echo "  Jan 22, 2020, Version 0.4, Tested for cron executions in various SSO systems."
    echo "  Jan 23, 2020, Version 1.0, Released & deployed in various SSO systems."
    echo ""
    echo ""
    echo -e "\e[33mAUTHOR:\e[0m Sudhanshu Shekhar"
    echo -e "\e[33mEMAIL:\e[0m sudhanshu.shekhar@company.com"
    echo ""
    exit 0
}
# END OF FUNCTION
#==================================================

#==================================================
# Function: tool_info()
# Purpose: Tool information page display
tool_info()
{
    clear
    echo ""
    echo -e "\e[33mCurrent Version:\e[0m ${tool_version} \e[31m ${tool_scope} \e[0m"
    tool_help
    exit 0
}
# END OF FUNCTION
#==================================================

#==================================================
# Function: tool_input_check()
# Purpose: Tool input check
tool_input_check()
{
clear
echo ""
echo "Performing input check @ `date` for ${TOOL_NAME}, Number of inputs passed is ${NUMBER_INPUTS}." > ${LOGGER}

# Check input values
if [ "${NUMBER_INPUTS}" == 4 ] ; then
  java_server_status

else
  echo -e "\e[31m\e[5mError Detected::\e[0m Check the inputs/arguments provided to the tool & retry. Refer to the help below -"
  tool_help
fi
}
# END OF FUNCTION
#==================================================

#==================================================
# Function: webdisp_check()
# Purpose: Check the webdispatcher
webdisp_check()
{
  echo ""
  echo ""
  echo "Running webdisp_check function & my sapcontrol is ${SAPCONTROL}" >> ${LOGGER}
  # Source environment variables in the shell
  echo "Sourcing environment variables for the execution of webdisp_check function now."  >> ${LOGGER}
  . /home/`whoami`/.sapenv_`hostname`.csh
  
      #Check webdispatcher current status
      ps -ef | grep "wd.sap${WEBSID}_W${WEBNUM}" | grep ${WEBSID} | grep -v sapstartsrv | grep -v $TOOL_NAME | grep -v grep > /tmp/sapwebdisp.process
      #If this file has > (greater than) zero length, then quit else restart the webdispatcher

       if [ -s /tmp/sapwebdisp.process ]
       then
          echo "Info:: Java server, SSO applications & SAP Web Dispatcher are already running, i have checked at `date`"  |& tee -a ${LOGGER}
          echo "Info:: Everything looks good, Goodbye from WebWatch for now."  |& tee -a ${LOGGER}
          rm -f /tmp/sapwebdisp.process
          exit 0
       else
          echo "Info:: SAP Web Dispatcher was found dead on `hostname -f`, i have checked at `date`"  |& tee -a ${LOGGER}
          echo "Info:: Let me bring it back to life -->"  |& tee -a ${LOGGER}
          echo ""
          echo ""
          echo "Info:: Cleaning up any residual webdisp related processes."  |& tee -a ${LOGGER}
          rm -f /tmp/sapwebdisp.process

          echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StopSystem"  |& tee -a ${LOGGER}
          ${SAPCONTROL} -nr $WEBNUM -function StopSystem  |& tee -a ${LOGGER}
          echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StopService"  |& tee -a ${LOGGER}
          ${SAPCONTROL} -nr $WEBNUM -function StopService  |& tee -a ${LOGGER}
          echo "Info:: Running /usr/sap/${WEBSID}/SYS/exe/run/cleanipc $WEBNUM remove"  |& tee -a ${LOGGER}
          /usr/sap/${WEBSID}/SYS/exe/run/cleanipc $WEBNUM remove  |& tee -a ${LOGGER}

          echo ".."  |& tee -a ${LOGGER}
          echo "...."  |& tee -a ${LOGGER}
          echo "......"  |& tee -a ${LOGGER}
          echo "........"  |& tee -a ${LOGGER}

          echo "Info:: Cleanup has completed, let me bring up the webdisp processes now - "  |& tee -a ${LOGGER}
          #/usr/sap/$WEBSID/SYS/exe/run/startsap r3
          sleep 45
          echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StartService" ${WEBSID}  |& tee -a ${LOGGER}
          ${SAPCONTROL} -nr $WEBNUM -function StartService ${WEBSID}  |& tee -a ${LOGGER}
          sleep 45
          echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StartSystem"  |& tee -a ${LOGGER}
          ${SAPCONTROL} -nr $WEBNUM -function StartSystem  |& tee -a ${LOGGER}
          sleep 45
          echo "Info:: New webdisp process is - "  |& tee -a ${LOGGER}
          echo "Info:: `ps -ef | grep "wd.sap${WEBSID}_W${WEBNUM}" | grep ${WEBSID} | grep -v sapstartsrv | grep -v $TOOL_NAME | grep -v grep` "  |& tee -a ${LOGGER}

          ps -ef | grep "wd.sap${WEBSID}_W${WEBNUM}" | grep ${WEBSID} | grep -v sapstartsrv | grep -v $TOOL_NAME | grep -v grep > /tmp/sapwebdisp.process
                if [ -s /tmp/sapwebdisp.process ]
                then
                echo "Info:: SAP Web Dispatcher has been started now on `hostname -f`."  |& tee -a ${LOGGER}
                echo ""
                echo ""
                echo "Info:: Support Contact - sudhanshu.shekhar@company.com" |& tee -a ${LOGGER}
                echo -e "\e[33mAlert::\e[0m Webdispatcher was found dead on `hostname -f`, Restart Done." | mailx -s "Webdispatcher Was Dead on `hostname -f`, Restart Done." ${MAILER} < ${LOGGER}
                rm -f /tmp/sapwebdisp.process

                fi
          exit 0
       fi
}
# END OF FUNCTION
#==================================================

#==================================================
# Function: java_server_status()
# Purpose: Check the status of the Java server processes
java_server_status()
{
clear
echo ""
echo "My sapcontrol is ${SAPCONTROL}" > ${LOGGER}
# Source environment variables in the shell
  echo "Sourcing environment variables for the execution of java_server_status function now."  >> ${LOGGER}
  . /home/`whoami`/.sapenv_`hostname`.csh
  
#Set variables for finding out the java process status
    sidadm="$(echo $WEBSID | tr '[A-Z]' '[a-z]')adm"

    # SCS Processes
    ms_proc=$( ps -ef |grep ms.sap${SAPSID} | grep -v grep | wc -l)
    en_proc=$( ps -ef |grep en.sap${SAPSID} | grep -v grep | wc -l)
    gw_proc=$( ps -ef |grep gw.sap${SAPSID} | grep -v grep | wc -l)

    # Java Instance Processes
    ig_proc=$( ps -ef |grep ig.sap${SAPSID} | wc -l)
    dw_proc=$( ps -ef |grep dw.sap${SAPSID} | wc -l)
    jc_proc=$( ps -ef |grep jc.sap${SAPSID} | wc -l)

    icm_proc=$( ps -ef |grep J${JAVANUM} | grep icm | grep -v grep | wc -l)
    icm_proc_id=$( ps -ef |grep J${JAVANUM} | grep icm | grep -v grep | awk '{print $2}')
    #icm_proc_id_sapcontrol=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetProcessList | grep -i "J2EE_RUNNING, Running" | grep -i ICM | awk '{print $3}'| rev | cut -c 2- | rev)
    icm_proc_id_sapcontrol=$( ${SAPCONTROL} -nr 00 -function J2EEGetProcessList | grep -i "J2EE_RUNNING, Running" | grep -i ICM | awk '{print $3}'| rev | cut -c 2- | rev)
    jstart_proc=$( ps -ef |grep J${JAVANUM} | grep jstart | grep -v grep | wc -l)
    jstart_proc_id=$( ps -ef |grep J${JAVANUM} | grep jstart | grep -v grep | awk '{print $2}')
    jstart_proc_id_sapcontrol=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetProcessList | grep -i "J2EE_RUNNING, Running" | grep -i server0 | awk '{print $3}'| rev | cut -c 2- | rev)


    #/usr/sap/WEB/SYS/exe/uc/linuxx86_64/sapcontrol -nr ${4} -function J2EEGetProcessList | grep -i "J2EE_RUNNING, Running" | grep -i ICM | awk '{print $3}'| rev | cut -c 2- | rev > /tmp/icmpid
    #/usr/sap/WEB/SYS/exe/uc/linuxx86_64/sapcontrol -nr 00 -function J2EEGetProcessList | grep -i "J2EE_RUNNING, Running" | grep -i ICM | awk '{print $3}'| rev | cut -c 2- | rev > /tmp/icmpid
    #icm_proc_id_sapcontrol=`cat /tmp/icmpid`


#Set variables for finding out SLS process status
    sls_status=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "SecureLoginServer" | awk '{print $(NF)}')
    sls_colour=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "SecureLoginServer" | awk '{print $(NF-2)}' | rev | cut -c 2- | rev)
    slui_status=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "securelogin.ui," | awk '{print $(NF)}')
    slui_colour=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "securelogin.ui," | awk '{print $(NF-2)}' | rev | cut -c 2- | rev)
    sluialias_status=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "securelogin.ui.alias" | awk '{print $(NF)}')
    sluialias_colour=$( ${SAPCONTROL} -nr ${JAVANUM} -function J2EEGetComponentList | grep -i "securelogin.ui.alias" | awk '{print $(NF-2)}' | rev | cut -c 2- | rev)

#Find Out if Java instance processes are running
if  [ ${dw_proc} -ge 5 ]  || [  ${jc_proc} -ge 2 ] && [ ${ig_proc} -ge 2 ] && [ ${icm_proc} -ge 1 ] && [ ${jstart_proc} -ge 1 ]
then 
    echo "Info:: Accessing sapcontrol at ${SAPCONTROL}."  |& tee -a ${LOGGER}
    echo "Info:: ICM process id from ps is - ${icm_proc_id}." |& tee -a ${LOGGER}
    echo "Info:: jstart process id from ps is - ${jstart_proc_id}." |& tee -a ${LOGGER}
    echo "Info:: ICM process id from sapcontrol is - ${icm_proc_id_sapcontrol}." |& tee -a ${LOGGER}
    echo "Info:: jstart process id from sapcontrol is - ${jstart_proc_id_sapcontrol}." |& tee -a ${LOGGER}


    if  [ ${icm_proc_id} -eq ${icm_proc_id_sapcontrol} ]  && [  ${jstart_proc_id} -eq ${jstart_proc_id_sapcontrol} ]
    then
      echo "Info:: Java Instance Process IDs for ICM & server0 are matching in ps & sapcontrol results." |& tee -a ${LOGGER}
      echo "Info:: Java Instance Processes are running." |& tee -a ${LOGGER}

      javainst_colour="GREEN"

      #Find out if Secure Login Server processes are running
      if [ ${javainst_colour} == GREEN ]
      then
        if [[ ${sls_status} == running ]] && [[ ${sls_colour} == GREEN ]] && [[ ${slui_status} == running ]] && [[ ${slui_colour} == GREEN ]] && [[ ${sluialias_status} == running ]] && [[ ${sluialias_colour} == GREEN ]]
        then
          echo "Info:: SLS application SecureLoginServer is in ${sls_status} & ${sls_colour} status." |& tee -a ${LOGGER}  
          echo "Info:: SLS application securelogin.ui is in ${slui_status} & ${slui_colour} status." |& tee -a ${LOGGER}
          echo "Info:: SLS application securelogin.ui.alias is in ${sluialias_status} & ${sluialias_colour} status." |& tee -a ${LOGGER}
      
          #Lets perform the webdisp check now
          webdisp_check

        else
          echo "Info:: SLS application SecureLoginServer is in ${sls_status} & ${sls_colour} status." |& tee -a ${LOGGER}  
          echo "Info:: SLS application securelogin.ui is in ${slui_status} & ${slui_colour} status." |& tee -a ${LOGGER}
          echo "Info:: SLS application securelogin.ui.alias is in ${sluialias_status} & ${sluialias_colour} status." |& tee -a ${LOGGER} 

          #Lets kill the webdispatcher
          ps -ef | grep "wd.sap${WEBSID}_W${WEBNUM}" | grep ${WEBSID} | grep -v sapstartsrv | grep -v $TOOL_NAME | grep -v grep > /tmp/sapwebdisp.process
          #If this file has > (greater than) zero length, then quit. Else kill Webdispatcher

          if [ -s /tmp/sapwebdisp.process ]
          then
            echo "Info:: SAP Web Dispatcher is found running, i have checked at `date`"  |& tee -a ${LOGGER}
            echo "Info:: Since Java processes have issues or have been shutdown, we should keep the webdispatcher down as well, otherwise we will see load balancing errors for users."|& tee -a ${LOGGER}
            echo "Info:: Shutting down the webdispatcher now - " |& tee -a ${LOGGER}
            echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StopSystem"  |& tee -a ${LOGGER}
            ${SAPCONTROL} -nr $WEBNUM -function StopSystem  |& tee -a ${LOGGER}
            rm -f /tmp/sapwebdisp.process
            echo "Info:: Webdispatcher has been shut down successfully."  |& tee -a ${LOGGER}
          echo "Java Instance Processes & Secure Login Server have issues on the SSO system - `hostname -f`." | mailx -s "Alert:: Java instance is down, webdispatcher killed for SSO on `hostname -f`." ${MAILER} < ${LOGGER}
          exit 1
        fi

    fi
fi

      #Lets perform the webdisp check now
      #webdisp_check

    else
      echo "Info:: Java Instance Process IDs for ICM & server0 are not matching in ps & sapcontrol results." |& tee -a ${LOGGER}
      echo "Info:: Java Instance Processes have issues." |& tee -a ${LOGGER}
      javainst_colour="RED"

      #Lets kill the webdispatcher
      ps -ef | grep "wd.sap${WEBSID}_W${WEBNUM}" | grep ${WEBSID} | grep -v sapstartsrv | grep -v $TOOL_NAME | grep -v grep > /tmp/sapwebdisp.process
      #If this file has > (greater than) zero length, then quit. Else kill Webdispatcher

       if [ -s /tmp/sapwebdisp.process ]
       then
          echo "Info:: SAP Web Dispatcher was found running, i have checked at `date`"  |& tee -a ${LOGGER}
          echo "Info:: Since Java processes have issues or shutdown, we should keep the webdispatcher down as well, otherwise we will see load balancing errors for users."|& tee -a ${LOGGER}
          echo "Info:: Shutting down the webdispatcher now - " |& tee -a ${LOGGER}
          echo "Info:: Running ${SAPCONTROL} -nr $WEBNUM -function StopSystem"  |& tee -a ${LOGGER}
          ${SAPCONTROL} -nr $WEBNUM -function StopSystem  |& tee -a ${LOGGER}
          rm -f /tmp/sapwebdisp.process
          echo "Java Instance Processes have issues on the SSO system - `hostname -f`." | mailx -s "Alert:: Java instance is down, webdispatcher killed for SSO on `hostname -f`." ${MAILER} < ${LOGGER}
          exit 1
        fi
    fi
fi    

}
# END OF FUNCTION
#==================================================

#==================================================
#Main Body of the Tool

# Tool running options
case ${1} in
        -help)                   tool_help                                 ;;
        -usage)                  tool_help                                 ;;
        -version)                tool_version                              ;;
        -h)                      tool_help                                 ;;
        -v)                      tool_version                              ;;
        -u)                       tool_help                                ;;
        -i)                      tool_info                                 ;;
        -info)                   tool_info                                 ;; 
        *)                       tool_input_check                          ;;
esac
#End of Main Body of the Tool
#==================================================
