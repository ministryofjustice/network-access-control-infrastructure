#!/bin/bash

echo "Script running is $(basename "$0")"
echo

declare -A RESOURCES=(
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[1]"]='module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2]'
    ["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-0c3448fdb5383e86e"]'
)

for OLD in "${!RESOURCES[@]}"; do
    NEW="${RESOURCES[$OLD]}"
    echo "Starting Moving:"
    echo "${OLD} ${NEW}"
    echo
    terraform state mv --dry-run "${OLD}" "${NEW}"
done

echo "Complete"
