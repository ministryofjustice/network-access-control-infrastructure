#!/bin/bash

set -e

ensure_subdomain_ns_records() {
  echo $1 > upsert.json
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://upsert.json
}

main() {
  ensure_subdomain_ns_records $DEVELOPMENT_ROUTE53_NS_UPSERT
  ensure_subdomain_ns_records $PRE_PRODUCTION_ROUTE53_NS_UPSERT
}

if [ "$ENV" == "production" ]; then
  main
fi
