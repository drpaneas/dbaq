from pyparsing import *
import re
import sys

#grammar = Word('sub') + Word('run') +'(' + ')' + '{'
grammar = Word('sub') + Word('run') + '{'
grammar2 = Word('}')

filename = sys.argv[1]

i = 0
with open(filename) as file:
    for line in file:
        i += 1
        try:
            grammar.parseString(line, parseAll=True)
            start = i
        except:
            pass

print(start)

i = 0
with open(filename) as file:
    for line in file:
        i += 1
        try:
            grammar2.parseString(line, parseAll=True)
            finish = i
            break
        except:
            pass

print(finish)


i = 0
with open(filename) as file:
    for line in file:
        i += 1
        if i > start and i < finish:
            print(line, end="", flush=True)

