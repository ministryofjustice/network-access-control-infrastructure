#!/usr/bin/env bash

## This script will generate .env file for use with the Makefile

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



cat << EOF > ./.env
# env file
# regenerate by running "./scripts/generate-env-file.sh"
# defaults to "development"
# To test against another environment
# regenerate by running "./scripts/generate-env-file.sh [pre-production | production]"
# Also run "make clean"
# then run "make init"


AWS_PROFILE=mojo-shared-services-cli
AWS_VAULT_PROFILE=mojo-shared-services-cli

### ${ENV} ###
ENV=${ENV}

EOF

chmod u+x ./.env

rm -rf .terraform/ terraform.tfstate*

printf "\n\n run \"make init\"\n\n"
