#!/usr/bin/env python3

"""Create and manage virtual machines.

This script expects that the following environment vars are set:

AZURE_TENANT_ID: your Azure Active Directory tenant id or domain
AZURE_CLIENT_ID: your Azure Active Directory Application Client ID
AZURE_CLIENT_SECRET: your Azure Active Directory Application Secret
AZURE_SUBSCRIPTION_ID: your Azure Subscription Id
"""
import os, pprint
from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.compute.models import DiskCreateOption
from azure.mgmt.managementgroups import operations
from azure.common.client_factory import get_client_from_cli_profile

from msrestazure.azure_exceptions import CloudError

from haikunator import Haikunator


haikunator = Haikunator()

# Azure Datacenter
LOCATION = 'westus'

def get_credentials():
   group_name = os.environ['AZURE_GROUP_NAME']
   subscription_id = os.environ['AZURE_SUBSCRIPTION_ID']
   credentials = ServicePrincipalCredentials(
      client_id = os.environ['AZURE_CLIENT_ID'],
      secret = os.environ['AZURE_CLIENT_SECRET'],
      tenant = os.environ['AZURE_TENANT_ID']
   )
   return credentials, group_name, subscription_id


credentials, group_name, subscription_id = get_credentials()
#resource_client = ResourceManagementClient(credentials, subscription_id)
compute_client = ComputeManagementClient(credentials, subscription_id)
#network_client = NetworkManagementClient(credentials, subscription_id)

#def StartVM():
#   print('\nStart VM')
#   async_vm_start = compute_client.virtual_machines.start(GROUP_NAME, VM_NAME)
#   async_vm_start.wait()
#
#def RestartVM():
#   print('\nRestart VM')
#   async_vm_restart = compute_client.virtual_machines.restart(GROUP_NAME, VM_NAME)
#   async_vm_restart.wait()
#
#def StopVM():
#   print('\nStop VM')
#   async_vm_stop = compute_client.virtual_machines.power_off(GROUP_NAME, VM_NAME)
#   async_vm_stop.wait()

def ListVMinSub():
   print('\nList VMs in subscription')
   for vm in compute_client.virtual_machines.list_all():
      print("\tVM: {}".format(vm.name))

def ListVMinRG():
   print('\nList VMs in resource group')
   for vm in compute_client.virtual_machines.list(group_name):
      print("\tVM: {}".format(vm.name))

#def DeleteVM():
#   print('\nDelete VM')
#   async_vm_delete = compute_client.virtual_machines.delete(GROUP_NAME, VM_NAME)
#   async_vm_delete.wait()


# for testing purposes
if __name__ == "__main__":
   ListVMinRG()
