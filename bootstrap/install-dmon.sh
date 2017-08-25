#!/bin/bash

declare -r -A env_vars=(
  [UBUNTU_USERNAME]="Linux username for the Ubuntu"
  [LARGE_INSTANCE_ID]="Instance type ID for a large server"
  [UBUNTU_IMAGE_UUID]="Image UUID of the Ubuntu 14.04 OS image"
  [FCO_LARGE_DISK_UUID]="FCO UUID of the product offer for disk of large size"
  [DEPLOYMENT_PLATFORM]="Target platform for deployment(s)"
  [DMON_CLUSTER_NAME]="The name of the DMon cluster"
  [DDS_DNS_SERVER]="The address of the DNS server (usually DICE Deployment Service's internal IP)"
  [LSF_OPENSSL_CONF]="Configuration for Logstash Forwarder's certificate"
)

set -e

NAME=$0
TOOLDIR="$(dirname $0)"
DEPLOYMENT_ID=${1:-dmon}

function usage ()
{
  cat <<EOF

USAGE:

  $NAME [DEPLOY_NAME]

  Prepares the inputs for deployment of the DICE Monitoring Service,
  runs the deployment, and sets up the runtime inputs at the new DICE Deployment
  Service instance.

  DEPLOY_NAME - optional deployment name (default: dmon)

EOF
}

function check_inputs ()
{
  if [ "$1" == "-h" ] || [ "$1" == "--help" ]
  then
    usage
    exit 0
  fi
}

function validate_env()
{
  local success=true

  for v in "${!env_vars[@]}"
  do
    if [[ -z "${!v}" ]]
    then
      echo "Missing variable $v: ${env_vars[$v]}."
      success=false
    fi
  done

  if [ "$success" == "false" ]
  then
    echo
    echo "Have you forgotten to source config.inc.sh and dds-config.inc.sh?"
  fi

  $success
}

validate_env

echo "Creating deployment inputs for DICE Monitoring Service"
cat <<EOF > inputs.yaml
cluster_name: "$DMON_CLUSTER_NAME"
lsf_cert: {}
lsf_key: {}
openssl_conf: |
  $LSF_OPENSSL_CONF

platform: $DEPLOYMENT_PLATFORM
large_disk_type: $FCO_LARGE_DISK_UUID
large_instance_type: $LARGE_INSTANCE_ID
ubuntu_image_id: $UBUNTU_IMAGE_UUID
ubuntu_agent_user: $UBUNTU_USERNAME

centos_image_id: dummy
dns_server: dummy
medium_disk_type: dummy
medium_instance_type: dummy
small_disk_type: dummy
small_instance_type: dummy
EOF

echo "Running installation"
./up.sh $DEPLOYMENT_ID

echo "Obtaining outputs"
OUTPUTS_TO_EVAL=$(python "$TOOLDIR/outputs-to-env.py" $DEPLOYMENT_ID)

if [ "$?" != "0" ]
then
  echo ""
  echo "ERROR obtaining the outputs. Aborting."
  echo ""

  exit $?
fi

# Here we obtain DMON_ADDRESS and KIBANA_URL
eval $OUTPUTS_TO_EVAL

echo "Creating DICE Deployment Service's runtime inputs - the DMon values"
cat <<EOF > dmon_inputs.json
[
  {
    "key": "dmon_address",
    "value": "$DMON_ADDRESS:5001",
    "description": "Place dmon address here (eg. 10.50.51.4:5001). This input is required if one wishes to use monitoring components."
  },
  {
    "key": "logstash_graphite_address",
    "value": "$DMON_ADDRESS:5002",
    "description": "Place logstash graphite address here (eg. 10.50.51.4:5002). This input is required if one wishes to use monitoring components that utilize graphite logstash input."
  },
  {
    "key": "logstash_lumberjack_address",
    "value": "$DMON_ADDRESS:5000",
    "description": "Place logstash lumberjack address here (eg. 10.50.51.4:5000). This input is required if one wishes to use monitoring components that utilize lumberjack logstash input."
  },
  {
    "key": "logstash_udp_address",
    "value": "$DMON_ADDRESS:25826",
    "description": "Place logstash udp address here (eg. 10.50.51.4:25826). This input is required if one wishes to use monitoring components that utilize udp logstash input."
  },
  {
    "key": "logstash_lumberjack_crt",
    "value": "",
    "description": "Content of certificate that is offered by logstash lumberjack address."
  }
]
EOF


cat <<EOF

-----------------------------------------------------------------------------
SUMMARY:
  Kibana URL: $KIBANA_URL
  Private DMon address: $DMON_ADDRESS
-----------------------------------------------------------------------------
EOF