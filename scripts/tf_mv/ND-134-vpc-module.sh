#!/bin/bash

echo "Script running is $(basename "$0")"
echo

declare -A RESOURCES=(
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.rds[0]"]='module.radius_vpc.aws_vpc_endpoint.rds'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.s3[0]"]='module.radius_vpc.aws_vpc_endpoint.s3'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.logs[0]"]='module.radius_vpc.aws_vpc_endpoint.logs'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.monitoring[0]"]='module.radius_vpc.aws_vpc_endpoint.monitoring'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_dkr[0"]='module.radius_vpc.aws_vpc_endpoint.ecr_dkr'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_api[0]"]='module.radius_vpc.aws_vpc_endpoint.ecr_api'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.public_s3[0]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.public_s3'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[0]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-0f4597542e6aa0556"]'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[1]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-031a61b9efe154408"]'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-0b23013f2990bd5f5"]'
)

for OLD in "${!RESOURCES[@]}"; do
    NEW="${RESOURCES[$OLD]}"
    echo "Starting Moving:"
    echo "${OLD} ${NEW}"
    echo
    terraform state mv --dry-run "${OLD}" "${NEW}"
done

echo "Complete"
