#!/usr/bin/env bash

 while true
 do
	array[0]="ENTER IP 1"
	array[1]="ENTER IP 2"
	array[2]="ENTER IP 3"
	size=${#array[@]}
	index=$(($RANDOM % $size))

 	eapol_test -r0 -t3 -c test.conf -a"${array[$index]}" -s "PERFTEST" > /dev/null
	sleep 0.5
 done




