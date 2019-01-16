# This is the AWS portion of the MyCloud application.
# Python 3.6 is required for execution.

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
      print()
   else:
      print('Failed to retrieve EC2 data with code: ', str(statuscode))

def GetAllEC2Instances():
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.all()
   for instance in instances:
      print(instance.id, instance.tags, instance.state)

def GetAllStoppedEC2Instances():
   print("Looking for all stopped/stopping instances...")
   IdList = []
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['stopped', 'stopping']}]
   )
   for instance in instances:
      IdList.append(instance.id)
      print(instance.id, instance.tags, instance.state)
   if len(IdList) == 0:
      print("No instances with state of 'stopped'/'stopping' found.\n")
   else:
      print()
   return(IdList)

def GetAllRunningEC2Instances():
   print("Looking for all running instances...")
   IdList = []
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
   )
   for instance in instances:
      IdList.append(instance.id)
      print(instance.id, instance.tags, instance.state)
   if len(IdList) == 0:
      print("No instances with state of 'running' found.\n")
   else:
      print()
   return(IdList)

def StartAllStoppedEC2Instances(myids):
   ec2 = boto3.resource('ec2')
   response = ec2.instances.filter(InstanceIds=myids).start()
#   ec2.instance.wait_until_running(myids)
   pprint.pprint(response)

def StopAllStoppedEC2Instances(myids):
   ec2 = boto3.resource('ec2')
   response = ec2.instances.filter(InstanceIds=myids).stop()
   pprint.pprint(response)

def GetNetworkInterfaces(myids):
   client = boto3.client('ec2')
   response = client.describe_network_interfaces(
      Filters=[
         {
            'Name': 'attachment.instance-id',
            'Values': myids,
         },
      ],
      DryRun=False
   )
   statuscode = response['ResponseMetadata']['HTTPStatusCode']
   if statuscode == 200:
      elements = response['NetworkInterfaces']
#      pprint.pprint(elements)
      for element in elements:
         if 'Attachment' in element:
            print(
               "Instance ID:", element['Attachment']['InstanceId'],
               "\tAvailability Zone:", element['AvailabilityZone'],
               "\n\tPrivate DNS Name:", element['PrivateDnsName'],
               "\n\tIP Address:", element['PrivateIpAddress']
            )
         else:
            print("\tNo 'Attachment' section available.")
         if 'Association' in element:
            print(
               "\tPublic DNS Name:", element['Association']['PublicDnsName'],
               "\n\tIP Address:", element['Association']['PublicIp']
            )
         else:
            print("\tNo 'Assocation' section available.")
         print()
   else:
      pprint.pprint(response['ResponseMetadata'])

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
   myids = GetAllStoppedEC2Instances()
   if len(myids) > 0:
      GetNetworkInterfaces(myids)
   myids = GetAllRunningEC2Instances()
   if len(myids) > 0:
      GetNetworkInterfaces(myids)
