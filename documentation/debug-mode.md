# Debug Mode

Two debugging features can be used to troubleshoot issues in production and non-production environments.

1. Verbose logging
2. Server side packet captures

## Verbose logging

To enable verbose logging on the FreeRadius servers: 

1. Set the following SSM parameter to `true` in the Shared services AWS Account 

`/moj-network-access-control/$ENV/debug/radius/verbose_logging`

2. Re-deploy the infrastructure the Shared Services CodePipeline, this will update the ECS task definition and automatically kick off a rolling deployment.

This will start the radius server with the [-xx](https://github.com/ministryofjustice/network-access-control-server/blob/main/scripts/bootstrap.sh) flag passed for verbose logging.

```bash
freeradius -fxx -l stdout
```

## Server side packet captures

To perform a server side packet capture:

1. Set the following SSM parameter to `true` in the Shared services AWS Account:

`/moj-network-access-control/$ENV/debug/radius/enable_packet_capture`

2. Set the packet capture duration in seconds for the following SSM parameter in the Shared services AWS Account:

`/moj-network-access-control/$ENV/debug/radius/packet_capture_duration_seconds`

3. Re-deploy the infrastructure the Shared Services CodePipeline, this will update the ECS task definition and automatically kick off a rolling deployment.

This will start [tshark](https://github.com/ministryofjustice/network-access-control-server/blob/main/scripts/bootstrap.sh) listening on all network interfaces for the duration seconds specified. 

```bash
tshark -i any -w ./captures/$capture_file -a duration:${PACKET_CAPTURE_DURATION}
```

The results of this capture will be uploaded to the Radius configuration bucket under `./captures/container_id.pcap`. These files can be downloaded and analyzed for issues.