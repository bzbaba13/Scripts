# This is the AWS portion of the MyCloud application.
# Python 3.6+, AWS CLI, and boto3 are required for execution.

import boto3
import pprint, json

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
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['stopped', 'stopping']}]
   )
   return(instances)

def GetAllRunningEC2Instances():
   ec2 = boto3.resource('ec2')
   instances = ec2.instances.filter(
      Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
   )
   return(instances)

def PrintAllEC2Instances(instances,mystate):
   IdList = []
   for inst in instances:
      IdList.append(inst.instance_id)
      print("ID:", inst.instance_id, 
            "\tType:", inst.instance_type, 
            "\tState:", inst.state)
      print("    Tags:", inst.tags)
      print("\tPrivate DNS name:", inst.private_dns_name)
      print("\t      IP address:", inst.private_ip_address)
      if len(inst.public_dns_name) > 0:
         print("\t Public DNS name:", inst.public_dns_name)
      else:
         print("\t Public DNS name: None")
      print("\t      IP address:", inst.public_ip_address)
      print()
   if len(IdList) == 0:
      print("\tNo instances with state of", mystate, "found.\n")
   else:
      print()

def StartAllStoppedEC2Instances(myids):
   ec2 = boto3.resource('ec2')
   response = ec2.instances.filter(InstanceIds=myids).start()
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
   print("Looking for all stopped/stopping instances...")
   PrintAllEC2Instances(GetAllStoppedEC2Instances(),'stopped/stopping')
   print("Looking for all running instances...")
   PrintAllEC2Instances(GetAllRunningEC2Instances(),'running')
