# Usage:
# python3 script.py "https://openqa.suse.de/tests/overview?distri=sle&version=12-SP1&build=20170308-2&groupid=34"
# Do not forget the double quotes in the URL ^^^

import sys
import re
from bs4 import BeautifulSoup
import requests


def fetch_html(url):

  # Extract the link without the protocol
  base_url = re.search('http://(.+?)/', url)

  # If the user types http, turn it into https automatically without asking him
  SSL = False
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
    sys.exit(1)

  # If connections is OK, return the data from openqa page
  return data

def last_previous_url(url):
  ending="#previous"
  url += ending
  data = fetch_html(url)
  soup = BeautifulSoup(data.content, 'html.parser')

  # Parsing for all '<a href'
  previous_test_urls=[]
  for tr in soup.find_all('tr'):
    for span in tr.find_all('span'):
      for a in span.find_all('a', href=True):
        previous_test_urls.append("https://openqa.suse.de{}".format(a['href']))

  return previous_test_urls[0]

def parse_links_from_group_url(url):
  data = fetch_html(url)
  soup = BeautifulSoup(data.content, 'html.parser')

  # Group url
  # ---------
  testsuites_names = []
  for td in soup.find_all('td', id=True):
    testsuites_names.append(td['id'])

  # Parsing for all '<a href'
  testsuites_urls=[]
  for tr in soup.find_all('tr'):
    for span in tr.find_all('span', id=True):
      # TODO: clean this
      # .split('-')[1] -> makes sure that no 'poo' or 'boo' links will interefere
      # .split('#')[0] -> makes sure that no specific step failure (eg.#step/whatever) is going to picked up
      testsuites_urls.append("https://openqa.suse.de/tests/{}".format(span['id'].split('-')[1].split('#')[0]))

  # Mix the two lists into one dictionary structure
  result_dict = dict(zip(testsuites_names, testsuites_urls))
  return result_dict


def parse_results_from_url(url):
  data = fetch_html(url)
  soup = BeautifulSoup(data.content, 'html.parser')

  # Test-module url
  # ---------------
  # Parsing the name of test-modules
  test_modules = []
  for link in soup.find_all('a'):
    # Take only those which have 'modules' in their name and extract their name
    module = re.search('modules/(.+?)/steps', link.get('href'))
    if module:
      testcase = module.group(1)
      test_modules.append(testcase)

  # Parse the results of the test-modules
  results = []
  for td in soup.find_all('td', {'class':'result'}):
    result = td.string
    # Fix the newline issue during printing
    splitted_line = result.strip();
    results.append(splitted_line)

  # Mix the two lists into one dictionary structure
  result_dict = dict(zip(test_modules, results))
  return result_dict

def find_regressions(before, after):
  first_test = 0
  last_test = len (after)
  regressions  = []
  improvements = []
  both_failed  = []

  for result in range(first_test, last_test):
    test = list(after.keys())[result]
    result_before = list(before.values())[result]
    result_after  = list(after.values())[result]

    if result_before == "passed" and result_after == "failed":
      regressions.append(test)

  return regressions

def find_improvements(before, after):
  first_test = 0
  last_test = len (after)
  regressions  = []
  improvements = []
  both_failed  = []

  for result in range(first_test, last_test):
    test = list(after.keys())[result]
    result_before = list(before.values())[result]
    result_after  = list(after.values())[result]

    if result_before == "failed" and result_after == "passed":
      improvements.append(test)

  return improvements


def find_stillFailing(before, after):
  first_test = 0
  last_test = len (after)
  regressions = []
  improvements = []
  both_failed = []

  for result in range(first_test, last_test):
    test = list(after.keys())[result]
    result_before = list(before.values())[result]
    result_after  = list(after.values())[result]

    if result_before == "failed" and result_after == "failed":
      both_failed.append(test)

  return both_failed

def print_results(before, after):
  print("Improvements :",find_improvements(before,after))
  print("Regressions  :",find_regressions(before,after))
  print("Still Failing:",find_stillFailing(before,after))


# ================================================= #
# Main #
# ================================================= #

results = parse_links_from_group_url(sys.argv[1])
for testsuite, url in results.items():
  print("TEST   :",testsuite)
  print("BEFORE :",last_previous_url(url))
  print("AFTER  :",url)
  after  = parse_results_from_url(url)
  before = parse_results_from_url(url)
  print_results(before,after)
  print()
