#!/usr/bin/env bash

## This script will generate .env file for use with the Makefile
## or to export the TF_VARS into the environment

set -x

export ENV="${1:-development}"

printf "\n\nEnvironment is %s\n\n" "${ENV}"

case "${ENV}" in
    development)
        echo "development -- Continuing..."
        ;;
    pre-production)
        echo "pre-production -- Continuing..."
        ;;
    production)
        echo "production shouldn't be running this locally. Exiting..."
        exit 1
        ;;
    *)
        echo "Invalid input."
        ;;
esac

echo "Press 'y' to continue or 'n' to exit."

# Wait for the user to press a key
read -s -n 1 key

# Check which key was pressed
case $key in
    y|Y)
        echo "You pressed 'y'. Continuing..."
        ;;
    n|N)
        echo "You pressed 'n'. Exiting..."
        exit 1
        ;;
    *)
        echo "Invalid input. Please press 'y' or 'n'."
        ;;
esac



export PARAM=$(aws ssm get-parameters --region eu-west-2 --with-decryption --names \
    "/codebuild/pttp-ci-infrastructure-core-pipeline/$ENV/assume_role" \
    "/moj-network-access-control/$ENV/azure_federation_metadata_url" \
    "/moj-network-access-control/$ENV/hosted_zone_domain" \
    "/moj-network-access-control/$ENV/hosted_zone_id" \
    "/moj-network-access-control/$ENV/admin_db_username" \
    "/moj-network-access-control/$ENV/admin_db_password" \
    "/moj-network-access-control/$ENV/admin_sentry_dsn" \
    "/moj-network-access-control/$ENV/transit_gateway_id" \
    "/moj-network-access-control/$ENV/transit_gateway_route_table_id" \
    "/moj-network-access-control/$ENV/mojo_dns_ip_1" \
    --query Parameters)

export PARAM2=$(aws ssm get-parameters --region eu-west-2 --with-decryption --names \
    "/moj-network-access-control/$ENV/mojo_dns_ip_2" \
    "/moj-network-access-control/$ENV/ocsp/endpoint_ip" \
    "/moj-network-access-control/$ENV/ocsp/endpoint_port" \
    "/moj-network-access-control/$ENV/ocsp/atos/domain" \
    "/moj-network-access-control/$ENV/ocsp/atos/cidr_range_1" \
    "/moj-network-access-control/$ENV/ocsp/atos/cidr_range_2" \
    "/moj-network-access-control/$ENV/enable_ocsp" \
    "/moj-network-access-control/$ENV/ocsp_override_cert_url" \
    "/moj-network-access-control/$ENV/public_ip_pool_id" \
    "/moj-network-access-control/$ENV/eap_private_key_password" \
    --query Parameters)

export PARAM3=$(aws ssm get-parameters --region eu-west-2 --with-decryption --names \
    "/moj-network-access-control/$ENV/radsec_private_key_password" \
    "/moj-network-access-control/$ENV/debug/radius/enable_packet_capture" \
    "/moj-network-access-control/$ENV/debug/radius/packet_capture_duration_seconds" \
    "/moj-network-access-control/$ENV/cloudwatch_link" \
    "/moj-network-access-control/$ENV/grafana_dashboard_link" \
    "/moj-network-access-control/development/route53/ns_upsert" \
    "/moj-network-access-control/pre-production/route53/ns_upsert" \
    "/moj-network-access-control/$ENV/hosted_zone_id" \
    "/codebuild/pttp-ci-infrastructure-core-pipeline/$ENV/assume_role" \
    "/codebuild/staff_device_shared_services_account_id" \
    --query Parameters)


assume_role="$(echo $PARAM | jq '.[] | select(.Name | test("assume_role")) | .Value' --raw-output)"
azure_federation_metadata_url="$(echo $PARAM | jq '.[] | select(.Name | test("azure_federation_metadata_url")) | .Value' --raw-output)"
hosted_zone_domain="$(echo $PARAM | jq '.[] | select(.Name | test("hosted_zone_domain")) | .Value' --raw-output)"
hosted_zone_id="$(echo $PARAM | jq '.[] | select(.Name | test("hosted_zone_id")) | .Value' --raw-output)"
admin_db_username="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_username")) | .Value' --raw-output)"
admin_db_password="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_password")) | .Value' --raw-output)"
admin_sentry_dsn="$(echo $PARAM | jq '.[] | select(.Name | test("admin_sentry_dsn")) | .Value' --raw-output)"
transit_gateway_id="$(echo $PARAM | jq '.[] | select(.Name | test("transit_gateway_id")) | .Value' --raw-output)"
transit_gateway_route_table_id="$(echo $PARAM | jq '.[] | select(.Name | test("transit_gateway_route_table_id")) | .Value' --raw-output)"
mojo_dns_ip_1="$(echo $PARAM | jq '.[] | select(.Name | test("mojo_dns_ip_1")) | .Value' --raw-output)"

mojo_dns_ip_2="$(echo $PARAM2 | jq '.[] | select(.Name | test("mojo_dns_ip_2")) | .Value' --raw-output)"
ocsp_endpoint_ip="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp/endpoint_ip")) | .Value' --raw-output)"
ocsp_endpoint_port="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp/endpoint_port")) | .Value' --raw-output)"
ocsp_atos_domain="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp/atos/domain")) | .Value' --raw-output)"
ocsp_atos_cidr_range_1="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp/atos/cidr_range_1")) | .Value' --raw-output)"
ocsp_atos_cidr_range_2="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp/atos/cidr_range_2")) | .Value' --raw-output)"
enable_ocsp="$(echo $PARAM2 | jq '.[] | select(.Name | test("enable_ocsp")) | .Value' --raw-output)"
ocsp_override_cert_url="$(echo $PARAM2 | jq '.[] | select(.Name | test("ocsp_override_cert_url")) | .Value' --raw-output)"
byoip_pool_id="$(echo $PARAM2 | jq '.[] | select(.Name | test("public_ip_pool_id")) | .Value' --raw-output)"
eap_private_key_password="$(echo $PARAM2 | jq '.[] | select(.Name | test("eap_private_key_password")) | .Value' --raw-output)"

radsec_private_key_password="$(echo $PARAM3 | jq '.[] | select(.Name | test("radsec_private_key_password")) | .Value' --raw-output)"
radius_enable_packet_capture="$(echo $PARAM3 | jq '.[] | select(.Name | test("debug/radius/enable_packet_capture")) | .Value' --raw-output)"
packet_capture_duration_seconds="$(echo $PARAM3 | jq '.[] | select(.Name | test("debug/radius/packet_capture_duration_seconds")) | .Value' --raw-output)"
cloudwatch_link="$(echo $PARAM3 | jq '.[] | select(.Name | test("cloudwatch_link")) | .Value' --raw-output)"
grafana_dashboard_link="$(echo $PARAM3 | jq '.[] | select(.Name | test("grafana_dashboard_link")) | .Value' --raw-output)"
DEVELOPMENT_ROUTE53_NS_UPSERT="$(echo $PARAM3 | jq '.[] | select(.Name | test("development/route53/ns_upsert")) | .Value' --raw-output)"
PRE_PRODUCTION_ROUTE53_NS_UPSERT="$(echo $PARAM3 | jq '.[] | select(.Name | test("pre-production/route53/ns_upsert")) | .Value' --raw-output)"
HOSTED_ZONE_ID="$(echo $PARAM3 | jq '.[] | select(.Name | test("hosted_zone_id")) | .Value' --raw-output)"
ROLE_ARN="$(echo $PARAM3 | jq '.[] | select(.Name | test("assume_role")) | .Value' --raw-output)"
shared_services_account_id="$(echo $PARAM3 | jq '.[] | select(.Name | test("staff_device_shared_services_account_id")) | .Value' --raw-output)"


cat << EOF > ./.env
# env file
# regenerate by running "./scripts/generate-env-file.sh"
# defaults to "development"
# To test against another environment
# regenerate by running "./scripts/generate-env-file.sh [pre-production | production]"
# Also run "make clean"
# then run "make init"


export AWS_PROFILE=mojo-shared-services-cli
export AWS_VAULT_PROFILE=mojo-shared-services-cli

### ${ENV} ###
export ENV="${ENV}"

export TF_VAR_assume_role="${assume_role}"
export TF_VAR_azure_federation_metadata_url="${azure_federation_metadata_url}"


export TF_VAR_hosted_zone_domain="${hosted_zone_domain}"
export TF_VAR_hosted_zone_id="${hosted_zone_id}"
export TF_VAR_admin_db_username="${admin_db_username}"
export TF_VAR_admin_db_password="${admin_db_password}"
export TF_VAR_admin_sentry_dsn="${admin_sentry_dsn}"
export TF_VAR_transit_gateway_id="${transit_gateway_id}"
export TF_VAR_transit_gateway_route_table_id="${transit_gateway_route_table_id}"
export TF_VAR_mojo_dns_ip_1="${mojo_dns_ip_1}"
export TF_VAR_mojo_dns_ip_2="${mojo_dns_ip_2}"
export TF_VAR_ocsp_endpoint_ip="${ocsp_endpoint_ip}"
export TF_VAR_ocsp_endpoint_port="${ocsp_endpoint_port}"
export TF_VAR_ocsp_atos_domain="${ocsp_atos_domain}"
export TF_VAR_ocsp_atos_cidr_range_1="${ocsp_atos_cidr_range_1}"
export TF_VAR_ocsp_atos_cidr_range_2="${ocsp_atos_cidr_range_2}"
export TF_VAR_enable_ocsp="${enable_ocsp}"
export TF_VAR_ocsp_override_cert_url="${ocsp_override_cert_url}"
export TF_VAR_byoip_pool_id="${byoip_pool_id}"
export TF_VAR_eap_private_key_password="${eap_private_key_password}"
export TF_VAR_radsec_private_key_password="${radsec_private_key_password}"
export TF_VAR_radius_enable_packet_capture="${radius_enable_packet_capture}"
export TF_VAR_packet_capture_duration_seconds="${packet_capture_duration_seconds}"
export TF_VAR_cloudwatch_link="${cloudwatch_link}"
export TF_VAR_grafana_dashboard_link="${grafana_dashboard_link}"
export DEVELOPMENT_ROUTE53_NS_UPSERT="${DEVELOPMENT_ROUTE53_NS_UPSERT}"
export PRE_PRODUCTION_ROUTE53_NS_UPSERT="${PRE_PRODUCTION_ROUTE53_NS_UPSERT}"
export HOSTED_ZONE_ID="${HOSTED_ZONE_ID}"
export ROLE_ARN="${ROLE_ARN}"
export TF_VAR_shared_services_account_id="${shared_services_account_id}"

EOF
chmod u+x ./.env

rm -rf .terraform/ terraform.tfstate*

printf "\n\n run \"make init\"\n\n"
