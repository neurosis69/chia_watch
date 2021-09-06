# chia_watch
For every signage point harvester should check if plots are eligible for farming.

Current harvester versions seem to get stuck after some time. Sometimes after a couple of hours, sometimes after a few days.

This little service checks for such occurrences and restarts chia if no plots were eligible for a certain amount of time.


# How it works

1) Check for reoccuring "plots were eligible" string in debug.log

2) If no string was found for $seconds_without_eligible_until_restart, then restart using "chia start farmer -r"

3) Write logfiles to default .chia log directory

    a) Restart Logfile
  
    b) Small Report every $seconds_until_write_report
  
4) Check if chia farmer was restarted manually by monitoring the existence of the pid from .chia/mainnet/run/chia_farmer.pid

    a) Wait until chia farmer is started again by checking for new file chia_farmer.pid and then continue 
  
# Installation

Copy chia_watch.sh to the chia farmer host.

Ensure ~chia/.chia/mainnet/log and ~chia/.chia/mainnet/run directories are readable/writable.

## Ubuntu

Copy chia_watch.service to /etc/systemd/system

Change path for parameter ExecStart to the location of chia_watch.sh.

systemctl daemon-reload

systemctl enable chia-watch.service

systemctl start chia-watch.service
