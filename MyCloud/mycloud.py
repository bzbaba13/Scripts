#!/usr/bin/env python3

import pprint, getopt, sys
import mc_aws

myprog = sys.argv[0]
defaultRegion = 'us-west-1'

def usage():
   print(myprog, "[-h] [-r {region}] [-v] {pattern}")
   print("\nwhere:")
   print("\t-h\tthis help screen")
   print("\t-r\tregion")
   print("\t-v\tverbose")
   print()

try:
   opts, args = getopt.gnu_getopt(sys.argv[1:], "hr:v")
   if len(args) < 2:
      usage()
      sys.exit(2)
   else:
      pattern = args[0]
except getopt.GetoptError as err:
   print(str(err))
   usage()
   sys.exit(2)
for o, a in opts:
   if o == "-h":
      usage()
      sys.exit(2)
   elif o == "-r":
      defaultRegion = a
   elif o == "-v":
      verbose = True
   else:
      assert False, "unhandled option"

#class ComputeInstance:
#   def __init__(self, id, name, cur_state,
#                priv_dns, priv_ip,
#                pub_dns, pub_ip):
#      self.id = id
#      self,name = name
#      self.state = cur_state
#      self.priv_dns = priv_dns
#      self.priv_ip = priv_ip
#      self.pub_dns = pub_dns
#      self.pub_ip = pub_ip

#def main():


#if __name__ == "__main__":
