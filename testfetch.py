# Usage:
# python3 testfetch.py https://openqa.opensuse.org/tests/300810
# -------------------------------------------------------------
# pipe ('|') the output as follows:
# * Names only: cut -f1
# * Souce code openqa links: cut -f2
# * Souce code txt links: cut -f3

import sys
import re
from bs4 import BeautifulSoup
import requests

url = sys.argv[1]


SSL = False
base_url = re.search('http://(.+?)/', url)

# If SSL if Enabled on the openqa server
if 'https://' in url:
    base_url = re.search('https://(.+?)/', url)
    protocol = "https://"

# The user has to type either http or https in front of the URL
if base_url:
    openqa_server = base_url.group(1)
    protocol = "http://"
else:
    print("Error: Please type 'http(s)://' in front of your link")
    sys.exit(1)

# Connectivity test
try:
    data = requests.get(url)
except:
    print ("Error: Cannot access the openqa server", url)
    sys.exit(2)


soup = BeautifulSoup(data.content, 'html.parser')

# Parsing for all '<a href'
for link in soup.find_all('a'):
    # Take only those which have 'modules' in their name and extract their name
    module = re.search('modules/(.+?)/steps', link.get('href'))
    if module:
        testcase = module.group(1)
        print(testcase, "\t" + protocol + openqa_server + link.get('href') + "\t" + protocol + openqa_server + link.get('href') + ".txt")
