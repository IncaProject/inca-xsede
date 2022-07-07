#!/bin/sh 

dirs="/misc/inca/install-2r5 /misc/inca/ipm/IncaInstallDir"

for dir in ${dirs}; do
  logs=`ls $dir/var/*.log.*[0-9] 2>/dev/null`
  echo "Gzipping $dir logs" `date` >> ${HOME}/logs/gzip.log
  for log in ${logs}; do
    echo "Gzipping $log" >> ${HOME}/logs/gzip.log
    gzip $log >> ${HOME}/logs/gzip.log
  done
done
