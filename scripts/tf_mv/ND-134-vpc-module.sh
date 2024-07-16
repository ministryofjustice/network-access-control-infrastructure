#!/bin/bash

echo "Script running is $(basename "$0")"
echo "Env is ${ENV}"

declare -A RESOURCES=()

declare -A RESOURCES_DEVELOPMENT=(
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.rds[0]"]='module.radius_vpc.aws_vpc_endpoint.rds'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.s3[0]"]='module.radius_vpc.aws_vpc_endpoint.s3'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.logs[0]"]='module.radius_vpc.aws_vpc_endpoint.logs'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.monitoring[0]"]='module.radius_vpc.aws_vpc_endpoint.monitoring'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_dkr[0]"]='module.radius_vpc.aws_vpc_endpoint.ecr_dkr'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_api[0]"]='module.radius_vpc.aws_vpc_endpoint.ecr_api'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.public_s3[0]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.public_s3'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[0]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-0f4597542e6aa0556"]'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[1]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-031a61b9efe154408"]'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-0b23013f2990bd5f5"]'
)

declare -A RESOURCES_PRE_PRODUCTION=(
)

declare -A RESOURCES_PRODUCTION=(
)

printf "\n\nEnvironment is %s\n\n" "${ENV}"

case "${ENV}" in
    development)
        echo "development -- Continuing..."
        for k in "${!RESOURCES_DEVELOPMENT[@]}"; do RESOURCES[$k]=${RESOURCES_DEVELOPMENT[$k]}; done
        ;;
    pre-production)
        echo "pre-production -- Continuing..."
        for k in "${!RESOURCES_PRE_PRODUCTION[@]}"; do RESOURCES[$k]=${RESOURCES_PRE_PRODUCTION[$k]}; done
        ;;
    production)
        echo "production -- Continuing..."
        for k in "${!RESOURCES_PRODUCTION[@]}"; do RESOURCES[$k]=${RESOURCES_PRODUCTION[$k]}; done
        ;;
    *)
        echo "Using default resources array."
        ;;
esac

APPLY="${1:-false}"


for OLD in "${!RESOURCES[@]}"; do
    NEW="${RESOURCES[$OLD]}"
    echo "Starting Moving:"
    echo "${OLD} ${NEW}"
    echo

    if [[ "${APPLY}" == "true" ]]; then
      echo "Applying state move"
      terraform state mv "${OLD}" "${NEW}"
    else
      echo "Dry Run"
      terraform state mv --dry-run "${OLD}" "${NEW}"
    fi
done

echo "Complete"
