#!/bin/bash

set -e

echo "starting test"
while true; do
    ./test_eap_tls.sh |tail -n 1 >> results 
    date +%s >> results
    sleep 0.5 
done &