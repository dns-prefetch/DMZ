---
<img src="https://dns-prefetch.github.io/assets/logos/dmz-header-2.svg" width="100%" height="10%">

# ORB (Oracle RMAN Backup)

Bash wrapper script that sits between Linux CRON and RMAN to execute backups, weekly tidy, with a 30 day backup retention window.  Backups are configured to  write to Cloud storage mounted on the host (default script variable rman_disk_folder=/mnt/orabackup).

  - Use cases
    - Oracle database single instance RMAN backups
    - Oracle RAC database backups
    - Oracle Data Guard database backups.  (The archive deletion policy requires backup of the standby databases.)
    - Weekly backups (incremental level 0) plus archive log
    - Daily backups (incremental level 1) plus archive log
    - Archive log backups seperate from the weekly and daily backups
    - Tidy operations to remove log files over 30 days old
    - Backup retension period is 30 days
    - Backup destination modified by adjusting global variable: rman_disk_folder

<p align="center">
<img src="sample_output/sample.png" alt="Sample Output" title="orb help and installed files" />
</p>


# Single Instance host instructions

## Download orb.sh
  * wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh
  * curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh > orb.sh

## Mount NAS to /mnt/orabackup

  Create your NAS partition, and mount onto the database server, and grant the database owner (oracle) read/write permission.

  > [!NOTE]
  > This is the default backup folder, you can use any folder path that meets your requirements, but remember to update the variable reference in the script configuration section.

## Install ORB

  Execute the orb installation task to create the installation folders, activity files, and copy the orb.sh script into the folder structure.

    orb.sh install

  The default configurable location (default \~/orb) is modified by editing orb.sh and modify folder_top to your preference (typeset folder_top=~/orb).

## Configure a database backup

  Orb connects to the database using RMAN, configures RMAN, and create the database specific folder under /mnt/orabackup

    ~/orb/bin/orb.sh config MySID

Also, config suggests a set of crontab entries for the database backup.

    @hourly           /home/oracle/orb/bin/orb.sh archive MySID     # Backup the archivelogs every hour
    15 01 * * mon-sat /home/oracle/orb/bin/orb.sh daily   MySID     # Backup the database incremental level 1 and archivelog Monday-Saturday at 01:15
    15 01 * * sun     /home/oracle/orb/bin/orb.sh weekly  MySID     # Backup the database incremental level 0 and archivelog on Sunday at 01:15
    30 01 1 * sun     /home/oracle/orb/bin/orb.sh tidy    MySID     # Remove expired backups, archivelog, and orb backup logs weekly on Sunday at 01:30

  > [!NOTE]
  > Add crontab entries to automated the backup schedule.

## Test Test Test

  Manually run each of the backup tasks in this order

  1. weekly
  1. daily
  1. archive
  1. tidy

  Then review the generated sets of files

  1. Scan the database backup files:

    find /mnt/orabackup

  2. Scan the log files for interesting messages

    grep FAIL: ~/orb/log/*
    grep WARN: ~/orb/log/*
    grep INFO: ~/orb/log/*

# Data Guard primary and standby host instructions

  The Data Guard host installations are broadly similar to the single installation setup, with he differences being reasonably simple to manage.  The installation pattern we follow should make sense if you have managed a Data Guard site before:

  1. On the primary host
     - Mount NAS disk to /mnt/orabackup
     - Install Orb
     - Configure the database backup
     - Schedule the Orb weekly, daily, archive, and tidy actions with CRON (or your enterprise scheduler)
  1. Switchover to standby
     - Perform a Data Guard switchover of the primary role to the standby database
  1. On the standby host
     - Mount NAS disk to /mnt/orabackup (This should be the same NAS primary host partition shared with standby)
     - Install Orb
     - Configure the database backup
     - Schedule the Orb weekly, daily, archive, and tidy actions with CRON (or your enterprise scheduler)
  1. Switchover to primary
     - Perform a Data Guard switchover of the primary role to the primary database
  1. Finally, run the backup tests
     - weekly
     - daily
     - archive
     - tidy

  > [!NOTE]
  > Data Guard: **Orb requires that you backup the standby.**
  >   This is because the RMAN "CONFIGURE ARCHIVELOG DELETION POLICY" ensures archivelogs are applied ALL standbys and backed up on the primary.
  >   You are free to modify the "CONFIGURE ARCHIVELOG DELETION POLICY" to suite you requirements


## Download orb.sh

  * wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh
  * curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh > orb.sh

Example to download a raw script file directly using wget or curl

```
wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl.sql
curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl.sql > mcl.sql
```

## On the primary host

### Mount NAS to /mnt/orabackup

  Create your NAS partition, and mount onto the database server, and grant the database owner (oracle) read/write permission.

  > [!NOTE]
  > This is the default backup folder, you can use any folder path that meets your requirements, but remember to update the variable reference in the script configuration section.

  > It is not necessary to mount the same NAS partition to primary and standby.

  > Daily ORB incremental level 1 backups first crosscheck existing backup files and automatically perform an incremental level 0 if a full backup is not available.

### Install ORB

  Execute the orb installation task to create the installation folders, activity files, and copy the orb.sh script into the folder structure.

    orb.sh install

  The default configurable location (default \~/orb) is modified by editing orb.sh and modify folder_top to your preference (typeset folder_top=~/orb).

### Configure the database backup

  Orb connects to the database using RMAN, configures RMAN, and create the database specific folder under /mnt/orabackup

    ~/orb/bin/orb.sh config MySID

Also, config suggests a set of crontab entries for the database backup.

    @hourly           /home/oracle/orb/bin/orb.sh archive MySID     # Backup the archivelogs every hour
    15 01 * * mon-sat /home/oracle/orb/bin/orb.sh daily   MySID     # Backup the database incremental level 1 and archivelog Monday-Saturday at 01:15
    15 01 * * sun     /home/oracle/orb/bin/orb.sh weekly  MySID     # Backup the database incremental level 0 and archivelog on Sunday at 01:15
    30 01 1 * sun     /home/oracle/orb/bin/orb.sh tidy    MySID     # Remove expired backups, archivelog, and orb backup logs weekly on Sunday at 01:30

  > [!NOTE]
  > Add crontab entries to automated the backup schedule.

## Switchover to standby

  Switchover using your preferred method which should be Data Guard Manager (dgmgrl) but SQL*Plus is if you like to make your life unnecesarily complicated.

    dgmgrl
      connect sys/spiffingly23Complex56Password@$tnsalias as sysdba
      show configuration
      switchover to standby-name;
      show configuration

  > [!NOTE]
  > The spiffingly23Complex56Password password only exists as a documentation artefact.
  > In the real world, my passwords are never this complex and never involve multi-factor authentication (joke haha).

## On the standby host

### Mount NAS to /mnt/orabackup

  Create your NAS partition, and mount onto the database server, and grant the database owner (oracle) read/write permission.

> [!NOTE]
  > This is the default backup folder, you can use any folder path that meets your requirements, but remember to update the variable reference in the script configuration section.

  > It is not necessary to mount the same NAS partition to primary and standby.

  > Daily ORB incremental level 1 backups first crosscheck existing backup files and automatically perform an incremental level 0 if a full backup is not available.

### Install ORB

  Execute the orb installation task to create the installation folders, activity files, and copy the orb.sh script into the folder structure.

    orb.sh install

  The default configurable location (default \~/orb) is modified by editing orb.sh and modify folder_top to your preference (typeset folder_top=~/orb).

### Configure the database backup

  Orb connects to the database using RMAN, configures RMAN, and create the database specific folder under /mnt/orabackup

    ~/orb/bin/orb.sh config MySID

Also, config suggests a set of crontab entries for the database backup.

    @hourly           /home/oracle/orb/bin/orb.sh archive MySID     # Backup the archivelogs every hour
    15 01 * * mon-sat /home/oracle/orb/bin/orb.sh daily   MySID     # Backup the database incremental level 1 and archivelog Monday-Saturday at 01:15
    15 01 * * sun     /home/oracle/orb/bin/orb.sh weekly  MySID     # Backup the database incremental level 0 and archivelog on Sunday at 01:15
    30 01 1 * sun     /home/oracle/orb/bin/orb.sh tidy    MySID     # Remove expired backups, archivelog, and orb backup logs weekly on Sunday at 01:30

  > [!NOTE]
  > Add crontab entries to automated the backup schedule.


## Switchover to primary

  Switchover using your preferred method which should be Data Guard Manager (dgmgrl) but SQL*Plus is if you like to make your life unnecesarily complicated.

    dgmgrl
      connect sys/spiffingly23Complex56Password@$tnsalias as sysdba
      show configuration
      switchover to primary-name;
      show configuration

  > [!NOTE]
  > Please refer the the previous password security artefact notes.

## Test Test Test

  Manually run each of the backup tasks in this order

  1. weekly
  1. daily
  1. archive
  1. tidy

  The review the generated sets of file

  1. Scan the database backup files:

    find /mnt/orabackup

  2. Scan the log files for interesting messages

    grep FAIL: ~/orb/log/*
    grep WARN: ~/orb/log/*
    grep INFO: ~/orb/log/*


# And finally

"orb.sh help" is a good place to start, but a few hints follow...

| orb command           | Description                                    |
| --- | --- |
| orb.sh help           | Display help                                   |
| orb.sh config   MySID | Configure the database db21c for backups       |
| orb.sh archive  MySID | Backup the archivelogs for db21c               |
| orb.sh daily    MySID | Daily backup (incremental level 1) for db21c   |
| orb.sh weekly   MySID | Weekly backup (incremental level 0) for db21c  |
| orb.sh tidy     MySID | Remove logs files over 30 days old             |
| orb.sh review   MySID | List the backup summary for db21c              |

---
