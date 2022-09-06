<img src="https://dns-prefetch.github.io/assets/logos/dmz-header-2.svg" width="100%" height="100%">

# Oracle: Cloud, Linux, and Database

&nbsp;

# Oracle Database Backup script

Use cases
Oracle database single instance RMAN backups
Oracle RAC database backups
Oracle Data Guard database backups.  The script checks the DATABASE_ROLE=PRIMARY and exits if the database is a standby.

# Instructions

* Download orb.sh
    * wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh
    * curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/RMAN/orb.sh > orb.sh

* Install on the database server

```
chmod 700 orb.sh
orb.sh install
```

To change the default installation location (default ~/orb) edit script and change

```
typeset folder_top=~/orb
 to
typeset folder_top=<your-preferred-folder>/orb
```



__Migration Check List, should be run from a SYSDBA account.__

cd /mnt/hostm/Code/Unix/azure_db_backup
chmod 700 orb.sh
orb.sh install

* ~/orb/bin/orb.sh help
* ~/orb/bin/orb.sh config   db21c
* ~/orb/bin/orb.sh archive  db21c
* ~/orb/bin/orb.sh daily    db21c
* ~/orb/bin/orb.sh weekly   db21c
* ~/orb/bin/orb.sh tidy     db21c
* ~/orb/bin/orb.sh review   db21c

* find ~/orb/log



There is no need to enable dbms_output or start a spool file, all this is done for you.
e.g.

```
    connect un/pw@//hostname:port/service_name as sysdba
    or
    connect un/pw@db as sysdba
    or
    connect / as sysdba

    SQL> @mcl.sql

    Finished. The spool file is mcl.html
    SQL>
```

Then ZIP with encryption

```
zip -e mcl.zip mcl.html
```


