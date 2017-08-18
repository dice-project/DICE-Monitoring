import sys
import os

from cloudify_cli import utils

deployment_id = sys.argv[1]

management_ip = utils.get_management_server_ip()
client = utils.get_rest_client(management_ip)

dep = client.deployments.get(deployment_id, _include=['outputs'])
response = client.deployments.outputs.get(deployment_id)
outputs = response.outputs

print("""
	export DMON_ADDRESS={0}
	export KIBANA_URL={1}
""".format(outputs["dmon_address"], outputs["kibana_url"]))

