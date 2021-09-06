# chia_watch
For every signage point harvester should check if plots are eligible for farming.
Current harvester versions seem to get stuck after some time. Sometimes after a couple of hours, sometimes after a few days.



# How it works
-) Check for reoccuring "plots were eligible" string in debug.log
-) If no string was found for $seconds_without_eligible_until_restart, then restart using "chia start farmer -r"
-) Write logfiles to default .chia log directory
  .) Restart Logfile
  .) Small Report every $seconds_until_write_report
-) Check if chia farmer was restarted manually by monitoring the existence of the pid from .chia/mainnet/run/chia_farmer.pid
  .) Wait until chia farmer is started again by checking for new file chia_farmer.pid and then continue 
  
# Installation
Copy chia_watch.sh to host and ensure ~chia/.chia/mainnet/log and ~chia/.chia/mainnet/run directories are readable/writable.

Ubuntu:
Copy chia_watch.service to /etc/systemd/system
systemctl daemon-reload
systemctl enable chia-watch.service
systemctl start chia-watch.service
