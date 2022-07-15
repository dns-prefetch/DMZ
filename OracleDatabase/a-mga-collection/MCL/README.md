# DMZ
 Oracle: Cloud, Linux, and Database

<p>
    <img src="https://dns-prefetch.github.io/assets/logos/dmz-header.svg">
</p>

&nbsp;

Migration Check List, should be run from a SYSDBA account.

The runtime of mcl.sql depends on the number of database objects and the performance of your platform, the number of rows in tables is not a factor.  In general this
script takes between 30 seconds and 40 minutes, on average, completing within 2 minutes

This script is read-only

* it does SELECT
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
    connect un/pw@db as sysdba
    connect / as sysdba

    SQL> @mcl.sql
      or
    SQL> @mcl.sql <schema_name_1> <schema_name_2> <schema_name_3>

    Finished. The spool file is mcl.html
    SQL>
```

Then ZIP with encryption

```
zip -e mcl.zip mcl.html
```


