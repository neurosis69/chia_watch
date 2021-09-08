#!/bin/bash
#################
##Configuration##
#################
#Print after the 5th Signage Point without eligible checks
problematic_threshold=5
#Write short work proof after # of lines
report_threshold=1000
#Debug?
debug_mode="false"
#Report?
report_mode="true"
#Logfile Name
logfile_name="missing_eligibles_`date +%s`.out"

##################
##Initialization##
##################
report_count=0
overall_count=0
missing_eligibles="\n"
start_run=`date +%s`
count_signage=0
print_missing_eligibles_header="no"
print_it="no"
missing_times=0
first_time="yes"
print_missing_eligibles="no"

##################
##Argument Check##
##################
[[ $# -eq 0 ]] && 
{
	echo "Usage:             . ./check_missing_eligibles.sh <LOGFILENAME> <PATH>"
	echo ""
	echo "<LOGFILENAME>      can be debug.log, debug.log.1, debug.log.2, ... or 'all' to scan for all to scan through all debug.log.*"
	echo "<PATH>             absolute path to logfiles. Log Report is also written to this path."
	echo ""
	echo "Examples: "
	echo "                   . ./check_missing_eligibles.sh debug.log $PWD"
	echo "                   . ./check_missing_eligibles.sh all $PWD"
	echo "                   . ./check_missing_eligibles.sh debug.log.3 ~chia/.chia/mainnet/log"
} && return 9
[[ -z $1 ]] && echo "Argument missing. Enter debug.log as first parameter or all to scan all logfiles." && return 10
[[ -z $2 ]] && echo "Argument missing. Enter path to debug.log." && return 11
[[ $1 == "all" ]] && Logfiles=`ls -1tr debug.log*` || Logfiles=$1

########
##LOOP##
########
egrep -o '^.*plots were eligible for farming|^.*Finished signage point ..|^.*Finished sub slot ..' $2/$Logfiles | sed -E 's/\ .*INFO\ //g' | \
while read line ; do
	#Is Line Eligible or Signage?
	echo "$line" | egrep -q "plots were eligible for farming" && eligible="yes" || eligible="no"
	#When Signage, save line and count up, else reset
	[[ $eligible == "no" ]] && ((count_signage+=1)) && missing_eligibles+="${line}\n" || count_signage=0 
	#When threshold reached, prepare for printing
	[[ $count_signage -eq $problematic_threshold ]] && print_missing_eligibles_threshold="yes" #&& debug="true"
	#Print Header when printing
	[[ $eligible == "yes" && $print_missing_eligibles_threshold == "yes" ]] && print_missing_eligibles_header="yes"
	#Next Eligible found, print all missed signage points
	[[ $print_missing_eligibles == "yes" && $eligible == "yes" ]] && print_it="yes"
	#Reset missing_eligibles when they alternate as expected
	[[ $eligible == "no" && $print_it == "no" && $count_signage -eq 1 && $print_missing_eligibles == "no" ]] && missing_eligibles="\n"
	
	[[ $1 == "all" ]] &&
	{
		Current_Time=`echo $line|awk -F: '{lin = index($0,":");print substr($0,lin+1)}'|sed -E 's/\ .*//g'`
		Logfile=`echo $line|awk -F: '{print $1}'`
	} ||
	{
		Current_Time=`echo $line|sed -E 's/\ .*//g'`
		Logfile=$1
	}
	
	[[ $debug == "true" ]] && 
	{
		echo "Current Time: "$Current_Time
		echo "Logfile:      "$Logfile
		echo "Print it:     "$print_it 
		echo "Count SP:     "$count_signage
		echo "Eligible:     "$eligible
		echo "Print Thresh: "$print_missing_eligibles_threshold
		echo "Print Eli:    "$print_missing_eligibles
		echo "Print Head:   "$print_missing_eligibles_header
		#echo -e "Content:   $missing_eligibles"
	}
	#Print Header
	[[ $print_missing_eligibles_header == "yes" ]] && 
	{
		[[ $first_time == "yes" ]] &&
		{
			echo "-----------------------------------------------------------"		| tee -a $2/$logfile_name
			echo "###### SIGNAGE POINTS WITHOUT ELIGIBLE PLOT SCANS #########"		| tee -a $2/$logfile_name
			echo "-----------------------------------------------------------"		| tee -a $2/$logfile_name
			first_time="no"
		} ||
		{
			echo "-----------------------------------------------------------"		| tee -a $2/$logfile_name
		}
		print_missing_eligibles="yes"
		print_missing_eligibles_header="no"
		print_missing_eligibles_threshold="no"
		[[ $debug_mode == "true" ]] && debug="true"	
	}
	#Print all missed
	[[ $print_it == "yes" ]] && echo -e "$missing_eligibles" | tee -a $2/$logfile_name && missing_eligibles="\n" && print_missing_eligibles="no" && print_it="no" && debug="false" && ((missing_times+=1))
	#Print report
	[[ $report_mode == "true" && ($report_count -eq $report_threshold || "$report_count" = "0") ]] &&
	{
		runtime=$(($(date +%s)-$start_run))
		echo -e "------------------------------------------"
		echo -e "Logfile:              $Logfile"|col -h
		echo -e "Lines processed:      $overall_count"|col -h
		echo -e "Runtime:              $runtime"|col -h
		echo -e "Log Time processed:   $Current_Time"|col -h
		echo -e "------------------------------------------"
		report_count=0
	}
	((report_count+=1))
	((overall_count+=1))
done
