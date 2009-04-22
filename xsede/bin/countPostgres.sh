#!/bin/sh

countPostgres=`ps awwx | grep postgres | wc -l`
date=`date`
echo "$date $countPostgres" >> ${HOME}/logs/postgresCount.log
maxPostgres=80
if ( test $countPostgres -gt $maxPostgres ); then
  date | mail -s "postgres count is $countPostgres (over $maxPostgres processes)" inca@sdsc.edu
fi
