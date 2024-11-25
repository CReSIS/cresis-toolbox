#!/bin/bash
# How to use:
# Enable only one of the "find" statement options
# Navigate to the correct directory as explained in the comments of the
# option and then run this command.

# OPTION 1: USE THIS FOR CT_TMP
# -bash-4.1$ pwd
# /cresis/snfs1/dataproducts/ct_data/ct_tmp (gRadar.ct_tmp_path)
#find . -maxdepth 3 -mindepth 3 -type d -print0 | sort | while read -d '' -r dir; do

# OPTION 2: USE THIS FOR RAW DATA STORED IN fmcw AND mcords DIRECTORIES
# bash-4.1$ pwd
# /cresis/snfs2/data/2019_Antarctica_GV
# bash-4.1$ ls
# 20191017  20191027  20191030  20191104	20191108  20191114  20191118
# bash-4.1$ ls 20191030
# fmcw  mcords
#find . -maxdepth 2 -mindepth 2 -iname "mcords" -type d -print0 | sort | while read -d '' -r dir; do

# OPTION 3: USE THIS FOR OUTPUT DIRECTORY (gRadar.out_path)
# Run this command in the instrument directory
# -bash-4.1$ pwd
# /cresis/snfs1/dataproducts/ct_data/accum
# /cresis/snfs1/dataproducts/ct_data/kuband
# /cresis/snfs1/dataproducts/ct_data/rds
# /cresis/snfs1/dataproducts/ct_data/snow
find . -maxdepth 2 -mindepth 2 -iname "*" -type d -print0 | sort | while read -d '' -r dir; do

# ALL OPTIONS USE THE FOLLOWING CODE (NO NEED TO CHANGE BELOW THIS POINT)
  #files=("$dir"/*)
  num=$(find "$dir" -ls | wc -l);
  #printf "%5d files in directory %s\n" "$num" "$dir"
  printf "%5d\tDir:\t%s\n" "$num" "$dir"
done
