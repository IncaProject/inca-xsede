#!/bin/sh

INCA_INSTALL=/misc/inca/install-2r5
EMAIL=ssmallen@sdsc.edu

cd $INCA_INSTALL
./bin/inca stop consumer
sleep 5
pids=`ps wwx | grep Consumer | grep java | wc -l`
if [ $pids -gt 0 ]; then
  ps wwx | grep Consumer | grep java | mail -s "More than 1 process running after stopping consumer" $EMAIL
fi
./bin/inca start consumer
tail var/consumer.log
