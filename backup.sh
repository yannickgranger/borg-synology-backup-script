#!/bin/bash

# Define directory list file
DIR_LIST="directories.txt"

while IFS= read -r DIR; do

  BACKUP_SOURCE="$DIR"
  DIR_NAME="${DIR##*/}"

  # Define Borg repository on Synology NAS
  BORG_REPO="yg@192.168.1.2:/volume1/backup/${DIR_NAME}"

  # Optional: Set backup exclusion patterns (one per line)
  BACKUP_EXCLUDE=(
   /DATA/${DIR_NAME}/.Trash-1000
  )
  # Optional: Set Borg encryption password (store securely!)
  # BORG_PASSWORD=""
  # Check if remote repository exists
  "Running borg info for directory ${DIR}:"
  borg info --remote-path=/usr/local/bin/borg "$BORG_REPO" 2>> borg_backup.log  # Log standard error to borg_backup.log

  # Check exit code of borg info
  if [[ $? -eq 0 ]]; then
    echo "Borg repository exists."
  else
    echo "Borg repository not found. Creating..."
    borg init --remote-path=/usr/local/bin/borg --encryption=none "$BORG_REPO" 2>> borg_backup.log  # Log standard error
  fi
  # Prune older backups (optional, adjust these values)
  # KEEP_DAILY=7
  # KEEP_WEEKLY=4
  # KEEP_MONTHLY=6
  # Initiate backup process
  borg create --remote-path=/usr/local/bin/borg --verbose --stats -C zstd,20 --exclude=${BACKUP_EXCLUDE[@]} \
    "$BORG_REPO::{hostname}_backup_${DIR_NAME}_$(date +%Y-%m-%d-%H_%I_%S)" "$BACKUP_SOURCE" 2>> borg_backup.log  # Log standard error
  if [[ $? -eq 0 ]]; then
    echo "Backup completed successfully!"
  else
    echo "Backup failed! Check Borg logs for details."
    exit 1
  fi
  # Prune older backups (keep only 3)
  borg prune --remote-path=/usr/local/bin/borg -v --keep-daily=3 --keep-weekly=0 --keep-monthly=0 "$BORG_REPO" 2>> borg_backup.log  # Log standard error
  echo "Borg backup script execution complete."

done < "$DIR_LIST"


