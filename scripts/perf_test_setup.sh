env=development

aws s3 cp s3://mojo-$env-nac-config-bucket/clients.conf ./scripts/

# Get all the IPs from EC2
ip_addresses=$(aws ec2 describe-instances --filters "Name=tag:Name,Values='MoJ Authentication Performance-*'" --query "Reservations[].Instances[].PublicIpAddress")
trim_brackets=$(echo $ip_addresses | sed 's/^..\(.*\)..$/\1/')
IFS='", "' read -r -a ip_array <<< $trim_brackets

# For each IP append the clients conf file
for ip in "${ip_array[@]}"
do
  CLIENT=$(cat <<-END
  \n\nclient $ip/32 {\n
  \tipv4addr = $ip/32\n
  \tsecret = PERFTEST\n
  \tshortname = perf_test_site\n}
END
)
  echo $CLIENT >> ./scripts/clients.conf
done

# Upload the clients file to s3
aws s3 cp ./scripts/clients.conf s3://mojo-$env-nac-config-bucket/clients.conf

# Delete clients.conf
rm ./scripts/clients.conf

# Restart the ECS tasks
aws ecs update-service --force-new-deployment --service mojo-$env-nac-service --cluster mojo-$env-nac-cluster

# Upload the performance test script to perf config bucket
load_balancer_ip=$(aws elbv2 describe-load-balancers --names nac-radius-lb-development --query "LoadBalancers[].AvailabilityZones[].LoadBalancerAddresses[].IpAddress | [0]")

TEST_SCRIPT=$(cat <<-END
#!/usr/bin/env bash\n
\n
while true\n
do\n
  \teapol_test -r0 -t3 -c test.conf -a$load_balancer_ip -s "PERFTEST"\n
done\n
END
)

echo $TEST_SCRIPT > ./scripts/perf_test.sh

aws s3 cp ./scripts/perf_test.sh s3://mojo-$env-nac-perf-config-bucket/perf_test.sh

# Delete the test script
rm ./scripts/perf_test.sh
