#!/usr/bin/env python3

import datetime, getpass, pprint, sys
import json
import requests

baseurl = 'http://{somewhere}/'


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
         for ssName in ssNames:
            print("\t", ssName)
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


if __name__ == "__main__":
   PW = getPW()
   verifyUser(PW)

