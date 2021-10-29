#!/bin/bash

set -e

assume_role_target_aws_account() {
  TEMP_ROLE=`aws sts assume-role --role-arn $1 --role-session-name ci-build-$CODEBUILD_BUILD_NUMBER`
  export AWS_ACCESS_KEY_ID=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
}

ensure_subdomain_ns_records() {
  name_servers=$(aws route53 list-resource-record-sets --hosted-zone-id $1 |jq '.ResourceRecordSets[]' | jq 'select(.Type=="NS")') > ns.json
  name=$(jq -r '.Name' ns.json)
  jq ".Name = \"${name}\"" record_set_template.json
  jq ".Changes[0].ResourceRecordSet = ${name_servers}" record_set_template.json > upsert.json

  cat upsert.json

  #aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch file://upsert.json
}

main() {
  assume_role_target_aws_account $DEVELOPMENT_ASSUME_ROLE
  ensure_subdomain_ns_records $DEVELOPMENT_HOSTED_ZONE_ID

  assume_role_target_aws_account $PRE_PRODUCTION_ASSUME_ROLE
  ensure_subdomain_ns_records PRE_PRODUCTION_HOSTED_ZONE_ID
}

if [ "$ENV" == "production" ]; then
  main
fi

