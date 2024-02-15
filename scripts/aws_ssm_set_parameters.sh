#!/usr/bin/env bash

ENV="${1:-development}"
ENABLE_RDS_SERVERS_BASTION="${2:-false}"
ENABLE_RDS_ADMIN_BASTION="${3:-false}"

echo $ENV

#aws ssm put-parameter \
#    --name "/moj-network-access-control/$ENV/enable_rds_servers_bastion" \
#    --type "String" \
#    --value "$ENABLE_RDS_SERVERS_BASTION" \
#    --overwrite
#
#aws ssm put-parameter \
#    --name "/moj-network-access-control/$ENV/enable_rds_admin_bastion" \
#    --type "String" \
#    --value "$ENABLE_RDS_ADMIN_BASTION" \
#    --overwrite


export PARAM=$(aws ssm get-parameters --region eu-west-2 --with-decryption --names \
    "/moj-network-access-control/$ENV/enable_rds_admin_bastion" \
    "/moj-network-access-control/$ENV/enable_rds_servers_bastion" \
    --query Parameters)

echo $ENV
echo $PARAM

declare -A params

params["enable_rds_servers_bastion"]="$(echo $PARAM | jq '.[] | select(.Name | test("enable_rds_servers_bastion")) | .Value' --raw-output)"
params["enable_rds_admin_bastion"]="$(echo $PARAM | jq '.[] | select(.Name | test("enable_rds_admin_bastion")) | .Value' --raw-output)"

for key in "${!params[@]}"
do
  echo "${key}=${params[${key}]}"
done
