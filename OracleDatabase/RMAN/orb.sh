#!/bin/bash
#
# Author:         Michael Hartley
# Date:           15/07/2022 15:35:21
# Synopsis:       Oracle RMAN Backup (orb) for Azure Files (This is a backup to disk installation)
# Usage:
#                 orb.sh install          Install orb, create folders, and files
#                 orb.sh config dbsid     Configure RMAN for database dbsid
#                 orb.sh weekly dbsid     Run weekly level 0 backup for database
#                 orb.sh daily dbsid      Run daily level 1 backup for database
#                 orb.sh tidy dbsid       Remove expired backups, archivelogs, and log files
#
# Modifications:  18/07/2022 12:22:13 MH Added disk backup destination
#                 14/09/2022 12:22:44 MH Update tidy - add missing log files to list
#                 14/09/2022 15:37:25 MH Update rman_run - removed reference to log_syslog
#                 14/09/2022 18:39:06 MH Update config - use db_name when creating backup folder path
#                 14/09/2022 18:39:01 MH Update config - fixed example crontab syntax
#                 14/09/2022 18:38:55 MH Update main - add oraenv to path for crontab execution
#
# ToDo
#                 18/07/2022 12:26:08 MH extend to handle RAC
#                 18/07/2022 12:26:08 MH extend to handle Data Guard physical standby
#                 20/07/2022 14:56:09 MH Started added restore and recovery notes

function help { # Help

if [ $# -ne 1 ]; then
  clear
else
  clear
  echo +---------------------------------------------
  echo Error: ${1}
  echo +---------------------------------------------
fi

log_title "${g_application_title}"

fn=$(which ${PROG_NAME})

grep function $fn | grep -vE "functions|check|log_|no-help-output" | sort | awk '{printf("%-30s - %-10s ", $2, $5); for(i=6;i<=NF;i++) printf("%s ",$i); print ""}'

echo -e "\n"
echo ORB is installed to the following folders and files
echo -e "\n"

echo "Installation orb                     = ${folder_bin}/$(basename ${PROG_NAME})"
echo "Installation rman_disk_folder        = ${rman_disk_folder}      "
echo "Installation folder_top              = ${folder_top}            "
echo "Installation folder_bin              = ${folder_bin}            "
echo "Installation folder_log              = ${folder_log}            "
echo "Installation folder_rman_scripts     = ${folder_rman_scripts}   "
echo "Installation rman_config_script      = ${rman_config_script}    "
echo "Installation rman_weekly_script      = ${rman_weekly_script}    "
echo "Installation rman_daily_script       = ${rman_daily_script}     "
echo "Installation rman_archivelog_script  = ${rman_archivelog_script}"
echo "Installation rman_fra_daily_script   = ${rman_fra_daily_script} "
echo "Installation rman_review_script      = ${rman_review_script}    "
echo "Installation rman_tidy_script        = ${rman_tidy_script}      "
echo "Installation rman_notes              = ${rman_notes}      "
echo -e "\n"

}


#          _   _ _                          _       _
#         | | (_| |                        (_)     | |
#    _   _| |_ _| |  ______   ___  ___ _ __ _ _ __ | |_
#   | | | | __| | | |______| / __|/ __| '__| | '_ \| __|
#   | |_| | |_| | |          \__ | (__| |  | | |_) | |_
#    \__,_|\__|_|_|          |___/\___|_|  |_| .__/ \__|
#                                            | |
#                                            |_|

function get_date_string {      # no-help-output
  printf "$(date +%Y-%m-%d_%H:%M:%S)\n"
}

function get_time_string {      # no-help-output
  printf "$(date +%H:%M:%S)\n"
}

function log_info {             # no-help-output
  echo -e "\E[1;33;43m$(get_date_string): INFO:\E[m" $1
}

function log_warn {             # no-help-output
  echo -e "\E[1;44;33m$(get_date_string): WARN:\E[m" $1
}

function log_fail {             # no-help-output
  echo -e "\E[1;41;22m$(get_date_string): FAIL:\E[m" $1
}

function log_step {             # no-help-output
  a=$(printf '=%.0s' {1..10})
  echo -e "\E[1;31;33m$(get_date_string): STEP: $a $1 $a\E[m"
}

function log_title {             # no-help-output
  a=$(printf '=%.0s' {1..10})
  b=$(echo $1 | tr "[:alnum:]" "-")
  echo -e "\E[1;31;33m$a $b $a\E[m"
  echo -e "\E[1;31;33m$a $1 $a\E[m"
  echo -e "\E[1;31;33m$a $b $a\E[m"
}

function log_debug {             # no-help-output
  a=$(printf '~%.0s' {1..10})
  echo -e "\E[0;33m$(get_date_string): DEBUG: $a $1 $a\E[m"
}

function install {                                                                                  # Install Create installation folders, create RMAN scripts, install orb, and suggest crontab schedule

log_info "Creating the installation folders"

mkdir -p ${folder_bin}
mkdir -p ${folder_log}
mkdir -p ${folder_rman_scripts}

log_info "Installing ${PROG_NAME} to ${folder_bin}"
cp ${PROG_NAME} ${folder_bin}
chmod 700 ${folder_bin}/${PROG_NAME}

log_info "Creating the RMAN FRA daily backup script"

cat << END > ${rman_fra_daily_script}

run
{
SHOW ALL;
BACKUP RECOVERY AREA;
}
END

log_info "Creating the RMAN daily backup script"

cat << END > ${rman_daily_script}

run
{
SHOW ALL;
BACKUP SECTION SIZE 100G AS BACKUPSET FILESPERSET = 15 INCREMENTAL LEVEL 1 CUMULATIVE DATABASE TAG 'DB_DAILY_L1';
BACKUP FILESPERSET = 15 ARCHIVELOG ALL DELETE ALL INPUT TAG 'archivelog';
}
END

log_info "Creating the RMAN archivelog backup script"

cat << END > ${rman_archivelog_script}

run
{
SHOW ALL;
BACKUP FILESPERSET = 15 ARCHIVELOG ALL DELETE ALL INPUT TAG 'archivelog';
}
END

log_info "Creating the RMAN weekly backup script"

cat << END > ${rman_weekly_script}

run
{
SHOW ALL;
BACKUP SECTION SIZE 100G AS BACKUPSET FILESPERSET = 15 INCREMENTAL LEVEL 0 DATABASE TAG 'DB_WEEKLY_L0';
BACKUP FILESPERSET = 15 ARCHIVELOG ALL DELETE ALL INPUT TAG 'ARCHIVELOG';
}
END

log_info "Creating the RMAN tidy script"

cat << END > ${rman_tidy_script}

run
{
SHOW ALL;
CROSSCHECK COPY;
CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED COPY;
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT OBSOLETE;
}
END

log_info "Creating the RMAN config script"

cat << END > ${rman_config_script}

#CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DEVICE type SBT;
#CONFIGURE CHANNEL DEVICE TYPE sbt FORMAT '%d_%I_%U' PARMS='ENV=( NB_ORA_SERV=TheNetbackServerIPorDNS, NB_ORA_POLICY=TheNetbackupPolicyName, NB_ORA_SCHED=TheNetbackupScheduleName, NB_ORA_CLIENT=TheNetbackupClient )';
#CONFIGURE DEFAULT DEVICE TYPE TO SBT;

CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE CHANNEL 1 DEVICE TYPE DISK FORMAT '${rman_disk_folder}/%d/%d_%T_%s_%U';
CONFIGURE CHANNEL 2 DEVICE TYPE DISK FORMAT '${rman_disk_folder}/%d/%d_%T_%s_%U';
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 100g;
CONFIGURE CHANNEL DEVICE TYPE SBT MAXPIECESIZE 100g;
CONFIGURE COMPRESSION ALGORITHM 'basic' OPTIMIZE FOR LOAD TRUE;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${rman_disk_folder}/%d/%d_%I_%F';
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE SBT TO '%d_%I_%F';
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET PARALLELISM 2;
CONFIGURE DEVICE TYPE DISK PARALLELISM 2 BACKUP TYPE TO BACKUPSET;
CONFIGURE DEVICE TYPE SBT PARALLELISM 4 BACKUP TYPE TO BACKUPSET;
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;
CONFIGURE RMAN OUTPUT TO KEEP FOR 31 DAYS;
# Size the control file to purge backup logs after 31 days
alter system set CONTROL_FILE_RECORD_KEEP_TIME=31;
# Low activity databases write an archive log every 5 minutes
alter system set archive_lag_target=300 scope=both;
END

log_info "Creating the RMAN review script"

cat << END > ${rman_review_script}
SHOW ALL;
LIST BACKUP SUMMARY;
REPORT SCHEMA;
END

log_info "Creating the example backup restore notes"

cat << END > ${rman_notes}
function help_restore { # Help How to restore a CDB or PDB

# These notes are RMAN restore and recovery notes
# Check these notes before attempting to perform any restore or recovery operations
# You are recommended to raise a support request with Oracle before restoring your database or any parts of your database

rman
connect target

SELECT RECID, STAMP, THREAD#, SEQUENCE#, FIRST_CHANGE#
       FIRST_TIME, NEXT_CHANGE#
FROM   V$ARCHIVED_LOG
WHERE  RESETLOGS_CHANGE# =
       ( SELECT RESETLOGS_CHANGE#
         FROM   V$DATABASE_INCARNATION
         WHERE  STATUS = 'CURRENT');

     RECID      STAMP    THREAD#  SEQUENCE# FIRST_TIME NEXT_CHANGE#
---------- ---------- ---------- ---------- ---------- ------------
         1 1110367496          1         27    3133136      3154821
         2 1110367537          1         28    3154821      3155002
         3 1110367720          1         29    3155002      3155116

LIST BACKUP SUMMARY;
REPORT SCHEMA;

CROSSCHECK COPY;
CROSSCHECK BACKUP;

# Backup and individual PDB
BACKUP PLUGGABLE DATABASE p1;
BACKUP PLUGGABLE DATABASE p1, p2;

# Restore PDB to SCN
ALTER PLUGGABLE DATABASE p1 CLOSE;
RUN
{
SET UNTIL SCN 3155002;
RESTORE PLUGGABLE DATABASE p1 validate;
}
RUN
{
SET UNTIL SCN 3155002;
RESTORE PLUGGABLE DATABASE p1 validate;
RECOVER PLUGGABLE DATABASE p1 validate;
}
ALTER PLUGGABLE DATABASE p1 OPEN RESETLOGS;

# Restore PDB to timestamp
ALTER PLUGGABLE DATABASE p1 CLOSE;
run
{
   set UNTIL TIME "to_date('20/07/2022 14:53:11','dd/mm/yyyy hh:mi:ss')";
   RESTORE PLUGGABLE DATABASE p1;
   RECOVER PLUGGABLE DATABASE p1;
}
ALTER PLUGGABLE DATABASE p1 OPEN RESETLOGS;

}
END

log_info "orb is installed here: ${folder_top}"
cd ${folder_top}
find . | grep -v ".log"
echo

}

#          _   _ _                _ _
#         | | (_| |              | | |
#    _   _| |_ _| |  ______    __| | |__
#   | | | | __| | | |______|  / _` | '_ \
#   | |_| | |_| | |          | (_| | |_) |
#    \__,_|\__|_|_|           \__,_|_.__/
#

function show {                                                                                     # no-help-output

(
  if [ ${LD_LIBRARY_PATH:-0} = 0 ]; then LD_LIBRARY_PATH=NotSet; fi
  if [ ${ORACLE_BASE:-0} = 0 ]; then ORACLE_BASE=NotSet; fi
  if [ ${ORACLE_HOME:-0} = 0 ]; then ORACLE_HOME=NotSet; fi
  if [ ${ORACLE_SID:-0} = 0 ]; then ORACLE_SID=NotSet; fi
  if [ ${TNS_ADMIN:-0} = 0 ]; then TNS_ADMIN=NotSet; fi
  if [ ${OKV_ADMIN:-0} = 0 ]; then OKV_ADMIN=NotSet; fi

cat << END

          TNS_ADMIN=${TNS_ADMIN}
         ORACLE_SID=${ORACLE_SID}
        ORACLE_BASE=${ORACLE_BASE}
        ORACLE_HOME=${ORACLE_HOME}
          OKV_ADMIN=${OKV_ADMIN}
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}

END
)

show_running_listeners
show_running_instances

}

function show_running_listeners {                                                                   # List The running TNS listeners

a="Oracle listener is up:"
for myrows in $(ps -ef | grep tnslsnr | grep -v grep | awk '{print $9}')
do
  echo "$a $myrows "
done

}

function show_running_instances {                                                                   # List The running database instances

a="Oracle database instance up:"
for myrows in $(ps -ef | grep lgwr | grep -v grep | awk '{print $8}')
do
  echo "$a $myrows "
done
echo

}

function set_oraenv {                                                                               # no-help-output - Set The ORAENV ask=no environment variables for the SID

if [ $# -ne 1 ]; then
  clear
  log_fail "Parameter SID not included in the function call"
  return 1
fi

export ORACLE_SID=${1}; export ORAENV_ASK=NO; . oraenv > /dev/null; unset ORAENV_ASK

show

return 0

}

function set_debug {                                                                                # Set Enable debug mode.  RMAN actions are logging but not executed
  debug=true
}

function is_database_primary {                                                                      # no-help-output
# 1 = SID

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "is_database_primary: incorrect parameters, supply - SID"
  exit
fi

db_sid=$1

# set oraenv and exit on failure
log_info "Setting ORAENV using ${db_sid}"
set_oraenv ${db_sid}
if [ $? -eq 1 ]; then
  log_fail "is_database_primary: database SID (${db_sid}) was not set"
  exit
fi

(
echo -e "connect / as sysdba\n set head off\n select DATABASE_ROLE from V\$database;" | sqlplus -s /nolog
) | grep PRIMARY

# return 1 if grep failed to match PRIMARY
return $?

}

#          _   _ _
#         | | (_| |
#    _   _| |_ _| |  ______   _ __ _ __ ___   __ _ _ __
#   | | | | __| | | |______| | '__| '_ ` _ \ / _` | '_ \
#   | |_| | |_| | |          | |  | | | | | | (_| | | | |
#    \__,_|\__|_|_|          |_|  |_| |_| |_|\__,_|_| |_|
#


function rman_run {                                                                                 # no-help-output
# 1 = SID
# 2 = rman_script_file_name
# 3 = rman_logfile_name

# Check we have 3 input parameters
if [ $# -ne 3 ]; then
  log_fail "rman_run: incorrect parameters, supply - SID, rman-script, rman-logfile"
  exit
fi

db_sid=$1
rman_script=$2
rman_logfile=$3

# set oraenv and exit on failure
#log_info "Setting ORAENV using ${db_sid}"
set_oraenv ${db_sid}
if [ $? -eq 1 ]; then
  log_fail "rman_run: database SID (${db_sid}) was not set"
  exit
fi

# check rman script exists and exit on failure
if [ ! -f "$rman_script" ]; then
  log_fail "rman_run: rman_script not found - ${rman_script}"
  exit
fi

# check logfile folder exists and exit on failure
folder=$(dirname $rman_logfile)
if [ ! -d "$folder" ]; then
  log_fail "rman_run: rman_logfile folder not found - ${folder}"
  exit
fi

# Check the database is primary (this works for single instance and Data Guard)
is_database_primary ${db_sid}
if [ $? -eq 1 ];then
  log_fail "rman_run: Database is not primary"
  exit
fi

log_info "Preparing to run the RMAN script: $rman_script"
cat $rman_script

# debug mode does not execute the backup
if [ $debug = "true" ];then
  log_debug "rman target=/ cmdfile=$rman_script log=$rman_logfile APPEND"
else
  rman target=/ cmdfile=$rman_script log=$rman_logfile APPEND

  if [ $? -eq 1 ];then
    s=$(basename $rman_script)
    #log_syslog "database=${db_sid}: $s :reason=database backup failure"
    grep -E "ORA-|RMAN-" $rman_logfile
    log_fail "RMAN action failed. See the log file"
  fi
fi

echo -e "\n"

log_info "RMAN log file: $rman_logfile"

}

function config {                                                                                   # Setup Apply RMAN configuration to the database SID

dbsid=$1
rman_script=${rman_config_script}
rman_logfile=${folder_log}/rman_config_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log

rman_run ${dbsid} ${rman_script} ${rman_logfile}

dbUniqueName=$( ( echo -e "connect / as sysdba\n set head off\n show parameter db_name" | sqlplus -s /nolog; ) | grep db_name | awk '{print $3}' )

# For RAC this needs to be changed to db_unique_name
#for myrows in $(ps -ef | grep lgwr | grep -v grep | awk 'BEGIN {FS="_"} {print $3}')
#do
  # create full rman to disk folder path.  Note the ^^ forces myrows value to UPPERCASE
  #log_info "Creating backup folder: ${rman_disk_folder}/${dbsid}"
  log_info "Creating backup folder: ${rman_disk_folder}/${dbUniqueName}"
  mkdir -p ${rman_disk_folder}/${dbUniqueName}
  #mkdir -p ${rman_disk_folder}/${dbsid}
#done

log_info "CRONTAB schedule suggestion - add this to the ${USER} crontab"

#for myrows in $(ps -ef | grep lgwr | grep -v grep | awk 'BEGIN {FS="_"} {print $3}')
#do
cat << END
  =========================================================================================
  @hourly           ${PROG_NAME} archive ${dbsid}     # Backup the archivelogs every hour
  15 01 * * mon-sat ${PROG_NAME} daily   ${dbsid}     # Backup the database incremental level 1 and archivelog Monday-Saturday at 01:15
  15 01 * * sun     ${PROG_NAME} weekly  ${dbsid}     # Backup the database incremental level 0 and archivelog on Sunday at 01:15
  30 01 1 * sun     ${PROG_NAME} tidy    ${dbsid}     # Remove expired backups, archivelog, and orb backup logs weekly on Sunday at 01:30
END
#done

}

function review {                                                                                   # List Review the RMAN configuration

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "review: incorrect parameters - please include SID -> ${PROG_NAME} review SID"
  exit
fi

dbsid=$1
rman_script=${rman_review_script}
rman_logfile=${folder_log}/rman_review_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log

rman_run ${dbsid} ${rman_script} ${rman_logfile}

cat ${rman_logfile}

log_step "grep listing of FAIL: messages in all log files"
grep FAIL: ${folder_log}/*.log
log_step "grep listing of WARN: messages in all log files"
grep WARN: ${folder_log}/*.log
#log_step "grep listing of INFO: messages in all log files"
#grep INFO: ${folder_log}/*.log

}


#    ____             _                               _   _
#   |  _ \           | |                    /\       | | (_)
#   | |_) | __ _  ___| | ___   _ _ __      /  \   ___| |_ _  ___  _ __  ___
#   |  _ < / _` |/ __| |/ | | | | '_ \    / /\ \ / __| __| |/ _ \| '_ \/ __|
#   | |_) | (_| | (__|   <| |_| | |_) |  / ____ | (__| |_| | (_) | | | \__ \
#   |____/ \__,_|\___|_|\_\\__,_| .__/  /_/    \_\___|\__|_|\___/|_| |_|___/
#                               | |
#                               |_|

function archive {                                                                                   # Backup The Archivelogs, remove if not retained for standby database shipment

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "archive: incorrect parameters - please include SID -> ${PROG_NAME} archive SID"
  exit
fi

dbsid=$1
rman_script=${rman_archivelog_script}
rman_logfile=${folder_log}/rman_archivelog_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log

(
  log_title "archive backup"
  log_info "dbsid=$dbsid"
  log_info "rman_script=${rman_script}"
  log_info "rman_logfile=${rman_logfile}"
  log_info "rman_stdout=${rman_stdout}"
  rman_run ${dbsid} ${rman_script} ${rman_logfile}
) > ${rman_stdout}

}

function daily {                                                                                     # Backup Backup the database using daily incremental level 1

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "daily: incorrect parameters - please include SID -> ${PROG_NAME} daily SID"
  exit
fi

dbsid=$1
rman_script=${rman_daily_script}
rman_logfile=${folder_log}/rman_daily_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log

(
  log_title "daily backup"
  log_info "dbsid=$dbsid"
  log_info "rman_script=${rman_script}"
  log_info "rman_logfile=${rman_logfile}"
  log_info "rman_stdout=${rman_stdout}"
  rman_run ${dbsid} ${rman_script} ${rman_logfile}
) > ${rman_stdout}

}

function weekly {                                                                                    # Backup Backup the database using weekly incremental level 0

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "weekly: incorrect parameters - please include SID -> ${PROG_NAME} weekly SID"
  exit
fi

dbsid=$1
rman_script=${rman_weekly_script}
rman_logfile=${folder_log}/rman_weekly_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log

(
  log_title "weekly backup"
  log_info "dbsid=$dbsid"
  log_info "rman_script=${rman_script}"
  log_info "rman_logfile=${rman_logfile}"
  log_info "rman_stdout=${rman_stdout}"
  rman_run ${dbsid} ${rman_script} ${rman_logfile}
) > ${rman_stdout}

}

function tidy {                                                                                      # Remove Remove expired: backupsets, archive logs, orb log files

# Check we have 1 input parameters
if [ $# -ne 1 ]; then
  log_fail "tidy: incorrect parameters - please include SID -> ${PROG_NAME} tidy SID"
  exit
fi

dbsid=$1
rman_script=${rman_tidy_script}
rman_logfile=${folder_log}/rman_tidy_$(get_date_string).log
rman_stdout=${folder_log}/orb_session_$(get_date_string).log


(
  log_title "tidy"
  log_info "dbsid=$dbsid"
  log_info "rman_script=${rman_script}"
  log_info "rman_logfile=${rman_logfile}"
  log_info "rman_stdout=${rman_stdout}"
  # Remove expired backups, archivelogs and control file logging
  rman_run ${dbsid} ${rman_script} ${rman_logfile}
  # Remove expired log files
  cd ${folder_log}
  find orb_session*.log -mtime +30 -delete;
  find rman_archivelog*.log -mtime +30 -delete;
  find rman_config*.log -mtime +30 -delete;
  find rman_daily*.log -mtime +30 -delete;
  find rman_review*.log -mtime +30 -delete;
  find rman_tidy*.log -mtime +30 -delete;
  find rman_weekly*.log -mtime +30 -delete;
) > ${rman_stdout}

}

#    __  __       _
#   |  \/  |     (_)
#   | \  / | __ _ _ _ __
#   | |\/| |/ _` | | '_ \
#   | |  | | (_| | | | | |
#   |_|  |_|\__,_|_|_| |_|
#

typeset g_application_title="Oracle RMAN Backup wrapper script"

PROG_NAME=${0}
PATH=$PATH:/usr/local/bin                                                                             # crontab execution needs this to put oraenv on search path

#typeset rman_disk_folder=/mnt/hostdl/orabackup                                                        # Cloud NFS mount point folder
typeset rman_disk_folder=/mnt/orabackup                                                               # Cloud NFS mount point folder

typeset folder_top=~/orb                                                                              # To install orb to a diferent folder, change this variable

typeset folder_bin=${folder_top}/bin
typeset folder_log=${folder_top}/log
typeset folder_rman_scripts=${folder_top}/rman-scripts
typeset rman_archivelog_script=${folder_rman_scripts}/bu-archivelog.txt
typeset rman_fra_daily_script=${folder_rman_scripts}/bu-fra-daily.txt
typeset rman_daily_script=${folder_rman_scripts}/bu-daily.txt
typeset rman_config_script=${folder_rman_scripts}/rman-config.txt
typeset rman_tidy_script=${folder_rman_scripts}/rman-tidy.txt
typeset rman_weekly_script=${folder_rman_scripts}/bu-weekly.txt
typeset rman_review_script=${folder_rman_scripts}/rman-review.txt
typeset rman_notes=${folder_rman_scripts}/rman-notes.txt

typeset log_fail_syslog=true                                                                          # Not implemented yet.  Waiting to decide how to alert on backup failed outcomes
typeset debug=true
typeset debug=false

if [ $# -eq 0 ]; then help "Wrong syntax, please check and try again."; fi

# echo Starting...

# echo $1 $2 $3 $4
$1 $2 $3 $4 $5 $6

#echo Finished.
