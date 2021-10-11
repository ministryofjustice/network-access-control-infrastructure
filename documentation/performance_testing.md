# Network Access Control Performance Testing

- [Deploying the infrastructure](#peploying-the-infrastructure)
- [Performance test configuration](#performance-test-configuration)
  - [Generating and signing the performance test certificates](#generating-and-signing-the-performance-test-certificates)
- [Running the performance tests](#running-the-performance-tests)

## Deploying the infrastructure
The infrastructure for performance testing is deployed using Terraform. These resources currently consist of ten client EC2 instances and an s3 bucket for configuration. They are defined in [`modules/performance_testing`](./modules/performance_testing) module and deployed only in the development environment.

> The first deployment of EC2 instances will fail to configure the boxes! Prerequisite is to have the certificates and performance test script in the configuration bucket.

## Performance-test-configuration
### Generating and signing the performance test certificates
1. There is a `generate-certs` script in the [integration tests repository](https://github.com/ministryofjustice/network-access-control-integration-tests/blob/main/Makefile#L33)

2. From the generated ./test/certs folder, run the command to destroy the certificates. These are not signed with the correct `private_key_password` that is used in the development environment
```bash
make destroycerts
```

3. Edit the `ca.cnf`, `clients.cnf` and `server.cnf` file to use the `private_key_password` from the parameter Store, to get the password run:
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

5. Copy the generated certificate to the performance test config bucket
```bash
aws-vault exec development -- aws s3 cp ./client.pem s3://mojo-development-nac-perf-config-bucket/certs/

aws-vault exec development -- aws s3 cp ./ca.pem s3://mojo-development-nac-perf-config-bucket/certs/
```

6. Create a `test.conf` file and copy it into the s3 bucket
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
    private_key_passwd="<dev_private_key_password>"
    eapol_flags=3
}
```
  - Run:
```bash
aws-vault exec development -- aws s3 cp ./test.conf s3://mojo-development-nac-perf-config-bucket/
```

9. Create a `perf_test.sh` file and copy into the s3 bucket
```bash
# perf_test.sh
#!/usr/bin/env bash

while true
do
  eapol_test -r0 -c test.conf -a<IP-address-of-NLB> -s "PERFTEST"
done

```
- Run:
```bash
aws-vault exec development -- aws s3 cp ./perf_test.sh s3://mojo-development-nac-perf-config-bucket/
```

## Running the performance tests
- Download the key file from parameter store
```bash
aws-vault exec development -- aws ssm get-parameter --name "/network-access-control/mojo-development-nac-perf/ec2/key" --with-decryption --query "Parameter.Value"> mojo-development-nac-perf-performance-testing.pem
```

- Grab the public DNS Names of the performance test instances
```bash
aws-vault exec development -- aws ec2 describe-instances --filters "Name=tag:Name,Values='MoJ Authentication Performance-*'" --query "Reservations[].Instances[].PublicDnsName"
```

- ssh into a client EC2 instance
```bash
ssh -i mojo-development-nac-perf-performance-testing.pem ubuntu@<PublicDnsName>
```
- run the `perf_test.sh` from the instance
