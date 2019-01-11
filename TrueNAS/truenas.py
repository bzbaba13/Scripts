#!/usr/bin/env python3

import datetime, getopt, getpass, pprint, sys
import json
import requests

myprog = sys.argv[0]
baseurl = 'http://{some_address}/'


def non200(t):
   print("\nCRITICAL:  Non-200 status code received.")
   print(t)

def getPW():
   pw = getpass.getpass(
      prompt='Please enter the password of the "root" account: ',
      stream=None
   )
   return pw

def getAllUsers(pw):
   print("\nFetching data of all user accounts...")
   url = baseurl + "api/v2.0/user"
   response = requests.get(
      url,
      auth = ('root', pw),
      timeout = 10,
   )
   if response.status_code == 200:
      pprint.pprint(response.json())
   else:
      non200(response.text)

def getAllServices(pw):
   print("\nFetching data of all services...")
   url = baseurl + "api/v2.0/service"
   response = requests.get(
      url,
      auth = ('root', pw),
      timeout = 10,
   )
   if response.status_code == 200:
      pprint.pprint(response.json())
   else:
      non200(response.text)

def getSysInfo(pw):
   print("\nObtaining system information...")
   url = baseurl + "api/v2.0/system/info"
   response = requests.get(
      url,
      auth = ('root', pw),
      timeout = 10,
   )
   if response.status_code == 200:
      pprint.pprint(response.json())
   else:
      non200(response.text)

def getDataset():
   dsName = input('Please enter dataset, e.g., tank/fYP/DEV/fma_test: ')
   return(dsName)

def delSnapshot(pw,dsName):
   print("\nDeleting ZFS snapshot:", dsName, "for dataset:", dsName)
   ssName = input('Please enter name of snapshot: ')
   url = baseurl + "api/v2.0/zfs/snapshot/remove"
   response = requests.post(
      url,
      auth = ('root', pw),
      timeout = 10,
      headers = {'Content-Type': 'application/json'},
      data = json.dumps(
         {
            'dataset': dsName,
            'name': ssName,
         }
      )
   )
   if response.status_code == 200:
      if response.text == 'true':
         print("\tSuccessfully deleted snapshot", ssName, "of dataset:", dsName)
      else:
         print("\tWARNING: Failed to delete snapshot:", ssName, "of dataset", dsName)
   else:
      non200(response.text)

def getSnapshot(pw,dsName):
   print("\nLooking up ZFS snapshot for dataset:", dsName)
   print("It may take some time so please be patient...")
   url = baseurl + "api/v2.0/zfs/snapshot"
   response = requests.get(
      url,
      auth = ('root', pw),
      timeout = 60,
   )
   if response.status_code == 200:
      ssList = response.json()
      ssNames = []
      for item in ssList:
         if item['dataset'] == dsName:
            ssNames.append(item['snapshot_name'])
      if len(ssNames) > 0:
         print("Snapshot(s)...")
         for ssName in ssNames:
            print("\t", ssName)
         print()
      else:
         print("\tNo snapshot(s) found for the dataset.\n")
   else:
      non200(response.text)

def takeSnapshot(pw):
   print("\nAttempting to take ZFS snapshot of dataset...")
   dsName = input('Please enter the dataset: ')
   d = datetime.datetime.utcnow()
   ssName = '{}{}{}'.format(
               dsName.rsplit(sep='/',
               maxsplit=1)[1], '-',
               '{:%Y-%m-%d-%H:%M:%S}'.format(d)
            )
   print("Name of snapshot:", ssName)
   url = baseurl + "api/v2.0/zfs/snapshot"
   response = requests.post(
      url,
      auth = ('root', pw),
      timeout = 10,
      headers = {'Content-Type': 'application/json'},
      data = json.dumps(
         {
            'dataset': dsName,
            'name': ssName,
            'recursive': False
         }
      )
   )
   if response.status_code == 200:
      if response.text == 'true':
         print("\tSnapshot taken successfully with dataset:", dsName)
      else:
         print("\n\tWARNING:  Failed to take snapshot of dataset:", dsName)
   else:
      non200(response.text)
   return(dsName)

def verifyUser(pw):
   print("\nVerifying entered password...")
   url = baseurl + "api/v2.0/auth/check_user"
   response = requests.post(
      url,
      auth = ('root', pw),
      timeout = 10,
      headers = {'Content-Type': 'application/json'},
      data = json.dumps(
         {
            'username': 'root',
            'password': pw,
         }
      )
   )
   if response.status_code == 200:
      if response.text == 'true':
         print("Verification of user succeeded.")
      else:
         print("Verification of user failed.")
   else:
      non200(response.text)

def usage():
   print(myprog, "[-c] [-d] [-i] [-l] [-s] [-u]")
   print("\nwhere:")
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
   opts, args = getopt.gnu_getopt(sys.argv[1:], "cdilsu")
   if len(opts) < 1:
      usage()
except getopt.GetoptError as err:
   print(str(err))
   usage()
   sys.exit(2)
PW = getPW()
for o, a in opts:
   if o == "-c":
      DSN = takeSnapshot(PW)
      getSnapshot(PW,DSN)
   elif o == "-d":
      DSN = getDataset()
      delSnapshot(PW,DSN)
   elif o == "-h":
      usage()
   elif o == "-i":
      getSysInfo(PW)
   elif o == "-l":
      DSN = getDataset()
      getSnapshot(PW,DSN)
   elif o == "-s":
      getAllServices(PW)
   elif o == "-u":
      getAllUsers(PW)
   else:
      usage()
