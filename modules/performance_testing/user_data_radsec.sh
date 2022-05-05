#!/bin/bash
set -e

sudo apt update

disable_logging() {
  systemctl disable systemd-journald.service
}

fetch_certs() {
  mkdir -p /etc/raddb/certs
  chmod 777 /etc/raddb/certs
  aws s3 sync s3://${s3_bucket_name}/certs/ /etc/raddb/certs
  aws s3 cp s3://${s3_bucket_name}/perf_test.sh ./
  aws s3 cp s3://${s3_bucket_name}/test.conf ./
  chmod 777 ./perf_test.sh
  cd /etc/raddb/certs/ && c_rehash .
}

main() {
  disable_logging
  # fetch_certs
}

main
