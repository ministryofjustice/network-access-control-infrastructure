#!/usr/bin/env bash

set -e

# Check if the environment is "production"
if [[ $ENV != "production" ]]; then
  echo "Script is intended for production environment only. Exiting."
  exit 0
fi

# Filter for log groups containing "aws/rds/instance/" in the name
log_group_names=$(aws logs describe-log-groups | jq -r '.logGroups | .[] | select(.logGroupName | contains("aws/rds/instance/")) | .logGroupName')

retention_period=90

for log_group_name in $log_group_names
do
  echo "setting log retention policy for $log_group_name to $retention_period"
  aws logs put-retention-policy --log-group-name $log_group_name --retention-in-days $retention_period
done
