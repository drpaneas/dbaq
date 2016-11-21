#!/usr/bin/python

import sys
import os

first_arg = sys.argv[1]

def endswith(line, char):
  idx = -1
  if line[-1] == "\n":
    idx = -2
  return line[idx] == char

if not os.path.exists(first_arg):
  print("Not a file: {0}".format(first_arg))
  sys.exit(1)

with open(first_arg) as f:
    lines = f.readlines()
    mod_lines = []
    flag = False
    for line in lines:
        if "<<<" in line:
            flag = True

        if flag:
            if not endswith(line, ")"):
                mod_lines.append(line.rstrip("\n"))
            else:
                mod_lines.append(line)
                flag = False
        else:
            mod_lines.append(line)

    contents = ''.join(mod_lines)
    sys.stdout.write(contents)
