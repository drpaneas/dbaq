# dbaq:
openQA log &amp; test parser written for debugging.

# Description:
In openQA there's a huge pile of logs written in one single file called `autoinst-log.txt `.
Using `dbaq` you achieve two levels of verbosity.

  1. You have isolated `logs` for each `testsuite`
  2. Report analysis consisting (3 lines) per unit-test of each test of each testsuite.

    - API Call:
    - System's command that is triggered
    - Output of the system's command

# Requirements:
- python3
- wget
- python3-certifi
- python3-beautifulsoup4
- python3-requests
- python3-pyparsing

# Usage:
`./summary.sh $openqalink`

for example:
`bash summary.sh https://openqa.suse.de/tests/628142`

