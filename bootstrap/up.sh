#!/bin/bash

set -e

NAME=$0

function usage ()
{
  cat << EOF

USAGE:

  $NAME [DEPLOY_NAME]

EOF
}

function check_inputs ()
{
  [ -e "inputs.yaml" ] && return
  echo "Please create a valid inputs.yaml file."
  echo ""
  echo "E.g.:"
  echo "cp $TOOLDIR/install/inputs-example.yaml $TOOLDIR/inputs.yaml"
  echo "${EDITOR-nano} $TOOLDIR/inputs.yaml"
  exit 2
}

function main ()
{
  local name="blueprint.yaml"
  local inputs="inputs.yaml"
  # :- is not optional here, because function parameters are tricky
  local deploy_name=${1:-dmon}


  # Deploy
  local blueprint="$name"
  echo "Publishing blueprint"
  cfy blueprints upload -b $deploy_name -p $blueprint
  echo "Creating deploy"
  cfy deployments create -d $deploy_name -b $deploy_name -i $inputs
  echo "Starting execution"
  cfy executions start -d $deploy_name -w install -l
  echo "Outputs:"
  cfy deployments outputs -d $deploy_name
}

main $1
