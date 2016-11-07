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

if [ ! -d "$dir/$name" ]; then
    echo "planner.sh failed"
    exit 1
fi

echo

# Variables (Counters)
NUMOFLINES=$(wc -l < "$dir/$name/names")
PASS=0
FAIL=0


# Delete {passed,failed}.sum if they exist from a previous run
file="$dir/$name/passed.sum"
if [ -f "$file" ]
then
  rm $file
fi

file="$dir/$name/failed.sum"
if [ -f "$file" ]
then
  rm $file
fi

for (( i=1; i<=$NUMOFLINES; i++ )); do
    counter=$(printf "%0*d\n" ${#NUMOFLINES} $i)
    testname=$(cat $dir/$name/$counter/test)
    testresult=$(cat $dir/$name/$counter/result)

    if [ "$testresult" == "passed" ]; then
        PASS=$((PASS+1))
        echo $testname >> $dir/$name/passed.sum
        echo -e "TEST $counter: ${yellow}$testname${NC} -> ${green}$testresult${NC}"
    elif [ "$testresult" \> "$failed" ]; then
        FAIL=$((FAIL+1))
        echo $testname >> $dir/$name/failed.sum
        echo -e "TEST $counter: ${yellow}$testname${NC} -> ${red}$testresult${NC}"
    fi

done


# Check for failures
echo
if [ $FAIL -ne 0 ]; then
    FAILED_TESTS=$(cat $dir/$name/failed.sum)
    echo "${bold} Failed tests${normal}"
    echo "${bold}--------------${normal}"
    for eachtest_failed in $FAILED_TESTS; do
        # TODO
        # Provide debugging files
        dir_of_failed=$(grep -rwn $dir/$name/ -e "$eachtest_failed" | awk 'BEGIN { FS="./names:"; } { print $2; }' | cut -d ':' -f1)
        echo -e "- ${red} $eachtest_failed ${NC} failed (${blue}$dir/$name/$dir_of_failed/source_code.pl${NC})  logs: ${red} $dir/$name/$dir_of_failed/log ${NC} "
    done
fi




# Summary
echo
echo "${bold} Summary of test results${normal}"
echo "=========================${normal}"
echo -e "+ PASSED : $PASS (${blue}$dir/$name/passed.sum${NC})"
echo -e "- FAILED : $FAIL (${blue}$dir/$name/failed.sum${NC})"
echo
