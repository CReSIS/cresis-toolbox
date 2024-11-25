#!/bin/bash

# The following line is required to run on slurm:
#Xsrun  I know what I am doing

# =========================================================================
# SETUP
# =========================================================================

# Add some debugging information to stdout
echo "cluster_job.{sh,m} Start" `whoami` "hostname:"`hostname` "("`date`")"
#declare
#pwd

# Make sure file permissions will be set so everyone can read
umask 000

taskset -p $$

# Turn on MCR debugging information (goes to stderr)
export  MCR_CACHE_VERBOSE=1

# Get this scripts (the parent) process info
parent_pid=$$
#echo Parent: $parent_pid

# Check for sufficient space in $MCR_CACHE_ROOT for MCR to run
# =======================================================================
if [ -z $MCR_CACHE_ROOT ]
then
  # If not defined, use default
  MCR_CACHE_ROOT=/tmp/`whoami`
fi
tmp_avail=-1
while (( $tmp_avail < 0 ))
do
  # Make sure the directory is created to ensure df will run successfully
  mkdir -p $MCR_CACHE_ROOT
  if (( $? == 0 ))
  then
    # Get the space available in kilobytes (-P prevents line wrap in the
    # middle of a printout when the file system name is too long).
    tmp_avail=`df -P $MCR_CACHE_ROOT | tail -1 | awk '{print $4}'`
  else
    # Cannot even create the directory
    tmp_avail=0
  fi
  echo Space available on MCR_CACHE_ROOT=$MCR_CACHE_ROOT is $tmp_avail kB
  if (( tmp_avail < 256000 ))
  then
    if [ -n "$MCR_CACHE_ROOT2" ] && [ "$MCR_CACHE_ROOT" != "$MCR_CACHE_ROOT2" ]
    then
      echo "Using backup MCR_CACHE_ROOT2=$MCR_CACHE_ROOT2"
      MCR_CACHE_ROOT=$MCR_CACHE_ROOT2
      tmp_avail=-1
    else
      echo "Insufficient space on MCR_CACHE_ROOT: Less than 256 MB."
      if [ "$MCR_CACHE_ROOT" != "$MCR_CACHE_ROOT2" ]
      then
        echo "You may want to define MCR_CACHE_ROOT2 as a backup in your .bashrc."
      fi
    fi
  fi
done
MCR_CACHE_ROOT=$MCR_CACHE_ROOT/`hostname`
# Export MCR_CACHE_ROOT so that the child processes that cluster_job.sh
# creates will have the environment variable too.
export MCR_CACHE_ROOT

# =========================================================================
# ATTEMPT TO RUN CLUSTER_JOB.M UP TO MAX_ATTEMPTS TIMES
# =========================================================================
max_attempts=3
attempt=1

while (( attempt <= max_attempts ))
do

  echo Attempt $attempt of $max_attempts

  # Start child process
  # Run run_cluster_job.sh (runs Matlab compiled cluster_job.m)
  chmod a+x $MATLAB_CLUSTER_PATH/run_cluster_job.sh
  $MATLAB_CLUSTER_PATH/run_cluster_job.sh $MATLAB_MCR_PATH &

  child_pid=$!
  #echo Child: $child_pid

  # Wait for child process to finish
  child_proc=`ps -eo ppid,pid | sed -n "/^\s*$parent_pid\s*$child_pid/p" | awk '{print $2}'`
  max_mem=0
  max_cpu=0
  while [[ ! -z $child_proc ]]
  do
    mem=`ps -eo ppid,rss | sed -n "/^\s*$child_pid/p" | awk '{print $2}'`
    #echo Mem: $mem
    if (( mem > max_mem ))
    then
      max_mem=$mem
    fi
    cpu=`ps -eo ppid,cputime | sed -n "/^\s*$child_pid/p" | awk '{print $2}'`
    #echo CPU: $cpu
    if [[ ! -z $cpu ]]
    then
      max_cpu=$cpu
    fi

    # Update maximum memory and maximum CPU

    child_proc=`ps -eo ppid,pid | sed -n "/^\s*$parent_pid\s*$child_pid/p" | awk '{print $2}'`
    sleep 0.1
  done
  echo "Max Mem (KB):" $max_mem
  echo "Max CPU (MM:SS):" $max_cpu

  # Get return value from child process
  wait $child_pid
  return_value=$?

  if [ $return_value -eq 0 ]
  then
    echo "  Successful return value of $return_value."
    break
  else
    echo "  Failed with return value of $return_value. This usually is caused by reasons unrelated to the Matlab script itself."
  fi
  ((attempt++))

done

echo "  cluster_job.{sh,m} Done" "attempts:"$attempt "max_attempts:"$max_attempts "("`date`")"
date

if [[ -z $JOB_COMPLETE_PAUSE ]]
then
  JOB_COMPLETE_PAUSE=5
fi

echo sleep $JOB_COMPLETE_PAUSE
sleep $JOB_COMPLETE_PAUSE # Wait for file writes to take place and be available in file system metadata (seems to be necessary for high performance file systems)

exit $return_value
