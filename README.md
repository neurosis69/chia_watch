# chia_watch
For every signage point harvester should check if plots are eligible for farming.

Current harvester versions seem to get stuck after some time. Sometimes after a couple of hours, sometimes after a few days.

This little service checks for such occurrences and restarts chia if no plots were eligible for a certain amount of time.


## How it works

1) Check for reoccuring "plots were eligible" string in debug.log

2) If no string was found for $seconds_without_eligible_until_restart, then restart using "chia start farmer -r"

3) Write logfiles to default .chia log directory

    a) Restart Logfile
  
    b) Small Report every $seconds_until_write_report
  
4) Check if chia farmer was restarted manually by monitoring the existence of the pid from .chia/mainnet/run/chia_farmer.pid

    a) Wait until chia farmer is started again by checking for new file chia_farmer.pid and then continue 
  
## Installation

Copy chia_watch.sh to the chia farmer host.

Ensure ~chia/.chia/mainnet/log and ~chia/.chia/mainnet/run directories are readable/writable.

### Ubuntu - systemd

Copy chia_watch.service to /etc/systemd/system

Change path for parameter ExecStart to the location of chia_watch.sh.

Change parameter User to the osuser which should run the service.

systemctl daemon-reload

systemctl enable chia-watch.service

systemctl start chia-watch.service

# check_missing_eligibles.sh

Use this script to find out if there are missing proofs for signage points.

This could be caused by several reasons, e.g. if you have bad lookup times, delays caused by network lags or many other reasons.

Script is tested with Loglevel INFO.

Processing on a Raspberry Pi can be rather slow.

![grafik](https://user-images.githubusercontent.com/83925572/132508867-8801a061-2cab-40bf-b911-7828df5ae6c7.png)

## Assumption

After one signage point there should be a log entry stating, that chia is checking for Plots beeing eligible.

If there are $problematic_threshold consecutive signage points without an eligible entry, I assume there is a problem and report to $logfile_name.

## Usage

Usage              . ./check_missing_eligibles.sh <LOGFILENAME> <PATH>

<LOGFILENAME>      can be debug.log, debug.log.1, debug.log.2, ... or 'all' to scan for all to scan through all debug.log.*
<PATH>             absolute path to logfiles. Log Report is also written to this path.

Examples:
                   . ./check_missing_eligibles.sh debug.log /home/flax/.flax/mainnet/log
                   . ./check_missing_eligibles.sh all /home/flax/.flax/mainnet/log
                   . ./check_missing_eligibles.sh debug.log.3 ~chia/.chia/mainnet/log
