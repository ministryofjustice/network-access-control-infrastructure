#!/usr/bin/env bash

export PARAM=$(aws ssm get-parameters --region eu-west-2 --with-decryption --names \
    "/moj-network-access-control/$ENV/admin_db_username" \
    "/moj-network-access-control/$ENV/admin_db_password" \
    --query Parameters)

echo $ENV
echo $PARAM

declare -A params

params["admin_db_password"]="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_password")) | .Value' --raw-output)"
params["admin_db_username"]="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_username")) | .Value' --raw-output)"


for key in "${!params[@]}"
do
  echo "${key}=${params[${key}]}"
done
