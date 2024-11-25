#!/bin/bash
# $DATE should be passed from qsub when it's queued up
htar -c -v -f /hpss/c/r/cresis/2017_Antarctica_Basler/$1.tar -P -Y auto -H copies=1 -H verify=1 /N/dcwan/projects/cresis/2017_Antarctica_Basler/$1
