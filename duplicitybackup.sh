#!/bin/bash
: '
/*
 *      Copyright (C) 2008-2013 Paul Rae
 *      http://www.paulrae.com
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  If not, see <http://www.gnu.org/licenses/>
 *
 *
 *  duplicitybackup.sh is a script for managaing duplicity backups.
 *  It provivides an easy mechanism for creating, backingup, restoring,
 *  deleting and uploading encrypted backups using duplicity and ncftp
 *
 */
'

########################################################
## BASE CONFIG OPTIONS                                ##
## All details must be configured                     ##
########################################################
FTP_USER=
FTP_PASS=
FTP_SERVER=
GPG=
LOGFILE=/tmp/duplicity.log
########################################################


########################################################
## BASE CONFIG OPTIONAL OPTIONS                       ##
## Set EMAIL to recieve backup error reports          ##
## Set LOGFILE location                               ##
########################################################
EMAIL=

########################################################
## DUPLICITY BACKUP LOCTIONS                          ##
## Enter locations to backup / exclude                ##
## Multiple directories supported, space seperated    ##
BACKUP_LOCATIONS="/home"
BACKUP_EXCLUDES=""
########################################################


########################################################
## DO NOT CHANGE ANYTHING BELOW THIS LINE             ##
########################################################

########################################################
## DUPLICITY VARS                                     ##
########################################################
FTP_FOLDER=`hostname -f`_duplicity
DUP_ARCHIVE=ftp://$FTP_USER@$FTP_SERVER/$FTP_FOLDER/
export PASSPHRASE=$GPG FTP_PASSWORD=$FTP_PASS
########################################################

# check if required options are set
[ -z "$FTP_USER" ] && { echo "You must set your FTP username - set this in the BASE CONFIG section"; exit 1; }
[ -z "$FTP_PASS" ] && { echo "You must set your FTP password - set this in the BASE CONFIG section"; exit 1; }
[ -z "$FTP_SERVER" ] && { echo "You must set your FTP server - set this in the BASE CONFIG section"; exit 1; }
[ -z "$GPG" ] && { echo "You must set your GPG passphrase - set this in the BASE CONFIG section"; exit 1; }
[ -z "$LOGFILE" ] && { echo "You must set your LOGFILE locationi - set this in the BASE CONFIG section"; exit 1; }

# check ncftp, duplicity  is installed
NCFTP=$(which ncftp)
DUP=$(which duplicity)
[ -z "$NCFTP" ] && { echo "ncftp doesn't appear to be installed - this is required for script to run"; exit 1; }
[ -z "$DUP" ] && { echo "duplicity doesn't appear to be installed - this is required for script to run"; exit 1; }


# create remote directory to upload backups toy
create() {
  ncftp -u$FTP_USER -p$FTP_PASSWORD ftp://$FTP_SERVER<<EOF
mkdir $FTP_FOLDER
quit
EOF
echo created $FTP_FOLDER on ftp://$FTP_SERVER
}

# duplicity backup
# creates full backup if older than 30 days, else does incremental backup
backup() {
  duplicity --full-if-older-than 30D $BACKUP_LOCATIONS $BACKUP_EXCLUDES $DUP_ARCHIVE > $LOGFILE

  if [ -n "$EMAIL" ]; then
    if grep -q "Errors 0" "$LOGFILE"; then
      echo "No errors on `hostname -f`"
    else
      mail -s "Duplicity Backup Errors on `hostname -f`" $EMAIL < $LOGFILE
    fi
  fi  
}

# restore duplicity backup
# file [time] destination
restore() {
  if [ $# = 2 ]; then
    duplicity restore --file-to-restore $1 $DUP_ARCHIVE $2
  else
    duplicity restore --file-to-restore $1 --time $2 $DUP_ARCHIVE $3
  fi
}

# list files backed up
list() {
  duplicity list-current-files $DUP_ARCHIVE
}

# check duplicity collection-stats
status() {
  duplicity collection-status $DUP_ARCHIVE
}

# show duplicity lastlog
log() {
  cat $LOGFILE
}

# cleanup and empty exported vars
empty() {
  export FTP_USER=
  export FTP_PASS=
  export FTP_SERVER=
  export GPG=
  export DUP_ARCHIVE=
  export PASSPHRASE=$GPG FTP_PASSWORD=$FTP_PASS  
}

# test ftp connection
testftp() {
  ncftp -u$FTP_USER -p$FTP_PASSWORD ftp://$FTP_SERVER<<EOF
cd $FTP_FOLDER
ls
quit
EOF
}

# verify duplicity backups
verify() {
  duplicity verify -v4 $DUP_ARCHIVE $BACKUP_LOCATIONS 
}

# delete duplicity backups
delete() {
  duplicity remove-older-than $1 --force $DUP_ARCHIVE 
}

# Main if/elif loop
if [ "$1" = "create" ]; then
  create
elif [ "$1" = "backup" ]; then
  backup
elif [ "$1" = "list" ]; then
  list
elif [ "$1" = "restore" ]; then
  if [ $# = 3 ]; then
    restore $2 $3
  else
    restore $2 $3 $4
  fi
elif [ "$1" = "status" ]; then
  status
elif [ "$1" = "log" ]; then
  log
elif [ "$1" = "testftp" ]; then
  testftp
elif [ "$1" = "verify" ]; then
  verify
elif [ "$1" = "delete" ]; then
  delete $2
else
  echo "
  duplicitybackup - a helper script to manage duplicity backups
  
  USAGE:
  
  ./duplicitybackup.sh create             - This will create a remote working directory for uploading backups
  ./duplicitybackup.sh backup             - This will backup your files and upload them to your remote server
  ./duplicitybackup.sh verify             - Verify duplicity backup and show changes
  ./duplicitybackup.sh restore file [time] destination
                                          - Restore files from your remote server  
                                          - You can optionally set the time of the file to restore
                                          - (check duplicty TIME FORMATS for options)
  ./duplicitybackup.sh delete time        - Delete backups older than [time]
  ./duplicitybackup.sh list               - List files in the most recent duplicity backup
  ./duplicitybackup.sh status             - List dupicity backup repository status
  ./duplicitybackup.sh log                - Display last duplicity log file
  ./duplicitybackup.sh testftp            - Test ftp connection and list directory contents

  I recommend that you run this script from a cronjob to ensure regular backups.
  To run this hourly, add the following cronjob:
  @hourly /path/to/script/backup-scripts/duplicitybackup.sh backup

  Further details and usage examplese at: wwww.paulrae.com
  Contact Paul Rae - paul@paurlae.com
  "
fi
 

## Cleanup
empty

