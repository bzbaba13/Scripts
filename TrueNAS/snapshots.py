#!/usr/bin/env python2

# == Synopsis
#
# This script, written in Python 2.6+, performs snapshot-related tasks via the
# TrueNAS API INSECURELY.  Only HTTP protocol is available for the version(s)
# of TrueNAS I have worked with so far unfortunately.
#

import datetime, getopt, json
import os.path, re, subprocess, sys
import requests

myprog = sys.argv[0]
v1baseurl = 'http://{fqdn}/api/v1.0/'
v2baseurl = 'http://{fqdn}/api/v2.0/'
vaulturl = 'https://{vault_fqdn}/api/v1/groups/2506/items/11346'


def non200(t):
   print "\nCRITICAL:  Non-200 status code received."
   print t

def httpGet(url, pw, timeo, payl):
   r = requests.get(
      url,
      auth = ('root', pw),
      timeout = timeo,
      params = payl
   )
   return(r)

def httpPost(url, pw, timeo, hdrs, d):
   r = requests.post(
      url,
      auth = ('root', pw),
      timeout = timeo,
      headers = hdrs,
      data = d
   )
   return(r)

def httpPut(url, pw, timeo, hdrs, d):
   r = requests.put(
      url,
      auth = ('root', pw),
      timeout = timeo,
      headers = hdrs,
      data = d
   )
   return(r)

def getVaultKey(verbose, mydir):
   if verbose: print "Attempting to fetch password for snapshot from the Vault..."
   vk = None
   try:
      with open(os.path.join(mydir, "vault_key"), "r") as f:
         vk = f.read().split(':')
   except IOError as err:
      print "\nCritical: unable to read from 'vault_key' file to fetch password from vault."
      print err
      sys.exit(1)
   return(vk)

def getVaultValue(verbose, mydir):
   url = vaulturl
   vk = getVaultKey(verbose,mydir)
   if vk != None:
      r = requests.get(url, auth = (vk[0], vk[1]))
      if r.status_code == 200:
         response = r.json()
         sspw = response['data']['attributes']['value']
      else:
         non200(response.text)
         sys.exit(1)
      return(sspw)
   else:
      print "\nCritical: the value of vault key is None."
      sys.exit(1)

def checkPW(verbose, pw):
   if verbose: print "Verifying password..."
   url = v2baseurl + "auth/check_user"
   timeo = 5
   hdrs = {'Content-Type': 'application/json'}
   data = json.dumps(
      {
         'username': 'root',
         'password': pw,
      }
   )
   response = httpPost(url, pw, timeo, hdrs, data)
   if response.status_code == 200:
      if response.text == 'true':
         if verbose: print "\tVerification succeeded."
      else:
         print "\tCRITICAL: password verification failed.\n"
         sys.exit(1)
   else:
      print "CRITICAL: Incorrect password.  Terminating execution.\n"
      non200(response.text)
      sys.exit(1)

def getNFSpath():
   paths = []
   try:
      entries = subprocess.check_output(
                   "grep nfs /proc/mounts | grep '/mnt/tank' | awk '{ print $1 }'",
                   shell=True
                )
      for line in entries.split("\n"):
         if len(line) > 0:
            paths.append(line.split(':')[1].replace('/mnt/',''))
   except subprocess.CalledProcessError as err:
      print "Unable to locate NFS mount(s) and/or '/mnt/tank'."
      print err
      sys.exit(1)
   return(paths)

def fetchNFSinclusion(mydir):
   inList = []
   try:
      with open(os.path.join(mydir, "ss_includes"), "r") as f:
         for line in f:
            if not re.search("#", line):
               inList.append(line.rstrip("\n"))
   except IOError:
      pass
   return(inList)

def fetchNFSexclusion(mydir):
   exList = []
   try:
      with open(os.path.join(mydir, "ss_excludes"), "r") as f:
         for line in f:
            if not re.search("#", line):
               exList.append(line.rstrip("\n"))
   except IOError:
      pass
   return(exList)

def appendNFSpath(paths, inList):
   for item in inList:
      if len(item) > 0 and item not in paths: paths.append(item)
   return(paths)

def cleanNFSpath(paths, exList):
   for item in exList:
      if item in paths: paths.remove(item)
   return(paths)

def findFinalpath(verbose, mydir):
   paths = getNFSpath()
   if verbose: print "Discovered NFS path(s):", paths
   inList = fetchNFSinclusion(mydir)
   if len(inList) > 0:
      if verbose: print "Inclusion(s):", inList
      added_paths = appendNFSpath(paths, inList)
   else:
      if verbose: print "No inclusion of NFS path specified."
      added_paths = paths
   exList = fetchNFSexclusion(mydir)
   if len(exList) > 0:
      if verbose: print "Exclusion(s):", exList
      finalpaths = cleanNFSpath(added_paths, exList)
   else:
      if verbose: print "No exclusion of NFS path specified."
      finalpaths = paths
   if verbose: print "Final path(s):", finalpaths
   return(finalpaths)

def listSnapshot(verbose, pw, finalpaths):
   finalSSdict = {}
   if verbose:
      print "Fetching list of ZFS snapshot, it may take some time so please be patient..."
   url = v2baseurl + "zfs/snapshot"
   timeo = 90
   response = httpGet(url, pw, timeo, None)
   if verbose: print "Finished fetching list of snapshots."
   if response.status_code == 200:
      ssList = response.json()
      for dsName in finalpaths:
         ssNames = []
         for item in ssList:
            if item['dataset'] == dsName:
               ssNames.append(item['snapshot_name'])
         finalSSdict[dsName] = ssNames
      if verbose:
         print "Final SS dict:", finalSSdict
         for k, v in finalSSdict.items():
            print "Dataset:", k
            if len(v) > 0:
               print "\tSnapshot(s)..."
               for i in sorted(v):
                  print "\t\t", i
               print
            else:
               print "\tNo snapshot(s) found for the dataset.\n"
   else:
      print "Critical:  Failed to fetch list of snapshots from TrueNAS."
      non200(response.text)
      sys.exit(1)
   return(finalSSdict)

def takeSnapshot(verbose, pw, finalpaths):
   if verbose: print "\nTake ZFS snapshot of dataset..."
   d = datetime.datetime.utcnow()
   for dsName in finalpaths:
      ssName = '{}{}{}'.format(
                  dsName.rsplit('/',1)[1], '-', '{:%Y-%m-%d-%H:%M}'.format(d)
               )
      if verbose: print "Name of snapshot:", ssName
      url = v2baseurl + "zfs/snapshot"
      timeo = 10
      hdrs = {'Content-Type': 'application/json'}
      data = json.dumps(
         {
            'dataset': dsName,
            'name': ssName,
            'recursive': False
         }
      )
      response = httpPost(url, pw, timeo, hdrs, data)
      if response.status_code == 200:
         if response.text == 'true':
            if verbose: print "Snapshot", ssName, "taken successfully with dataset:", dsName
         else:
            print "Critical:  Failed to take snapshot of dataset:", dsName
            non200(reresponse.text)
            sys.exit(1)
      else:
         print "Critical:  Non 200 status code received from taking snapshot of", dsName
         non200(response.text)
         sys.exit(1)
   sys.exit(0)

def delSnapshot(verbose, pw, finalSSdict, retention):
   if verbose: print "Retention:", retention
   for k, v in finalSSdict.items():
      diff = len(v) - retention
      if diff > 0:
         delList = []
         v.sort(reverse=True)
         for i in range(diff):
            delList.append(v.pop())
         if len(delList) < 1:
            print "Critical:  Failed to build list of snapshot(s) for deletion."
            sys.exit(1)
         for ssName in delList:
            if verbose: print "Deleting ZFS snapshot:", ssName , "for dataset:", k
            url = v2baseurl + "zfs/snapshot/remove"
            timeo = 10
            hdrs = {'Content-Type': 'application/json'}
            data = json.dumps(
               {
                  'dataset': k,
                  'name': ssName,
               }
            )
            response = httpPost(url, pw, timeo, hdrs, data)
            if response.status_code == 200:
               if response.text == 'true':
                  if verbose:
                     print "Successfully deleted snapshot", ssName, "of dataset:", k
               else:
                  print "\nCritical:  Failed to delete snapshot:", ssName, "of dataset", k
                  sys.exit(1)
            else:
               print "Critical:  Non-200 status code returned from snapshot deletion."
               non200(response.text)
      else:
         if verbose: print "Specified retention value is higher than number of snapshots."
         pass
   sys.exit(0)

def toomanyactions():
   print "You have specified more than 1 of the exclusive actions."
   print "Please try again and select only 1 of the exclusive actions."
   usage()

def usage():
   print os.path.basename(myprog), "[-c | -d # | -l] [-v]"
   print "\nwhere action is one of:"
   print "\t-c    Create snapshot"
   print "\t-d #  Delete snapshot(s) over the retention of # snapshot(s)"
   print "\t-l    List snapshot(s) (verbose output)"
   print "   -h  Usage (this output)"
   print "   -v  Verbose output"
   print
   sys.exit(2)

def main():
   verbose = False
   action = None
   try:
      opts, args = getopt.gnu_getopt(sys.argv[1:], "cd:hlv")
      if len(opts) < 1:
         usage()
   except getopt.GetoptError as err:
      print str(err)
      usage()
   for o, a in opts:
      if o == "-v":
         verbose = True
      elif o == "-c":
         if action == None:
            action = 'create'
         else:
            toomanyactions()
      elif o == "-d":
         if action == None:
            action = 'delete'
            if a.isdigit():
               retention = int(a)
            else:
               print "Retention # provided was not digit(s),",
               print "e.g., '-d 3' for retention of 3 snapshots."
               usage()
         else:
            toomanyactions()
      elif o == "-h":
         usage()
      elif o == "-l":
         if action == None:
            action = 'list'
         else:
            toomanyactions()
         verbose = True
      else:
         assert False, "unhandled option"
         usage()
   if verbose: print "Verbose output selected..."
   if action == None:
      if verbose:
         print "No action was specified."
         usage()
   else:
      mydir = os.path.dirname(myprog)
      PW = getVaultValue(verbose, mydir)
      checkPW(verbose, PW)
      if action == 'create':
         if verbose: print "Creating snapshot..."
         takeSnapshot(verbose, PW, findFinalpath(verbose, mydir))
      elif action == 'delete':
         if verbose: print "Deleting snapshot(s)..."
         delSnapshot(verbose, PW, listSnapshot(verbose, PW, findFinalpath(verbose, mydir)), retention)
      elif action == 'list':
         if verbose: print "Listing snapshot(s)..."
         listSnapshot(verbose, PW, findFinalpath(verbose, mydir))
      else:
         print "Invalid action specified."
         sys.exit(1)

if __name__ == "__main__":
   main()
