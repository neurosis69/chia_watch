#!/bin/bash
#################
##Configuration##
#################
#osuser
osuser=chia
#chia/flax/..
blockchain_name=chia
#Node Role: farmer/harvester
node_role=farmer
seconds_without_eligible_until_restart="90"
seconds_until_write_report="900"

#add local connections after restart
initiate_local_connects="yes"

#path/files
blockchain=`eval echo "~$osuser"/${blockchain_name}-blockchain`
logdir=`eval echo "~$osuser"/.${blockchain_name}/mainnet/log`
rundir=`eval echo "~$osuser"/.${blockchain_name}/mainnet/run`

#filenames
restartlog=restart_triggered_by_eligible_time.out
reportlog=watchlog_report.out

##################
##Initialization##
##################
last_eligible=`date +%s`
seconds_since_last_eligible="0"
last_report=`date +%s`
seconds_since_last_report="0"
eligible_interval_count="0"

#Parameter used to distinguish between restart or normal operation
restart_active="no"
#Parameter used to prevent buffered lines containing eligible string to be used
loading_plots="no"

#cleanup
[ -f $logdir/trigger.restart ] && rm $logdir/trigger.restart

#assign current $node_role pid
current_pid=`cat $rundir/${blockchain_name}_${node_role}.pid`

########
##LOOP##
########
tail -Fn0 $logdir/debug.log | \
while read line ; do
                #Check for eligible plots
                if [ $restart_active = "no" ]
                then
                        #check for eligible plots and assign current timestamp
                        echo "$line" | grep -q "plots were eligible" && last_eligible=`date +%s` && ((eligible_interval_count+=1))
                        #calculate seconds since last eligible timestamp
                        seconds_since_last_eligible=$(($(date +%s)-$last_eligible))
                #Check for eligible plots during restart
                elif [ $restart_active = "yes" ]
                then
                        if [ $loading_plots = "no" ]
                        then
                                echo $line | grep -q "Found plot" && loading_plots="yes"
                        elif [ $loading_plots = "yes" ]
                        then
                                echo "$line" | grep -q "plots were eligible" && last_eligible=`date +%s` && restart_active="no" && loading_plots="no" && ((eligible_interval_count+=1))
                        fi
                        #TEST
                        #echo $line | tee -a $logdir/$restartlog
                        if [ $restart_active = "no" ]
                        then
                                echo "Restart finished: $(date +%Y-%m-%d_%H-%M-%S)"                                             | tee -a $logdir/$restartlog
                                if [ $initiate_local_connects = "yes" ]
                                then
                                        #wait some seconds so full node can be fully started before initiating local connection
                                        #can in future be checked by string "registered for service chia_full_node"
                                        sleep 30
                                        #add connection to local full node
                                        $blockchain_name show -a 192.168.1.164:8444                                             | tee -a $logdir/$restartlog
                                fi
                                #assign new $node_role pid
                                current_pid=`cat $rundir/${blockchain_name}_${node_role}.pid`
                                echo "#++++++++++++++++++++++++++++++++++++#"                                                   | tee -a $logdir/$restartlog
                        fi
                fi
                #TEST:trigger.restart for testing purpose
                #Check if no eligible plots were found in expected timeframe
                if [ "$seconds_since_last_eligible" -gt "$seconds_without_eligible_until_restart" ] && ps -p $current_pid > /dev/null || [ -f $logdir/trigger.restart ]
                then
                        . $blockchain/activate
                        echo "#------------------------------------#"                                                           | tee -a $logdir/$restartlog
                        echo "#Triggering restart#"                                                                             | tee -a $logdir/$restartlog
                        echo "Reason: eligible threshold reached"                                                               | tee -a $logdir/$restartlog
                        echo "Seconds since last eligible: $seconds_since_last_eligible"                                        | tee -a $logdir/$restartlog
                        echo "Restart Threshold(seconds): $seconds_without_eligible_until_restart"                              | tee -a $logdir/$restartlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $logdir/$restartlog
                        echo "Restart triggered: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $logdir/$restartlog
                        $blockchain_name start $node_role -r                                                                    | tee -a $logdir/$restartlog
                        echo "Startup was triggered, waiting for plots to be loaded."                                           | tee -a $logdir/$restartlog
                        restart_active="yes"
                        seconds_since_last_eligible="0"
                        current_pid=`cat $rundir/${blockchain_name}_${node_role}.pid`
                        #TEST
                        rm $logdir/trigger.restart
                #Farmer Restart not triggered by watch
                elif ! ps -p $current_pid > /dev/null && [ $restart_active = "no" ]
                then
                        echo "#------------------------------------#"                                                           | tee -a $logdir/$restartlog
                        echo "#No $node_role pid detected#"                                                                     | tee -a $logdir/$restartlog
                        echo "#Farmer was probably stopped manually#"                                                           | tee -a $logdir/$restartlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $logdir/$restartlog
                        echo "Downtime detected: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $logdir/$restartlog
                        restart_active="yes"
                        seconds_since_last_eligible="0"
                        when_downtime_detected=$(date +%s)
                        # Wait until $blockchain_name $node_role is started again
                        while [ ! -f $rundir/${blockchain_name}_${node_role}.pid ]; do
                                sleep 30
                                time_waited=$(($(date +%s)-$when_downtime_detected))
                                echo "Waited for $node_role restart: $time_waited seconds"                                      | tee -a $logdir/$restartlog
                        done
                        echo "Startup was triggered, waiting for plots to be loaded."                                           | tee -a $logdir/$restartlog
                fi
                seconds_since_last_report=$(($(date +%s)-$last_report))
                #TEST
                #echo $seconds_since_last_eligible
                #echo $seconds_since_last_report
                if [ "$seconds_since_last_report" -gt "$seconds_until_write_report" ] && [ $restart_active = "no" ]
                then
                        . $blockchain/activate
                        echo "#------------------------------------#"                                                           | tee -a $logdir/$reportlog
                        echo "#Report of last $seconds_since_last_report seconds #"                                             | tee -a $logdir/$reportlog
                        echo "Seconds since last eligible: $seconds_since_last_eligible"                                        | tee -a $logdir/$reportlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $logdir/$reportlog
                        echo "Current Timestamp: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $logdir/$reportlog
                        echo "Checked for eligible plots: $eligible_interval_count times"                                       | tee -a $logdir/$reportlog
                        last_report=`date +%s`
                        eligible_interval_count="0"
                        seconds_since_last_report="0"
                fi
done
