#!/bin/bash
# Usage:
# bash debugger.sh https://openqa.suse.de/tests/629120

par_dir=$(/usr/bin/pwd)
url=$1
name=$(echo $url | cut -d '/' -f 5-)
dir="/tmp/dbaq"
work_dir=$dir/$name

if [ ! -d "$dir/$name" ]; then
    echo "planner.sh failed"
    exit 1
fi

echo "Producing report ..."


# Variables (Counters)
NUMOFLINES=$(wc -l < "$dir/$name/names")


# Create log per testsuite
for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $dir/$name/$counter/test)
    log="$dir/$name/$counter/log"
    debug="$dir/$name/$counter/debug"

    if [ -f "$debug" ]
    then
        rm -r $debug
    fi

    cut -f 1 -d ' ' --complement $log > $debug
done


for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $dir/$name/$counter/test)
    log="$dir/$name/$counter/log"
    debug="$dir/$name/$counter/debug"
    debug_lines="$dir/$name/$counter/debug_lines"
    debug_commands="$dir/$name/$counter/debug_commands"
    debug_outputs="$dir/$name/$counter/debug_outputs"
    debug_reports="$dir/$name/$counter/debug_reports"
    error="$dir/$name/$counter/error"

    if [ -f "$debug_lines" ]
    then
        rm -r $debug_lines
    fi

    if [ -f "$debug_commands" ]
    then
        rm -r $debug_commands
    fi

    if [ -f "$debug_outputs" ]
    then
        rm -r $debug_outputs
    fi

    if [ -f "$debug_reports" ]
    then
        rm -r $debug_reports
    fi

    # Create log (DEBUG API only) per unit test of the testsuite
    egrep -i Debug $debug > $debug_lines

    # Create log (commands only)  per unit test of the testsuite
    egrep -iA 1 Debug $debug | grep -v -- '--' | egrep -iv Debug > $debug_commands

    # Create log (outputs only) per unit test of the testsuite
    egrep -iB 1 Debug $debug | grep -v -- '--' | egrep -iv Debug > $debug_outputs

    if egrep -i ' failed ' $debug &> /dev/null ; then
        egrep -iB 1 ' failed ' $debug | awk '{print $1;}' | head -n 1 > $error
    fi

    NUMOFDEBUGLINES=$(wc -l < "$debug_lines")
    for (( j=1; j<=$NUMOFDEBUGLINES; j++ )); do
        line1=$(sed "${j}q;d" $debug_lines)
        line2=$(sed "${j}q;d" $debug_commands)
        line3=$(sed "${j}q;d" $debug_outputs)


        if [ "$line3" == "$line2" ]; then
            line3="User Input (no output is expected here)"
        fi

        echo "APICALL: $line1" >> $debug_reports
        echo "COMMAND: $line2" >> $debug_reports
        echo "OUTPUT : $line3" >> $debug_reports
        echo >> $debug_reports
    done
done
