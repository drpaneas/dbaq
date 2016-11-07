#!/bin/bash
# Usage:
# bash planner.sh https://openqa.suse.de/tests/629120

par_dir=$(/usr/bin/pwd)
url=$1
name=$(echo $url | cut -d '/' -f 5-)
dir="/tmp/dbaq"
work_dir=$dir/$name

if [ ! -d "$dir/$name" ]; then
    mkdir -p $dir/$name
fi


python3 $par_dir/testfetch.py $url | cut -f1 > $dir/$name/names
python3 $par_dir/testfetch.py $url | cut -f3 > $dir/$name/sources
python3 $par_dir/resultfetch.py $url > $dir/$name/results

NUMOFLINES=$(wc -l < "$dir/$name/names")
i=1
for testname in `cat $dir/$name/names`; do counter=$(printf "%0*d\n" ${#NUMOFLINES} $i); mkdir -p "$dir/$name/$counter"; echo $testname > "$dir/$name/$counter/test"; ((i = i + 1)); done
i=1
for source_code in `cat /$dir/$name/sources`; do counter=$(printf "%0*d\n" ${#NUMOFLINES} $i); wget --quiet $source_code -O "$dir/$name/$counter/source_code.pl"; ((i = i + 1)); done
i=1
for result in `cat /$dir/$name/results`; do counter=$(printf "%0*d\n" ${#NUMOFLINES} $i); echo $result > $dir/$name/$counter/result; ((i = i + 1)); done

echo working dir is $work_dir
echo


