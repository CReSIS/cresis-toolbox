#!/bin/bash

TOTAL_MEM=`free | awk 'NR==2 {print $2}'`

user=`whoami`
LOG_FILE=/tmp/watch_cpu_mem.$USER.log

while (( 1 ))
do
  clear
  printf "Writing to file %s\n" $LOG_FILE
  ps -C MATLAB,hf3d,hfss,worker_task,java,httpd,postmaster,cluster_job -o "comm,user,rss,cputime,pid,pcpu" | awk -v total_mem=$TOTAL_MEM 'NR==1 {printf "%10s %10s %10s %10s %10s %10s %10s\n", $1, $2, $3, "%MEM", $4, $5, $6;} NR>1 {printf "%10s %10s %10.1f %10.0f%% %10s %10d %10.1f\n", $1, $2, $3/1024/1024, $3/total_mem*100, $4, $5, $6}'
  date >>$LOG_FILE
  ps -C MATLAB,hf3d,hfss,worker_task,java,httpd,postmaster,cluster_job -o "comm,user,rss,cputime,pid,pcpu" | awk -v total_mem=$TOTAL_MEM 'NR==1 {printf "%10s %10s %10s %10s %10s %10s %10s\n", $1, $2, $3, "%MEM", $4, $5, $6;} NR>1 {printf "%10s %10s %10.1f %10.0f%% %10s %10d %10.1f\n", $1, $2, $3/1024/1024, $3/total_mem*100, $4, $5, $6}' >>$LOG_FILE
  sleep 1
done

