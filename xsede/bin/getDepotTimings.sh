#!/bin/sh

INCA_DIR=/misc/inca/install-2r5
PERIOD=$1

if [ -z "$PERIOD" ]; then
  PERIOD=3600
fi

(( PERIOD = $PERIOD * 1000 ))
grep "start\[" $INCA_DIR/var/depot.log > /tmp/timings.$$
java -jar $INCA_DIR/lib/perf4j-0.9.10.jar -t $PERIOD /tmp/timings.$$
rm -f /tmp/timings.$$
