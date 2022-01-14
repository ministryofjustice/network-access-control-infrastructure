#!/bin/bash

set -euo pipefail

if [[ "${PLAN}" == "true" ]]; then
  terraform plan
else
  terraform apply --auto-approve -no-color
fi
