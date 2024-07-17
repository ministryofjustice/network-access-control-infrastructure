#!/bin/bash

echo "Script running is $(basename "$0")"
echo "Env is ${ENV}"

declare -A RESOURCES=(
)

declare -A RESOURCES_DEVELOPMENT=(
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
