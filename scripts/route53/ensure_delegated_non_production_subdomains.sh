#!/bin/bash

set -e

assume_deploy_role() {
  TEMP_ROLE=`aws sts assume-role --role-arn $ROLE_ARN --role-session-name ci-nac-deploy-$CODEBUILD_BUILD_NUMBER`
  export AWS_ACCESS_KEY_ID=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
}

ensure_subdomain_ns_records() {
  echo $1 > upsert.json
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://upsert.json
}

main() {
  assume_deploy_role
  ensure_subdomain_ns_records $DEVELOPMENT_ROUTE53_NS_UPSERT
  ensure_subdomain_ns_records $PRE_PRODUCTION_ROUTE53_NS_UPSERT
}

if [ "$ENV" == "production" ]; then
  main
fi
