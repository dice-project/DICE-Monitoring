#!/bin/bash

ARCH=`uname -s`
DIR=
PID=
RE='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
RENR='^[0-9]+$'


if [ $ARCH == "Linux" ]; then
   DIR=`readlink -f "$( dirname "$0" )"`
elif [ $ARCH == "Darwin" ]; then
   CMD="import os, sys; print os.path.realpath(\"$( dirname $0 )\")"
   DIR=`python -c "$CMD"`
fi



if [ $# -eq 0 ]; then
    echo "Starting dmon-logstash"
	#. $DIR/dmonEnv/bin/activate
        python dmon-logstash.py > log/dmon-logstash.out 2>&1 &
        echo $! > pid/dmon-logstash.pid
    echo "Finished"
elif [ $1 == "stop" ]; then
    echo "Stopping dmon-logstash"
    if [ ! -f $DIR/src/pid/dmon-logstash.pid ]; then
        echo "No Logstash PID file found."
    fi
    PID=`cat $DIR/pid/dmon-logstash.pid`
    kill -9  `cat $DIR/pid/dmon-logstash.pid`
    sleep 5
    while [ kill -0  $PID ]
        do
            kill -9  $PID
            sleep 1
        done
    echo "Stopped logstash server"
    killall -9 python
    echo "Stopped dmon-logstash"
else
   echo "DMON-logstash does not support this command line argument!"
fi