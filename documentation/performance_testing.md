# Network Access Control Performance Testing

- [Deploying the infrastructure](#deploying-the-infrastructure)
- [Performance test configuration](#performance-test-configuration)
  - [Generating and signing the performance test certificates](#generating-and-signing-the-performance-test-certificates)
  - [Authorise test clients](#authorise-test-clients)
- [Running the performance tests](#running-the-performance-tests)

## Deploying the infrastructure
The infrastructure for performance testing is deployed using Terraform. These resources currently consist of ten client EC2 instances and an s3 bucket for configuration. They are defined in the [performance testing](https://github.com/ministryofjustice/network-access-control-infrastructure/tree/main/modules/performance_testing) module and deployed only in the development environment.

## Performance test configuration
### Generating and signing the performance test certificates
1. There is a `generate-certs` script in the [integration tests repository](https://github.com/ministryofjustice/network-access-control-integration-tests/blob/main/Makefile#L33)

2. From the generated `./test/certs` folder, run the command to destroy the certificates. These are not signed with the correct `private_key_password` that is used in the development environment
```bash
make destroycerts
```

3. Edit the `ca.cnf`, `clients.cnf` and `server.cnf` file to use the `private_key_password` from the parameter store, to get the password run:
```bash
aws-vault exec moj-nac-shared-services -- aws ssm get-parameter --name "/moj-network-access-control/development/eap_private_key_password" --with-decryption --query "Parameter.Value"
```

```bash
# ca.cnf, clients.cnf or server.cnf
...
input_password		= <private_key_password>
output_password		= <private_key_password>
...
```

4. Regenerate the certificates with the updated `private_key_password`
```bash
make
```

5. Copy the generated certificates to the performance test config bucket
```bash
aws-vault exec moj-nac-development -- aws s3 cp ./client.pem s3://$perf_config_bucket/certs/

aws-vault exec moj-nac-development -- aws s3 cp ./ca.pem s3://$perf_config_bucket/certs/
```

6. Create a `test.conf` file and a `perf_test.sh` script
```bash
# test.conf
network={
    ssid="DoesNotMatterForThisTest"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="user@example.org"
    ca_cert="/etc/raddb/certs/ca.pem"
    client_cert="/etc/raddb/certs/client.pem"
    private_key="/etc/raddb/certs/client.pem"
    private_key_passwd="<private_key_password>"
    eapol_flags=3
}
```

```bash
# perf_test.sh

#!/usr/bin/env bash\n
while true
 do
	array[0]="18.x.x.x"
	array[1]="19.x.x.x"
	array[2]="20.x.x.x"
	size=${#array[@]}
	index=$(($RANDOM % $size))

 	eapol_test -r0 -t3 -c test.conf -a"${array[$index]}" -s "PERFTEST" > /dev/null
	sleep 0.5
 done
```
to grab the IP addresses of the load balancer, run
```bash
aws-vault exec moj-nac-development -- aws elbv2 describe-load-balancers --names nac-radius-lb-development --query "LoadBalancers[].AvailabilityZones[].LoadBalancerAddresses[].IpAddress"
```
upload the created files into the perf config bucket

```bash
aws-vault exec moj-nac-development -- aws s3 cp ./test.conf s3://$perf_config_bucket/
aws-vault exec moj-nac-development -- aws s3 cp ./perf_test.conf s3://$perf_config_bucket/
```

7. Decrypt the `server.key` file
```bash
openssl rsa -in server.key -out server.key -passin pass:"<private_key_password>"
```

8. Copy the decrypted key into the `server.pem` file and remove the generated metadata, so that it only has the server certificate and the decrypted key. The `server.pem` should look similar to this:
```pem
-----BEGIN CERTIFICATE-----
...Server certificate...
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
...Decrypted key...
-----END RSA PRIVATE KEY-----
```

9. Copy the server certificate and CA into the certificates bucket
```bash
aws-vault exec moj-nac-development -- aws s3 cp ./server.pem s3://$nac_certificate_bucket/
aws-vault exec moj-nac-development -- aws s3 cp ./ca.pem s3://$nac_certificate_bucket/
```

## Running the performance tests
The test script executes automatically when the EC2 instances are booted. For further details, see the [User Data script.](/modules/performance_testing/user_data.sh) It is a prerequisite to populate the performance test config bucket before deploying the performance test instances.

### Authorise test clients
The following make command updates the list of authorised clients with the IP addresses of the EC2 instance, run from the root folder using:
```bash
make authorise-performance-test-clients
```
