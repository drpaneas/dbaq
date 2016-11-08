#!/bin/bash
# Usage:
# bash logger.sh https://openqa.suse.de/tests/629120

par_dir=$(/usr/bin/pwd)
url=$1
name=$(echo $url | cut -d '/' -f 5-)
dir="/tmp/dbaq"
work_dir=$dir/$name

if [ ! -d "$dir/$name" ]; then
    echo "planner.sh failed"
    exit 1
fi

echo

wget --quiet $url/file/autoinst-log.txt -O $dir/$name/log

file="$dir/$name/log"
if [ -f "$file" ]
then
  echo "Complete logs can be found at: $file."
else
  echo "Error: couldn't download logs from openqa"
   exit 1
fi

# Variables (Counters)
NUMOFLINES=$(wc -l < "$dir/$name/names")


for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $dir/$name/$counter/test)
    log="$dir/$name/$counter/log"

    if [ -f "$log" ]
    then
        rm -r $log
    fi

    starting=1;
    finished=1
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line == *"starting $testname "* ]]
        then
              line_start=$starting
        fi

        if [[ $line == *"finished $testname "* ]] || [[ $line == *"$testname died"* ]] || [[ $line == *"$testname failed"* ]]
        then
              line_finish=$finished
        fi
    starting=$[$starting +1]
    finished=$[$finished +1]
    done < "$file"


    # TODO: Take into account that some tests are failing secretely
    #       and there is no any 'finished' or 'die' message

#    counter=1
#    while IFS='' read -r keimeno || [[ -n "$keimeno" ]]; do
#      if [[ $counter -gt $line_start ]]
#      then
#          if [[ $keimeno == *"starting"* ]]
#          then
#              break
#          fi
#          echo "$keimeno" >> "$log"
#      fi
#      counter=$[$counter +1]
#    done < "$file"

    counter=1
    while IFS='' read -r grammi || [[ -n "$grammi" ]]; do
      if [[ $counter -gt $line_start ]] && [[ $counter -lt $line_finish ]]
      then
          echo "$grammi" >> "$log"
      fi
      counter=$[$counter +1]
    done < "$file"

done
