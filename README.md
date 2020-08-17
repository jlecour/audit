audit
======

Simple bash script for server auditing

TODO
----

  - search for all available kernel for centOS / Fedora hosts
  - check for vlan and/or bonding
  - export MySQL configuratin (`cat /etc/mysql/my.cnf |grep -v "#"`)
  - export MySQL datadir size (`MYSQL_DATADIR=$(cat /etc/mysql/my.cnf |grep datadir | awk '{print $3}') && du -sh $MYSQL_DATADIR`) 
  - export MySQL database size (`SELECT table_schema AS 'DB Name', ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables GROUP BY table_schema;`)
  - export PostgreSQL configuraiton
  - export packets version for Debian hosts (`dpkg --get-selections`)
  - export "hold" packets for Debian hosts (`dkpg hold`)
  - make script SSH friendly
