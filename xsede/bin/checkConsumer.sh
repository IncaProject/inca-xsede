#!/bin/sh

wget -o /dev/null -O /dev/null "http://sapa.sdsc.edu:8080/config.jsp?xsl=config.xsl"
date=`date`
echo "$date = $?" >> ${HOME}/logs/consumerStatus.log
if ( test $? -ne 0 ); then
  date | mailx -s "consumer down" inca@sdsc.edu
fi
