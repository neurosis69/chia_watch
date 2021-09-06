#!/bin/bash
#initialize variables until first eligible
seconds_without_eligible_until_restart="90"
#seconds_until_write_report="900"
seconds_until_write_report="300"
last_eligible=`date +%s`
seconds_since_last_eligible="0"
last_report=`date +%s`
seconds_since_last_report="0"
eligible_interval_count="0"
farmer_restart_active="no"

#path/files
chia_logdir=~chia/.chia/mainnet/log
chia_rundir=~chia/.chia/mainnet/run
chia_blockchain=~chia/chia-blockchain
restartlog=restart_triggered_by_eligible_time.out
reportlog=watchlog_report.out

#cleanup
[ -f $chia_logdir/trigger.restart ] && rm $chia_logdir/trigger.restart

#assign current farmer pid
current_farmer_pid=`cat $chia_rundir/chia_farmer.pid`

#LOOP
tail -Fn0 $chia_logdir/debug.log | \
while read line ; do
                #Check for eligible plots
                if [ $farmer_restart_active = "no" ]
                then
                        #check for eligible plots and assign current timestamp
                        echo "$line" | grep -q "plots were eligible" && last_eligible=`date +%s` && ((eligible_interval_count+=1))
                        #calculate seconds since last eligible timestamp
                        seconds_since_last_eligible=$(($(date +%s)-$last_eligible))
                #Check for eligible plots during restart
                elif [ $farmer_restart_active = "yes" ]
                then
                        echo "$line" | grep -q "plots were eligible" && last_eligible=`date +%s` && farmer_restart_active="no" && ((eligible_interval_count+=1))
                        if [ $farmer_restart_active = "no" ]
                        then
                                #TEST
                                #echo "$line"                                                                                                                   | tee -a $chia_logdir/$restartlog
                                echo "Restart finished: $(date +%Y-%m-%d_%H-%M-%S)"                                             | tee -a $chia_logdir/$restartlog
                                #add connection to local full node
                                #chia show -a 192.168.1.164:8444                                                                 | tee -a $chia_logdir/$restartlog
                                #assign new farmer pid
                                current_farmer_pid=`cat $chia_rundir/chia_farmer.pid`
                                echo "#++++++++++++++++++++++++++++++++++++#"                                                   | tee -a $chia_logdir/$restartlog
                        fi
                fi
                #TEST:trigger.restart for testing purpose
                #Check if no eligible plots were found in expected timeframe
                if [ "$seconds_since_last_eligible" -gt "$seconds_without_eligible_until_restart" ] && ps -p $current_farmer_pid > /dev/null || [ -f $chia_logdir/trigger.restart ]
                then
                        . $chia_blockchain/activate
                        echo "#------------------------------------#"                                                           | tee -a $chia_logdir/$restartlog
                        echo "#Triggering restart#"                                                                             | tee -a $chia_logdir/$restartlog
                        echo "Reason: eligible threshold reached"                                                               | tee -a $chia_logdir/$restartlog
                        echo "Seconds since last eligible: $seconds_since_last_eligible"                                        | tee -a $chia_logdir/$restartlog
                        echo "Restart Threshold(seconds): $seconds_without_eligible_until_restart"                              | tee -a $chia_logdir/$restartlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $chia_logdir/$restartlog
                        echo "Restart triggered: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $chia_logdir/$restartlog
                        chia start farmer -r                                                                                    | tee -a $chia_logdir/$restartlog
                        farmer_restart_active="yes"
                        seconds_since_last_eligible="0"
                        current_farmer_pid=`cat $chia_rundir/chia_farmer.pid`
                        #TEST
                        #trigger.restart for testing purpose
                        rm $chia_logdir/trigger.restart
                #Farmer Restart not triggered by watch
                elif ! ps -p $current_farmer_pid > /dev/null && [ $farmer_restart_active = "no" ]
                then
                        echo "#------------------------------------#"                                                           | tee -a $chia_logdir/$restartlog
                        echo "#No farmer pid detected#"                                                                         | tee -a $chia_logdir/$restartlog
                        echo "#Farmer was probably stopped manually#"                                                           | tee -a $chia_logdir/$restartlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $chia_logdir/$restartlog
                        echo "Downtime detected: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $chia_logdir/$restartlog
                        farmer_restart_active="yes"
                        seconds_since_last_eligible="0"
                        when_downtime_detected=$(date +%s)
                        # Wait until chia farmer is started again
                        while [ ! -f $chia_rundir/chia_farmer.pid ]; do
                                sleep 30
                                time_waited=$(($(date +%s)-$when_downtime_detected))
                                echo "Waited for farmer restart: $time_waited seconds"                                          | tee -a $chia_logdir/$restartlog
                        done
                        echo "Startup was triggered, waiting for plots to be loaded."                                           | tee -a $chia_logdir/$restartlog
                fi
                #TEST
                #echo $seconds_since_last_eligible
                seconds_since_last_report=$(($(date +%s)-$last_report))
                #echo $seconds_since_last_report
                if [ "$seconds_since_last_report" -gt "$seconds_until_write_report" ] && [ $farmer_restart_active = "no" ]
                then
                        . $chia_blockchain/activate
                        echo "#------------------------------------#"                                                           | tee -a $chia_logdir/$reportlog
                        echo "#Report of last $seconds_since_last_report seconds #"                                             | tee -a $chia_logdir/$reportlog
                        echo "Seconds since last eligible: $seconds_since_last_eligible"                                        | tee -a $chia_logdir/$reportlog
                        echo "Unix Timestamp: $(date +%s)"                                                                      | tee -a $chia_logdir/$reportlog
                        echo "Current Timestamp: $(date +%Y-%m-%d_%H-%M-%S)"                                                    | tee -a $chia_logdir/$reportlog
                        echo "Checked for eligible plots: $eligible_interval_count times"                                       | tee -a $chia_logdir/$reportlog
                        last_report=`date +%s`
                        eligible_interval_count="0"
                        seconds_since_last_report="0"
                fi
                #Write summary of signage points to logfile
done
