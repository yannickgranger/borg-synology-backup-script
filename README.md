# borg-synology-backup-script

This script is used to backup from a server to a synology nas
After proper setup of ssh keys from source to synology
Both source and synology nas must have borg installed

I found it more convenient to use a simple script and a cron than to rely on more complete
solutions, with more configuration.

[Reference for setup](https://soyuka.me/borg-backups-archlinux-synology/) 

To make the script work, simply fill the .env.local from .env with convenient values

BORG_USER=user-with-ssh-access-to-synology
BORG_IP=synology-ip

ex:
KEEP_DAILY=3
KEEP_WEEKLY=0
KEEP_MONTHLY=0

