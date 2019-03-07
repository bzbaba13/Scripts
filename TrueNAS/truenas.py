#!/usr/bin/env python3

# This script, written in Python 3.6+, performs various tasks via the TrueNAS
# API INSECURELY.  Only HTTP protocol is available for the version(s) of
# TrueNAS I have worked with so far unfortunately.  Additional development
# may be added to better format/utilize data retrieved.  Due to the
# execution/wait time of certain API calls, e.g., listing snapshots, is
# intentially programmed not to be combined.


import datetime, getopt, getpass
import re, pprint, sys
import json
import requests

myprog = sys.argv[0]
v1baseurl = 'http://{fqdn}/api/v1.0/'
v2baseurl = 'http://{fqdn}/api/v2.0/'


def non200(t):
   print("\nCRITICAL:  Non-200 status code received.")
   print(t)

def getPW():
   pw = getpass.getpass(
      prompt='Please enter the password of the "root" account: ',
      stream=None
   )
   return(pw)

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

def checkPW(pw):
   print("Verifying entered password...")
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
         print("\tVerification succeeded.")
      else:
         print("\tCRITICAL: password verification failed.\n")
         sys.exit(1)
   else:
      non200(response.text)
      print("CRITICAL: Incorrect password entered.  Terminating execution.\n")
      sys.exit(1)

def getAllUsers(pw):
   print("\nFetching data of all user accounts...")
   url = v2baseurl + "user"
   timeo = 10
   response = httpGet(url, pw, timeo, None)
   if response.status_code == 200:
      pprint.pprint(response.json())
   else:
      non200(response.text)

def getAllServices(pw):
   print("\nFetching data of all services...")
   url = v2baseurl + "service"
   timeo = 10
   response = httpGet(url, pw, timeo, None)
   if response.status_code == 200:
      pprint.pprint(response.json())
   else:
      non200(response.text)

def getSysInfo(pw):
   print("\nObtaining system information...")
   url = v2baseurl + "system/info"
   timeo = 10
   response = httpGet(url, pw, timeo, None)
   if response.status_code == 200:
      pprint.pprint(response.json())
      print()
   else:
      non200(response.text)

def getDataset():
   for i in range(3):
      ds = input('Please enter dataset, e.g., tank/fYP/DEV/fma_test: ')
      if i == 2 and len(ds) < 1:
         print("\nNo dataset entered aftet 3 times.  Aborting.\n")
         sys.exit(1)
      elif i <= 2 and len(ds) > 0:
         return(ds)

def delSnapshot(pw, dsName):
   print("\nDeleting ZFS snapshot:", dsName, "for dataset:", dsName)
   ssName = input('Please enter name of snapshot: ')
   url = v2baseurl + "zfs/snapshot/remove"
   timeo = 10
   hdrs = {'Content-Type': 'application/json'}
   data = json.dumps(
      {
         'dataset': dsName,
         'name': ssName,
      }
   )
   response = httpPost(url, pw, timeo, hdrs, data)
   if response.status_code == 200:
      if response.text == 'true':
         print("\tSuccessfully deleted snapshot", ssName, "of dataset:", dsName)
      else:
         print("\tWARNING: Failed to delete snapshot:", ssName, "of dataset", dsName)
   else:
      non200(response.text)
   sys.exit(0)

def listSnapshot(pw, dsName):
   print("\nLooking up ZFS snapshot for dataset:", dsName)
   print("It may take some time so please be patient...")
   url = v2baseurl + "zfs/snapshot"
   timeo = 90
   response = httpGet(url, pw, timeo, None)
   if response.status_code == 200:
      ssList = response.json()
      ssNames = []
      for item in ssList:
         if item['dataset'] == dsName:
            ssNames.append(item['snapshot_name'])
      if len(ssNames) > 0:
         print("Snapshot(s)...")
         for ssName in sorted(ssNames):
            print("\t", ssName)
         print()
      else:
         print("\tNo snapshot(s) found for the dataset.\n")
   else:
      non200(response.text)
   sys.exit(0)

def takeSnapshot(pw, dsName):
   print("\nTake ZFS snapshot of dataset...")
   d = datetime.datetime.utcnow()
   ssName = '{}{}{}'.format(
               dsName.rsplit(sep='/',
               maxsplit=1)[1], '-',
               '{:%Y-%m-%d-%H:%M:%S}'.format(d)
            )
   print("Name of snapshot:", ssName)
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
         print("\tSnapshot taken successfully with dataset:", dsName)
      else:
         print("\n\tWARNING:  Failed to take snapshot of dataset:", dsName)
   else:
      non200(response.text)
   sys.exit(0)

def getNFSExports(pw,ptrn):
   print("\nFetch NFS Exports information...")
   url = v1baseurl + "sharing/nfs/"
   timeo = 10
   payld = {'limit': 0}
   response = httpGet(url, pw, timeo, payld)
   if response.status_code == 200:
      return(response.json())
   else:
      non200(response.text)
      return(None)

def displayNFSExports(pw):
   print()
   ptrn = input('Please enter NFS path pattern (case sensitive): ')
   fullList = []
   foundList = []
   fullList = getNFSExports(pw,ptrn)
   for item in fullList:
      match = re.search(ptrn, str(item['nfs_paths']))
      if match:
         foundList.append(item)
   if len(foundList) > 0:
      pprint.pprint(foundList)
   else:
      print("\tNo data matching", ptrn, "can be found.")
   print()

def modifyNFSExports(pw):
   print()
   ptrn = input('Please enter NFS path pattern (case sensitive): ')
   fullList = []
   foundDict= {}
   goodIDs = []
   badIDs = []
   fullList = getNFSExports(pw,ptrn)
   for item in fullList:
      match = re.search(ptrn, str(item['nfs_paths']))
      if match:
         foundDict[item['id']] = [ item['nfs_paths'], item['nfs_hosts'], item['nfs_ro'] ]
   if len(foundDict) < 1:
      print("\tNo data matching", ptrn, "can be found.  Exiting.\n")
      sys.exit(0)
   else:
      print("Found the following entry/ies (ID, NFS path, NFS client(s) (if exists), & Read_Only?)...")
      pprint.pprint(foundDict)
      print("\nPlease enter the ID(s) (1st column) of the NFS path(s) you would like modify")
      print("separated by space between multiple IDs for batch modification:")
      myIDs = input()
      exIDs = myIDs.split()
      for exID in exIDs:
         if exID.isdigit() and int(exID) in foundDict.keys():
            goodIDs.append(exID)
         else:
            badIDs.append(exID)
      if len(badIDs) > 0:
         print("The following entered value(s) is/are invalid and is/are ignored:")
         print("\t", str(badIDs))
      if len(goodIDs) > 0:
         print("\nProceeding with the following ID(s) is/are:", goodIDs)
         newNFSclients = input('Please enter new space-separated NFS client(s): ')
         for Id in goodIDs:
            print("\nWorking on", Id, foundDict[int(Id)][0], "...")
            url = v1baseurl + "sharing/nfs/" + Id + "/"
            timeo = 30
            hdrs = {'Content-Type': 'application/json'}
            data = json.dumps(
               {
                  "nfs_hosts": newNFSclients
               }
            )
            response = httpPut(url, pw, timeo, hdrs, data)
            if response.status_code == 200:
               print("\nSuccessfully modified list of NFS client(s) of", Id)
               pprint.pprint(response.json())
            else:
               non200(response.text)
         print("\nAll ID(s) processed.\n")
      else:
         print("None of the entered ID(s) is valid.  Exiting.\n")
         sys.exit(1)

def usage():
   print(myprog, "[-e|-m] [-c|-d|-l] [-i] [-s] [-u]")
   print("\nwhere:")
   print("    NFS")
   print("\t-e   list Exports")
   print("\t-m   Modify exports")
   print("    Snapshot")
   print("\t-c   Create snapshot")
   print("\t-d   Delete snapshot")
   print("\t-l   List snapshot(s)")
   print("    System")
   print("\t-i   system Information")
   print("\t-s   fetch all Services")
   print("\t-u   fetch all Users")
   print()
   sys.exit(2)

try:
   opts, args = getopt.gnu_getopt(sys.argv[1:], "cdeilmsu")
   if len(opts) < 1:
      usage()
except getopt.GetoptError as err:
   print(str(err))
   usage()
   sys.exit(2)
PW = getPW()
checkPW(PW)
for o, a in opts:
   if o == "-c":
      DSN = getDataset()
      takeSnapshot(PW, DSN)
   elif o == "-d":
      DSN = getDataset()
      delSnapshot(PW, DSN)
   elif o == "-e":
      displayNFSExports(PW)
   elif o == "-i":
      getSysInfo(PW)
   elif o == "-l":
      DSN = getDataset()
      listSnapshot(PW, DSN)
   elif o == "-m":
      modifyNFSExports(PW)
   elif o == "-s":
      getAllServices(PW)
   elif o == "-u":
      getAllUsers(PW)
   else:
      usage()
