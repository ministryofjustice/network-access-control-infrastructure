#!/bin/bash

set -ex

eapol_test -r0 -t3 -c eapol_test_mab.conf -a 18.135.199.166 -s testing
