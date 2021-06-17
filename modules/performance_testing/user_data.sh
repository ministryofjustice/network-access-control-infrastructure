#!/bin/bash
set -e 

sudo apt update && sudo apt install -y nettle-dev openssl libssl-dev gcc libc-dev awscli make

cd /home/ubuntu

mkdir -p /etc/raddb/certs
mkdir -p ./test

chmod 777 /etc/raddb/certs
chmod 777 ./test

aws s3 sync s3://moj-auth-poc-config-bucket/certs/ /etc/raddb/certs
aws s3 cp s3://moj-auth-poc-config-bucket/radsecproxy.conf ./
aws s3 sync s3://moj-auth-poc-config-bucket/test ./test
aws s3 cp s3://moj-auth-poc-config-bucket/tmp.sh ./

chmod +x ./test/*
mv ./radsecproxy.conf /etc

sudo mkdir -p /var/run/radsecproxy
sudo mkdir -p /var/log/radsecproxy

curl -sLo radsecproxy-1.9.0.tar.gz  \
         https://github.com/radsecproxy/radsecproxy/releases/download/1.9.0/radsecproxy-1.9.0.tar.gz && \
     curl  -sLo radsecproxy-1.9.0.tar.gz.asc \
         https://github.com/radsecproxy/radsecproxy/releases/download/1.9.0/radsecproxy-1.9.0.tar.gz.asc && \
     curl -sS https://radsecproxy.github.io/fabian.mauchle.asc | gpg --import - && \
     gpg --verify radsecproxy-1.9.0.tar.gz.asc \
                  radsecproxy-1.9.0.tar.gz && \
     rm  radsecproxy-1.9.0.tar.gz.asc && \
     tar xvf radsecproxy-1.9.0.tar.gz && \
     rm radsecproxy-1.9.0.tar.gz &&\
     cd radsecproxy-1.9.0 && \
     ./configure --prefix=/ --disable-dependency-tracking && \
     make && \
     make check && \
     make install && \
     touch /var/log/radsecproxy/radsecproxy.log 

 sudo touch /var/run/radsecproxy/radsecproxy.pid && /sbin/radsecproxy -i "/var/run/radsecproxy/radsecproxy.pid"

sudo apt-get install -y make pkg-config libnl-3-dev build-essential libdbus-glib-1-dev libgirepository1.0-dev openssl libssl-dev libnl-genl-3-dev

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

    cd /home/ubuntu/test

echo "hi"
#    while true; do
#      ./test_eap_tls.sh > /dev/null 
#      ./test_eap_tls.sh > /dev/null 
#      ./test_eap_tls.sh > /dev/null 
#      ./test_eap_tls.sh > /dev/null 
#      ./test_eap_tls.sh > /dev/null 
#    done &