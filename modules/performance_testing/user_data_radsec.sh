#!/bin/bash
set -e


install_packages() {
apt update
apt upgrade -y
apt-get remove docker docker-engine docker.io containerd runc
apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update

  apt-get install docker-ce docker-ce-cli containerd.io
  apt install -y docker-compose
}

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
  install_packages
  disable_logging
  # fetch_certs
}

main
