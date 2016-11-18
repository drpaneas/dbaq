#!/bin/bash
# Usage:
# bash debugger.sh https://openqa.suse.de/tests/629120

par_dir=$(/usr/bin/pwd)
url=$1
name=$(echo $url | cut -d '/' -f 5-)
dir="/tmp/dbaq"
work_dir=$dir/$name

if [ ! -d "$work_dir" ]; then
    echo "planner.sh failed"
    exit 1
fi

echo "Producing report ..."


# Variables (Counters)
NUMOFLINES=$(wc -l < "$work_dir/names")


# Create log per testsuite
for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $work_dir/$counter/test)
    log="$work_dir/$counter/log"
    debug="$work_dir/$counter/debug"

    if [ -f "$debug" ]
    then
        rm -r $debug
    fi

    cut -f 1 -d ' ' --complement $log > $debug

    # The $debug file must start with the first APICALL (aka Debug: line)
    # This is not always the case because of openQA garbage in the logs
    # First find the line the first "Debug: " line starts
    start_of_debug_file=$(awk '/Debug/{ print NR; exit }' $debug)
    if [ "$start_of_debug_file" != "1" ]; then
        # Then save the file again, but only the content **after** starting from the first "Debug:" line
        # Save it in a temp file first, and then overwrite it (I don't know if this can be done in 1 step)
        tmp_file="$work_dir/$counter/debug_tmp"
        tail -n +$start_of_debug_file $debug > $tmp_file
        mv $tmp_file $debug
    fi

    # In case of critical failure, openQA finishes the current test with 'failed at' string
    # and then it triggers a series of several tasks that we don't care (serial console tests)
    # So, in case of failure, remove these extra noise
    end_of_debug_file=$(awk '/failed at/{ print NR; exit }' $debug)
    if [ ! -z "$end_of_debug_file" ]; then        # If this variable is not empty, it means it contains the number of line of failure
        tmp_file="$work_dir/$counter/debug_tmp"
        head -n $end_of_debug_file $debug > $tmp_file
        mv $tmp_file $debug
    fi
done


for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $work_dir/$counter/test)
    log="$work_dir/$counter/log"
    debug="$work_dir/$counter/debug"
    debug_lines="$work_dir/$counter/debug_lines"
    debug_commands="$work_dir/$counter/debug_commands"
    debug_sourcelines="$work_dir/$counter/debug_sourcelines"
    debug_outputs="$work_dir/$counter/debug_outputs"
    debug_reports="$work_dir/$counter/debug_reports"
    error="$work_dir/$counter/error"
    source_code="$work_dir/$counter/source_code.pl"


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


    # The test isosize doesn't have any Debug lines
    # it only says: 'check if actual iso size 3170893824 fits 4700372992: ok'
    if [ "$testname" == "isosize" ]; then
      egrep -i "check if actual iso size" $log > $debug
      continue; # Skip the next of the loop, go to the next text
    fi

    # Create log (DEBUG API only) per unit test of the testsuite
    egrep -i 'Debug: ' $debug > $debug_lines

    # Create log (commands only)  per unit test of the testsuite
    egrep -iA 1 'Debug: ' $debug | grep -v -- '--' | egrep -iv 'Debug: ' > $debug_commands

    # Create log (outputs only) per unit test of the testsuite
    egrep -iB 1 'Debug: |died|failed at' $debug | grep -v -- '--' | egrep -iv 'Debug: |died|failed at' > $debug_outputs

    # Create a log (number of lines only) per unit test of the testsuite
    cat $debug_lines  | cut -d':' -f3 | awk '{print $1;}' > $debug_sourcelines



    nol_debug_lines=$(cat $debug_lines | wc -l)       # 3
    nol_command_lines=$(cat $debug_commands | wc -l)  # 3
    nol_debug_outputs=$(cat $debug_outputs | wc -l)   # 4

    if [ "$nol_command_lines" != "$nol_debug_outputs" ]; then
        #lastline=$(grep '>>>' $debug | tail -n 1)
         lastline=$(cat $debug | tail -n 1)
         echo "$lastline" >> $debug_outputs
    fi

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


        # If we are checking the first (1) line of the file, then previous will be 0
        # and sed at 0 line, will fail. So, let's skip the test for the 1 line.
        if [ "$j" != "1" ]; then
            previous_line=$(( ${j}-1 ))
            sed "${previous_line}q;d" $debug_sourcelines &> /dev/null
            if [ $? -eq 0 ]; then
                previous_number_of_line=$(sed "${previous_line}q;d" $debug_sourcelines)
            else
                previous_number_of_line=0
            fi
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

        # Check if the line (e.g. pm::25) is the same as the previous line (e.g. pm::19)
        # if they the same, it means that we are still inside the same API CALL (same Debug: line)
        if [ "$number_of_line" == "$previous_number_of_line" ]; then
            echo "COMMAND: $line2" >> $debug_reports
            echo "OUTPUT : $line3" >> $debug_reports
        # if they are different, we have a new APICALL (a new Debug: line)
        else
          # Don't leave space in the start of the file, doesn't look good
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
