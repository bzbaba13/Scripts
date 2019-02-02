#!/usr/bin/env python3

# This script, written in Python 3.6+, performs various tasks via the TrueNAS
# API.  Additional development may be added to better format/utilize
# data returned by API.  Due to the execution/wait time of certain API calls,
# e.g., listing snapshots, is intentially
# programmed not to be combined.


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
   print("\nAttempting to take ZFS snapshot of dataset...")
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

def getNFSExports(pw):
   print("\nFetching NFS Exports information...")
   ptrn = input('Please enter path pattern (case sensitive): ')
   exList = []
   url = v1baseurl + "sharing/nfs/"
   timeo = 10
   payld = {'limit': 9999}
   response = httpGet(url, pw, timeo, payld)
   if response.status_code == 200:
      exList = response.json()
      for item in exList:
         match = re.search(ptrn, str(item['nfs_paths']))
         if match:
            pprint.pprint(item)
      print()
   else:
      non200(response.text)

def usage():
   print(myprog, "[-e] [-c|d|l] [-i] [-s] [-u]")
   print("\nwhere:")
   print("    NFS")
   print("\t-e   Exports")
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
   opts, args = getopt.gnu_getopt(sys.argv[1:], "cdeilsu")
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
      getNFSExports(PW)
   elif o == "-i":
      getSysInfo(PW)
   elif o == "-l":
      DSN = getDataset()
      listSnapshot(PW, DSN)
   elif o == "-s":
      getAllServices(PW)
   elif o == "-u":
      getAllUsers(PW)
   else:
      usage()
