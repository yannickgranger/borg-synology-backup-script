#!/bin/bash

# Read the .env file
set -o allexport
source .env
set +o allexport

# Define directory list file
DIR_LIST="directories.txt"

while IFS= read -r DIR; do

  BACKUP_SOURCE="$DIR"
  DIR_NAME="${DIR##*/}"

  # Define Borg repository on Synology NAS
  BORG_REPO="$BORG_USER@${BORG_IP}:/volume1/backup/${DIR_NAME}"

  # Optional: Set backup exclusion patterns (one per line)
  BACKUP_EXCLUDE=(
    $DIR/.Trash-1000
  )

  # Optional: Set Borg encryption password (store securely!)
  # BORG_PASSWORD=""
  # Check if remote repository exists
  echo "Running borg info for directory ${DIR}:";
  borg info --remote-path=/usr/local/bin/borg "$BORG_REPO" 2>> borg_backup.log  # Log standard error to borg_backup.log

  # Check exit code of borg info
  if [[ $? -eq 0 ]]; then
    echo "Borg repository exists."
  else
    echo "Borg repository not found. Creating..."
    borg init --remote-path=/usr/local/bin/borg --encryption=none "$BORG_REPO" 2>> borg_backup.log  # Log standard error
  fi


  # Initiate backup process
  echo "Start backup of ${DIR_NAME} at $(date +%Y-%m-%d-%H:%M:%S)";
  borg create --remote-path=/usr/local/bin/borg --verbose --stats -C zstd,20 --exclude=${BACKUP_EXCLUDE[@]} \
    "$BORG_REPO::{hostname}_backup_${DIR_NAME}_$(date +%Y-%m-%d-%H_%M_%S)" "$BACKUP_SOURCE" 2>> borg_backup.log  # Log standard error
  if [[ $? -eq 0 ]]; then
    echo "Backup of ${DIR_NAME} completed successfully!"
  else
    echo "Backup of ${DIR_NAME} failed! Check Borg logs for details."
    exit 1
  fi

  # Verify the newly created archive (optional)
  echo "Verifying backup of ${DIR_NAME} ... ";
  borg verify "$BORG_REPO::{hostname}_backup_${DIR_NAME}_$(date +%Y-%m-%d-%H_%I_%S)" 2>> borg_backup.log

  if [[ $? -ne 0 ]]; then
    echo "Borg verification failed!" >> borg_backup.log
    # Handle verification failure (e.g., retry verification, notify admin)
  fi

  # Prune older backups (keep only 3)
  borg prune --remote-path=/usr/local/bin/borg -v --keep-daily=${KEEP_DAILY} --keep-weekly=${KEEP_WEEKLY} --keep-monthly=${KEEP_MONTHLY} "$BORG_REPO" 2>> borg_backup.log  # Log standard error
  echo "Borg backup script execution complete."

done < "$DIR_LIST"
