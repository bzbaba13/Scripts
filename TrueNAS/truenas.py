#!/usr/bin/env python3

# This script, written in Python 3.6+, performs various tasks via the TrueNAS
# API INSECURELY.  Only HTTP protocol is configured for the TrueNAS I have
# worked with so far unfortunately.  Additional development may be added to
# better format/utilize data retrieved.


import datetime, getopt, getpass, json
import os.path, re, pprint, sys
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
      ds = input('Please enter dataset, e.g., {dataset_path}: ')
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
               '{:%Y-%m-%d-%H:%M}'.format(d)
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

def toomanyactions():
   print("You have specified more than 1 of the exclusive actions.")
   print("Please try again and select only 1 of the exclusive actions.")
   usage()

def usage():
   print(os.path.basename(myprog), "[-e|-m] [-c|-d|-l] [-h] [-i] [-s] [-u]")
   print("\nwhere:")
   print("    NFS (exclusive action)")
   print("\t-e   list Exports")
   print("\t-m   Modify exports")
   print("    Snapshot (exclusive action)")
   print("\t-c   Create snapshot")
   print("\t-d   Delete snapshot")
   print("\t-l   List snapshot(s)")
   print("    System")
   print("\t-i   system Information")
   print("\t-s   fetch all Services")
   print("\t-u   fetch all Users")
   print("    -h  usage (this output)")
   print()
   sys.exit(2)

def main():
   action = None
   verbose = False
   try:
      opts, args = getopt.gnu_getopt(sys.argv[1:], "cdehilmsu")
      if len(opts) < 1:
         usage()
   except getopt.GetoptError as err:
      print(str(err))
      usage()
   for o, a in opts:
      if o == "-h": usage()
      elif o == "-c":
         if action == None:
            action = 'c-ss'
         else:
            toomanyactions()
      elif o == "-d":
         if action == None:
            action = 'd-ss'
         else:
            toomanyactions()
      elif o == "-l":
         if action == None:
            action = 'l-ss'
         else:
            toomanyactions()
      elif o == "-e":
         if action == None:
            action = 'l-exports'
         else:
            toomanyactions()
      elif o == "-i":
         if action == None:
            action = 'g-sysinfo'
         else:
            toomanyactions()
      elif o == "-m":
         if action == None:
            action = 'm-exports'
         else:
            toomanyactions()
      elif o == "-s":
         if action == None:
            action = 'g-services'
         else:
            toomanyactions()
      elif o == "-u":
         if action == None:
            action = 'g-allusers'
         else:
            toomanyactions()
      else:
         assert False, "unhandled option"
         usage()
   PW = getPW()
   checkPW(PW)
   if verbose: print("Verbose output selected...")
   if action == None:
      if verbose:
         print("No action was specified.")
         usage()
   else:
      if action == 'c-ss':
         DSN = getDataset()
         takeSnapshot(PW, DSN)
      elif action == 'd-ss':
         DSN = getDataset()
         delSnapshot(PW, DSN)
      elif action == 'l-ss':
         DSN = getDataset()
         listSnapshot(PW, DSN)
      elif action == 'l-exports':
         displayNFSExports(PW)
      elif action == 'm-exports':
         modifyNFSExports(PW)
      elif action == 'g-sysinfo':
         getSysInfo(PW)
      elif action == 'g-services':
         getAllServices(PW)
      elif action == 'g-allusers':
         getAllUsers(PW)
      else:
         print("Invalid action specified.")
         sys.exit(1)


if __name__ == "__main__":
   main()
