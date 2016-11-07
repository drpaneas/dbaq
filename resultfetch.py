# Usage:
# python3 testcases.py https://openqa.opensuse.org/tests/300810
# -------------------------------------------------------------

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

# http/https test
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


for td in soup.find_all('td', {'class':'result'}):
    result = td.string
    # Fix the newline issue during printing
    splitted_line = result.strip();
    print(splitted_line)
