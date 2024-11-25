#!/bin/bash
# This script helps determine if files are on disk or on tape
# If the apparent size is larger, than this generally means that
# at least some of the files are on tape.
#
# SYNTAX:
# ./tape_or_disk.sh DIRECTORY_OR_FILE_LIST
#
# EXAMPLES:
# ./tape_or_disk.sh 2013*
# ./tape_or_disk.sh *

if (($# == 0))
then
 printf "Syntax is:\n  ./$0 DIRECTORY_OR_FILE_LIST\n" $0
 exit
else
 fns=$@
fi

# Find the maximum length of each filename
max_length=0
for fn in $fns
do
  length=${#fn}
  if ((length > max_length))
  then
    max_length=$length
  fi
done
format_string=`printf "%%%ds %%20s %%20s %%20s%s" $max_length "\n"` # Comment out for spreadsheet
#format_string=`printf "%%s\t%%s\t%%s\t%%s%s" "\n"` # Uncomment for spreadsheet

# Print out the headers
printf "$format_string" Filename "Disk Usage" "Apparent Disk Usage" "Tape/Disk Estimate"

# Print out the disk usage information for each file
units[0]="K"
units[1]="M"
units[2]="G"
units[3]="T"
units[4]="P"
for fn in $fns
do
  if [ ! -e $fn ]
  then
    printf "$format_string" $fn "-" "-" "File Not Found"
    continue;
  fi

  # Get the disk size of this file/directory in kilobytes
  du_val_kb=`du -sk $fn | awk '{print $1}' `
  du_actual_kb=`du -sk --apparent-size $fn | awk '{print $1}' `

  # Unit Conversion to human readable du_val (Comment out for spreadsheet)
  for (( tmp=$du_val_kb,unit_num=0; tmp > 1024; tmp/=1024,unit_num++ ))
  do
  printf "" 
  done
  du_val=`echo $tmp${units[$unit_num]}`
  #Alternate KB format (Uncomment for spreadsheet)
  #du_val=`echo $du_val_kb`

  # Unit conversion to human readable for du_actual (Comment out for spreadsheet)
  for (( tmp=$du_actual_kb,unit_num=0; tmp > 1024; tmp/=1024,unit_num++ ))
  do
  printf "" 
  done
  du_actual=`echo $tmp${units[$unit_num]}`
  #Alternate KB format (Uncomment for spreadsheet)
  #du_actual=`echo $du_actual_kb`
  
  # Print size information to screen
  if ((du_actual_kb > 100*du_val_kb))
  then
    printf "$format_string" $fn $du_val $du_actual "TAPE"
  elif ((du_actual_kb > du_val_kb))
  then
    printf "$format_string" $fn $du_val $du_actual "PART-ON-TAPE"
  else
    printf "$format_string" $fn $du_val $du_actual "DISK"
  fi
done

