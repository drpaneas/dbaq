#!/bin/bash
# Usage:
# bash summary.sh https://openqa.suse.de/tests/629120

# Colors for the output
red='\033[0;31m'
green='\033[1;32m'
blue='\033[0;34m'
NC='\033[0m' # No Color
bold=`tput bold`
normal=`tput sgr0`
yellow=$(tput setaf 3)

par_dir=$(/usr/bin/pwd)
url=$1
name=$(echo $url | cut -d '/' -f 5-)
dir="/tmp/dbaq"
work_dir=$dir/$name

bash planner.sh $url
bash logger.sh $url
bash debugger.sh $url

if [ ! -d "$work_dir" ]; then
    echo "planner.sh failed"
    exit 1
fi

echo

# Variables (Counters)
NUMOFLINES=$(wc -l < "$work_dir/names")
PASS=0
FAIL=0


# Delete {passed,failed}.sum if they exist from a previous run
file="$work_dir/passed.sum"
if [ -f "$file" ]
then
  rm $file
fi

file="$work_dir/failed.sum"
if [ -f "$file" ]
then
  rm $file
fi

for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $work_dir/$counter/test)
    testresult=$(cat $work_dir/$counter/result)

    if [ "$testresult" == "passed" ]; then
        PASS=$((PASS+1))
        echo $testname >> $work_dir/passed.sum
        echo -e "TEST $counter: ${yellow}$testname${NC} -> ${green}$testresult${NC}"
    elif [ "$testresult" \> "$failed" ]; then
        FAIL=$((FAIL+1))
        echo $testname >> $work_dir/failed.sum
        echo -e "TEST $counter: ${yellow}$testname${NC} -> ${red}$testresult${NC}"
    fi

done


# Check for failures
echo
if [ $FAIL -ne 0 ]; then
    FAILED_TESTS=$(cat $work_dir/failed.sum)
    echo "${bold} Failed tests${normal}"
    echo "${bold}--------------${normal}"
    for eachtest_failed in $FAILED_TESTS; do
        # TODO
        # Provide debugging files
        dir_of_failed=$(grep -rwn $work_dir/ -e "$eachtest_failed" | awk 'BEGIN { FS="./names:"; } { print $2; }' | cut -d ':' -f1)
        if [ -f "$work_dir/$dir_of_failed/error" ]; then
            echo -e "- ${red} $eachtest_failed ${NC} => $(cat $work_dir/$dir_of_failed/error)"
            echo -e "   sourcecode: ${blue}$work_dir/$dir_of_failed/source_code.pl${NC}  log: ${red} $work_dir/$dir_of_failed/log ${NC} report: ${red} $work_dir/$dir_of_failed/debug_reports ${NC}"
        else
            echo -e "- ${red} $eachtest_failed ${NC} => No openQA failure message was found in the logs"
            echo -e "   sourcecode: ${blue}$work_dir/$dir_of_failed/source_code.pl${NC}  log: ${red} $work_dir/$dir_of_failed/log ${NC} report: ${red} $work_dir/$dir_of_failed/debug_reports ${NC}"
        fi
    done

fi




# Summary
echo
echo "${bold} Summary of test results${normal}"
echo "=========================${normal}"
echo -e "+ PASSED : $PASS (${green}$work_dir/passed.sum${NC})"
echo -e "- FAILED : $FAIL (${red}$work_dir/failed.sum${NC})"
echo
