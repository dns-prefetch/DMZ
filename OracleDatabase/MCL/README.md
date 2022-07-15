<img src="https://dns-prefetch.github.io/assets/logos/dmz-header-2.svg" width="100%" height="100%">

# Oracle: Cloud, Linux, and Database

&nbsp;

![Employee data](sample_output/sample.png?raw=true "Employee Data title")

# Migration Check List

Use cases
1. Use the script mcl.sql to capture Oracle database setup and configuration details and start to plan the database migration.  Typically, the first and most daunting tasks for most DBA's is to form a good understanding of the database, mcl.sql will help.
2. I frequently ask DBA teams to run mcl.sql to give me an introduction to their database as part of my first fact gathering exercise.

# Instructions

* Download mcl.sql
    * wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl.sql
    * curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl.sql > mcl.sql
    * wget https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl-light.sql
    * curl https://raw.githubusercontent.com/dns-prefetch/DMZ/main/OracleDatabase/MCL/mcl-light.sql > mcl.sql
* SQL*Plus run mcl.sql against your database (this script is read only, and does not access business data)
    * SQL*Plus from your laptop over SQL*Net
    * SQL*Plus from your database host.
        * If the database is configured as RAC, run against any online instance
        * If the database is configured with Data Guard, run against the primary
* Copy the output html file to your laptop
* Open in your favourite browser

__Migration Check List, should be run from a SYSDBA account.__

The runtime of mcl.sql depends on the number of database objects and the performance of your platform, the number of rows in tables is not a factor.  In general this script takes between 30 seconds and 40 minutes, on average, completing within 2 minutes

This script is read-only

* it does SELECT against dictionary tables
* it does NOT insert
* it does NOT update
* it does NOT delete
* it does NOT alter
* it does NOT create
* it does NOT drop
* it does NOT grant
* it does NOT revoke


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


