#!/usr/bin/env python3

import re
import sys
import getopt


myprog = sys.argv[0]
debug = False
infile = None
pattern = None
no_case = None
reverse_match = None


def usage():
   print (myprog, " [-d] [-f <file>] [-h] [-i] [-p <pattern>] [-v]")
   print ("\nwhere:")
   print ("\t-d\tdebug information")
   print ("\t-f\tinput file")
   print ("\t-h\tthis help screen")
   print ("\t-i\tcase insensitive match")
   print ("\t-p\tpattern")
   print ("\t-v\treverse match")
   print ("")

try:
   opts, args = getopt.gnu_getopt(sys.argv[1:], "df:hip:v")
except getopt.GetoptError as err:
   print (str(err))
   usage ()
   sys.exit (2)
for o, a in opts:
   if o == "-d":
      debug = True
   elif o == "-h":
      usage ()
      sys.exit (2)
   elif o == "-f":
      infile = a
   elif o == "-i":
      no_case = True
   elif o == "-v":
      reverse_match = True
   elif o == "-p":
      pattern = a
   else:
      assert False, "unhandled option"

def main():
   if debug == True:
      print ("Input file:", infile, " Pattern:", pattern)
   
   if pattern == None or infile == None:
      print ("Please provide both pattern (-p) and input file (-f).")
      usage ()
      sys.exit (2)
   
   with open ( infile, 'r' ) as f:
      for line in f:
         if no_case == True:
            if reverse_match == True:
               match = not re.search ( pattern, line, flags=re.I )
            else:
               match = re.search ( pattern, line, flags=re.I )
         else:
            if reverse_match == True:
               match = not re.search( pattern, line )
            else:
               match = re.search( pattern, line )
         if match:
            print ( line, end='' )


if __name__ == "__main__":
   main()

