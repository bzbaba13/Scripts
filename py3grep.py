#!/usr/bin/env python3

import re, sys, getopt
import glob


myprog = sys.argv[0]
debug = False
myfile = None
infile = None
pattern = None
no_case = None
reverse_match = None


def usage():
   print(myprog, "[-d] [-h] [-i] [-v] {pattern} {datafile}")
   print("\nwhere:")
   print("\t-d\tdebug information")
   print("\t-h\tthis help screen")
   print("\t-i\tcase insensitive match")
   print("\t-v\treverse match")
   print()

try:
   opts, args = getopt.gnu_getopt(sys.argv[1:], "dhiv")
   if len(args) < 2:
      usage()
      sys.exit(2)
   else:
      pattern = args[0]
      myfile = glob.glob(args[1])
except getopt.GetoptError as err:
   print(str(err))
   usage()
   sys.exit(2)
for o, a in opts:
   if o == "-d":
      debug = True
   elif o == "-h":
      usage()
      sys.exit(2)
   elif o == "-i":
      no_case = True
   elif o == "-v":
      reverse_match = True
   else:
      assert False, "unhandled option"

def main():
   if debug == True:
      print("File:", myfile, " Pattern:", pattern)
   
   for infile in myfile:
      print("========", infile, "========")
      with open(infile, 'r') as f:
         for line in f:
            if no_case == True:
               if reverse_match == True:
                  match = not re.search(pattern, line, flags=re.I)
               else:
                  match = re.search(pattern, line, flags=re.I)
            else:
               if reverse_match == True:
                  match = not re.search(pattern, line)
               else:
                  match = re.search(pattern, line)
            if match:
               print(line, end='')
      print("\n")


if __name__ == "__main__":
   main()