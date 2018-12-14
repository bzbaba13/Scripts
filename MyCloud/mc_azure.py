#!/usr/bin/env python3

import pprint
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.managementgroups import operations
from azure.common.client_factory import get_client_from_cli_profile


def GetCompute():
   client = get_client_from_cli_profile(ComputeManagementClient)

   pprint.pprint(client)

def GetResourceGroup():
   resource_group = 

# for testing purposes
if __name__ == "__main__":
   GetResourceGroup()
