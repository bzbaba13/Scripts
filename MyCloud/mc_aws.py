#!/usr/bin/env python3

import boto3, pprint


def GetCompute():
   client = boto3.client('ec2')
   response = client.describe_instance_status(
      IncludeAllInstances=True
   )
   statuscode = response['ResponseMetadata']['HTTPStatusCode']
   if statuscode == 200:
      pprint.pprint (response['InstanceStatuses'])
      print()
      pprint.pprint (response['ResponseMetadata'])
   else:
      print('Failed to retrieve EC2 data with code: ', str(statuscode))

# for testing purposes
if __name__ == "__main__":
   GetCompute()
