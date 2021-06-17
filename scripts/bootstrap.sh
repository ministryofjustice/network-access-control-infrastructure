#!/bin/bash

set -e

install_dependencies() {
  sudo apt-get update && sudo apt-get install -y make pkg-config libnl-3-dev build-essential libdbus-glib-1-dev libgirepository1.0-dev openssl libssl-dev libnl-genl-3-dev

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
}

run_test() {
  eapol_test
}


main() {
#install_dependencies
run_test
}