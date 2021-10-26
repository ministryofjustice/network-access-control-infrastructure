# Disaster Recovery

The most likely regressions are categorised below:

  - [Corrupt radius server container](#corrupt-radius-server-container)
  - [Corrupt configuration](#corrupt-configuration)
  - [AWS failure](#aws-failure)
  - [RDS backend](#rds-backend)
  - [Breaking infrastructure updates](#breaking-infrastructure-updates)
  - [Breaking network integration updates](#breaking-network-integration-updates)

## Corrupt radius server container

Automated integration tests should catch all regressions to the service if a breaking change was introduced, rolling forward to fix the issue is the recommended solution. 

If rolling back is the only option, please see interactive automated rollback scripts [here](https://github.com/ministryofjustice/network-access-control-disaster-recovery#corrupt-container)

## Corrupt configuration

The self service admin portal validates configurations before allowing them to be published to S3.

If a corrupt configuration file managed to get through and a deployment was initiated, it would not take down the service. Instead it would fail to boot up new servers and leave the original ones to handle authentications. Alarms have been configured in Grafana to notify developers when this happens.

Two FreeRadius files are managed through the self service admin portal and stored in S3, `clients.conf` and `authorised_macs`.

At this point an investigation needs to be done to understand what has corrupted the configuration files, rolling forward to fix the issue is the recommended solution. Audit logs exist in the admin portal which will be helpful in diagnosing issues.

If rolling back is the only option, please see interactive rollback scripts [here](https://github.com/ministryofjustice/network-access-control-disaster-recovery#corrupt-config)

## AWS Failure

### Availability zone goes down

The service has been configured to run in 3 AWS availability zones in the London region:

- eu-west-2a
- eu-west-2b
- eu-west-2c

The service can withstand up to 2 availability zones going down at the same time. All 3 availability zones going down at the same time would be considered a regional failure.

### Region goes down

The service is not designed to do multi-region failover. AWS will be responsible for getting the region back up and running according to their [SLAs](https://aws.amazon.com/compute/sla/).

On-premise fallback options need to be considered in case of such an event, this will be site specific and owned by the local network administrators.

## RDS backend

The Network Access Control policy engine reads policy data from an RDS read replica, any issue would cause service disruption. The data source for this read replica is the self service admin portal RDS database.

### Running out of resources for current load

During performance testing it was noted that the read replica was the first bottleneck when reaching ~278 authentications per second.

Alarms have been set up to notify developers when the CPU of the read replica goes beyond 60%. To scale the resources on the read replica please see [Vertically Scaling Read Replica](./database-upgrade.md)

### Broken schema change

The [schema](https://github.com/ministryofjustice/network-access-control-admin/blob/main/db/schema.rb) for the policy engine read replica is managed by the self service admin portal via [Rails database migrations](https://github.com/ministryofjustice/network-access-control-admin/tree/main/db/migrate). Care needs to be taken to update the schema in a safe way. Any changes can be tested on non-live environments before deploying to production.

## Breaking infrastructure updates

### Manual breaking changes made in the console

Any manual changes made in the console can be reset by running the infrastructure pipeline in CodeBuild. Terraform will re-provision the infrastructure to be in a known good state.

## Breaking network integration updates

### MoJ network integration

Issues at the network level can be diagnosed by looking at the [VPC Flow logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html). If traffic is not flowing as expected, check the VPC route tables, security groups, network ACLs and any firewalls in between the client and servers. 

All networking configurations for the Network Access Control service are configured and managed with Terraform and stored in version control.

### OCSP integration

Client certificates are validated by checking [OCSP endpoints](https://en.wikipedia.org/wiki/Online_Certificate_Status_Protocol).
Some of these endpoints are on the private MoJ network. Any connectivity issues would cause authentications to fail for client certificates issued by that PKI. As a short term solution turn of OCSP validation in SSM parameter store until the issue can be fixed.
