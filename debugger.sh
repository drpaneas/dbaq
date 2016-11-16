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
    debug_sourcelines="$dir/$name/$counter/debug_sourcelines"
    debug_outputs="$dir/$name/$counter/debug_outputs"
    debug_reports="$dir/$name/$counter/debug_reports"
    error="$dir/$name/$counter/error"
    source_code="$dir/$name/$counter/source_code.pl"


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
    egrep -iB 1 'Debug|died' $debug | grep -v -- '--' | egrep -iv 'Debug|died' > $debug_outputs

    # Create a log (number of lines only) per unit test of the testsuite
    cat $debug_lines  | cut -d':' -f3 | awk '{print $1;}' > $debug_sourcelines



    if egrep -i ' failed ' $debug &> /dev/null ; then
        egrep -i ' failed ' $debug | head -n 1 > $error
    fi



#    echo "Testname" $testname
#    echo "----------------------------------------"


    NUMOFDEBUGLINES=$(wc -l < "$debug_lines")
    for (( j=1; j<=$NUMOFDEBUGLINES; j++ )); do
        line1=$(sed "${j}q;d" $debug_lines)
        line2=$(sed "${j}q;d" $debug_commands)
        line3=$(sed "${j}q;d" $debug_outputs)

        number_of_line=$(sed "${j}q;d" $debug_sourcelines)
        line4=$(sed "${number_of_line}q;d" $source_code)


        if [ "$line3" == "$line2" ]; then
            line3="User Input (no output is expected here)"
        fi


        previous_line=$(( ${j}-1 ))
        sed "${previous_line}q;d" $debug_sourcelines &> /dev/null
        if [ $? -eq 0 ]; then
            previous_number_of_line=$(sed "${previous_line}q;d" $debug_sourcelines)
        else
            previous_number_of_line=0
        fi

        #echo current line $number_of_line and previous line is $previous_number_of_line

        if [[ $line2 == *"testapi"* ]]; then
          line2_edit=$(echo $line2 | awk 'BEGIN {FS="::"} {print $2}')
          line2=$line2_edit
        fi

        if [[ $line3 == *"testapi"* ]]; then
          line3_edit=$(echo $line3 | awk 'BEGIN {FS="::"} {print $2}')
          line3=$line3_edit
        fi

        if [ "$number_of_line" == "$previous_number_of_line" ]; then
            echo "COMMAND: $line2" >> $debug_reports
            echo "OUTPUT : $line3" >> $debug_reports
        else
          #echo "APICALL: $line1" >> $debug_reports
          if [ "$j" != 1 ]; then
            echo >> $debug_reports
          fi
          echo "APICALL: $line4" >> $debug_reports
          echo "======================================================================" >> $debug_reports
          echo "COMMAND: $line2" >> $debug_reports
          echo "OUTPUT : $line3" >> $debug_reports
        fi
        echo >> $debug_reports
    done
done
