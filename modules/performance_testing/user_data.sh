#!/bin/bash
set -e

sudo apt update && sudo apt install -y nettle-dev openssl libssl-dev gcc libc-dev awscli make pkg-config libnl-3-dev build-essential libdbus-glib-1-dev libgirepository1.0-dev openssl libssl-dev libnl-genl-3-dev

cd /home/ubuntu

mkdir -p /etc/raddb/certs

chmod 777 /etc/raddb/certs

cd /tmp
rm wpa_supplicant-2.9 -fr

wget http://w1.fi/releases/wpa_supplicant-2.9.tar.gz
tar xzvf wpa_supplicant-2.9.tar.gz

cd wpa_supplicant-2.9/wpa_supplicant

cp defconfig .config
sed -i "s/#CONFIG_EAPOL_TEST=y/CONFIG_EAPOL_TEST=y/g" .config
cat .config | grep TEST
make eapol_test
sudo cp eapol_test /usr/local/bin

cd /home/ubuntu

aws s3 sync s3://${s3_bucket_name}/certs/ /etc/raddb/certs
aws s3 cp s3://${s3_bucket_name}/perf_test.sh ./
aws s3 cp s3://${s3_bucket_name}/test.conf ./

chmod 777 ./perf_test.sh
