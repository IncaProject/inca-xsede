#!/bin/sh

nohup /misc/inca/postgresql-8.1.3/install/bin/vacuumdb -f -z -v teragrid >& ${HOME}/logs/vacuumfull.log &
