duplicitybackup.sh
==================

duplicitybackup.sh - a helper script to manage duplicity backups

duplicitybackup.sh's aim is to make using duplicity easier. It allows you to backup, verify, restore, delete, etc.. using duplicity and upload them to a remote ftp server.

To use duplicity.sh:

1. First setup the script. Edit the script and set:
   FTP_USER=FTP username i.e ftpuser
   FTP_PASS=FTP password i.e mypassword
   FTP_SERVER=FTP server hostname or ip address i.e myftpserver.com
   GPG=Your secret passphrase used to encrypt and decrypt backups i.e. T1hNMFY3ej6CGc572SFnuQoWtCL2ImyA
   LOGFILE=Log file location i.e. /tmp/duplicity log
2. If you want to recieve reports if there are errors, then set your EMAIL address. If you leave this blank, no reports will be sent. NOTE ONLY ERROR REPORTS ARE SENT.
   EMAIL=Your email address i.e username@mydomain.com
3. Set the files/directories to be included in your duplicity backups:
   BACKUP_LOCATIONS="/home"
4. Set any files/directories to be excluded from your duplicity backups:
   BACKUP_EXCLUDES=""
5. Before running the script, you need to create the required folder on your ftp server. To do this, run:
   ./duplicitybackup.sh create
6. You are ready to run your first backup. To do this run:
   ./duplicitybackup.sh backup
   (this may take a few minutes to a few hours depending on the size of your backup and network speed)
7. You can confirm your backup has been uploaded to the remote server by running:
   ./duplicitybackup.sh testftp   


I recommend running duplicitybackup.sh in a cronjob to ensure frequent incremental backups. To do this add something similar to the following in your crontab:
   
   @hourly /path/to/script/duplicitybackup.sh backup
   
  
./duplicitybackup.sh
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
