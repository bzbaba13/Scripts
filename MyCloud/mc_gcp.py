# This is the GCP portion of the MyCloud application.
# Python 3.6+, GCloud SDK, and  google-api-python-client
# are required for execution.

import googleapiclient
import json, pprint


compute = googleapiclient.discovery.build('compute', 'v1')

def list_instances(compute, project, zone):
    result = compute.instances().list(project=project, zone=zone).execute()
    return result['items'] if 'items' in result else None
