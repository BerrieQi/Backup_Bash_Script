VMware Backup Script
-----------------------------------------

Introduction:
There are two scripts which will perform backup for the directories of /home/username/ /opt/shares/ and /opt/vmware/vm/. The script needs the support of crontab to perform the schduled backup task.

Test:
Type in command line the following commands:
0 0 * * * {script directory}/dailybackup.sh
0 1 * * 1 {script directory}/weeklybackup.sh

Attention:
Recommend to run in root privilege 
##Use With cron			#refer:github.com/Pricetx/backup
If you're running this script from cron, make sure you add the following line to the top of your crontab:
`PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin`

Refer:
github.com
help.ubuntu.com
dar.linux.free.fr

Peiyuan Qi 2016
