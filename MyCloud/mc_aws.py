# This is the AWS portion of the MyCloud application.
# Python 3.6 or newer is required for execution.

import boto3, pprint, json

verbose = False

def GetAllEC2InstanceStatus():
   client = boto3.client('ec2')
   response = client.describe_instance_status(
      IncludeAllInstances=True
   )
   statuscode = response['ResponseMetadata']['HTTPStatusCode']
   if statuscode == 200:
      for instance in response['InstanceStatuses']:
         print('ID: %(id)s\t\tState: %(state)s' %
               {'id': instance['InstanceId'],
                'state': instance['InstanceState']['Name']}
         )
      if verbose == True:
         print()
         pprint.pprint(response['ResponseMetadata'])
   else:
      print('Failed to retrieve EC2 data with code: ', str(statuscode))

def GetAllEC2Instances():
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.all()
   for instance in instances:
      print(instance.id, instance.tags, instance.state)

def GetAllStoppedEC2Instances():
   IdList = []
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['stopped']}]
   )
   for instance in instances:
      IdList.append(instance.id)
      print(instance.id, instance.tags, instance.state)
   return(IdList)

def GetAllRunningEC2Instances():
   IdList = []
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
   )
   for instance in instances:
      IdList.append(instance.id)
      print(instance.id, instance.tags, instance.state)
   return(IdList)

def StartAllStoppedEC2Instances(myids):
   ec2 = boto3.resource('ec2')
   ec2.instances.filter(InstanceIds=myids).start()
   ec2.instance.wait_until_running()

def StopAllStoppedEC2Instances(myids):
   ec2 = boto3.resource('ec2')
   ec2.instances.filter(InstanceIds=myids).stop()

def GetIAMUser():
   pages = dict()
   iam = boto3.client('iam')
   paginator = iam.get_paginator('list_users')
   for response in paginator.paginate():
      pages = response
   statuscode = pages['ResponseMetadata']['HTTPStatusCode']
   if statuscode == 200:
      pprint.pprint(pages['Users'])
      if verbose == True:
         pprint.pprint(pages["InstanceStatuses"])
   else:
      print('Failed to retrieve IAM User data with code: ', str(statuscode))


# for testing purposes
if __name__ == "__main__":
   GetAllEC2InstanceStatus()
#   GetAllEC2Instances()
#   myids = GetAllStoppedEC2Instances()
#   StartAllStoppedEC2Instances(myids)
#   myids = GetAllRunningEC2Instances()
#   StopAllStoppedEC2Instances(myids)
#   GetIAMUser()
