#!/usr/bin/env bash

set -e

assume_deploy_role() {
  TEMP_ROLE=`aws sts assume-role --role-arn $ROLE_ARN --role-session-name ci-nac-deploy-$CODEBUILD_BUILD_NUMBER`
  export AWS_ACCESS_KEY_ID=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
}

update_log_retention(){

# Filter for log groups containing "aws/rds/instance/" in the name
log_group_names=$(aws logs describe-log-groups | jq -r '.logGroups | .[] | select(.logGroupName | contains("aws/rds/instance/")) | .logGroupName')

retention_period=90

for log_group_name in $log_group_names
do
  echo "setting log retention policy for $log_group_name to $retention_period"
  aws logs put-retention-policy --log-group-name $log_group_name --retention-in-days $retention_period
done
}

main() {
  assume_deploy_role
  update_log_retention

}
if [ "$ENV" == "production" ]; then # Check if the environment is "production"
  main
fi
