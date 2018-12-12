#!/usr/bin/env python3

import boto3, pprint


def main():
   client = boto3.client('ec2')
   response = client.describe_instance_status(
      IncludeAllInstances=True
   )
   pprint.pprint (response['InstanceStatuses'])
   print ()
   pprint.pprint (response['ResponseMetadata'])


if __name__ == "__main__":
   main()
