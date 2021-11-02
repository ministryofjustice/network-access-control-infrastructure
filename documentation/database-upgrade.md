# Vertically scaling the Read Replica

This guide explains how to scale the read replica used by the Network Access Control Service to increase performance and support a higher number of authentications per second.

## Overview

The Network Access Control service connects to a single RDS read replica to get access to policy data. This read replica runs in multiple availability zones for reliability.
During performance testing it was noted that high CPU usage on the read replica was the bottleneck. Unlike the ECS cluster, there is no capability for the read replica to [scale horizontally](https://aws.amazon.com/blogs/database/scaling-your-amazon-rds-instance-vertically-and-horizontally/). It needs to be scaled vertically (manually) to increase performance.

Alarms have been set up to monitor the CPU of this read replica and set to go off if the CPU usage is over 65%.

These alarms will prompt engineers and provide sufficient time to upgrade the database to improve performance of the service.

The steps required to upgrade the database are:

1. Create a new read replica 
2. Update connection details for radius servers
3. Remove the old read replica

## Create new read replica

Copy the definition of the current read replica resource in modules/admin_read_replica/main.tf:

```
resource "aws_db_instance" "admin_read_replica" {
```

Give it a unique resource name for example

```
resource "aws_db_instance" "admin_read_replica_xl" {
```

Update the instance class to the desired [RDS instance type](https://aws.amazon.com/rds/instance-types/) eg. `db.t3.xlarge`

Update the identifier property on this resource and give it a unique name eg. `"${var.prefix}-xl"`

*Commit this change and push it through the pipeline*

## Update connection details for radius servers

Update the read replica terraform outputs host and name values in `modules/admin_read_replica/outputs.tf` to reference the new read replica.

```
output "rds" {
  value = {
    name = aws_db_instance.admin_read_replica_xl.name             << HERE
    host = aws_db_instance.admin_read_replica_xl.address          << HERE 
    security_group_id = aws_security_group.admin_read_replica.id
  }
}
```

This will be passed through to the radius module task definition and be set as environment variables for any new servers to use.

*Commit this change and push it through the pipeline*

A zero downtime deployment will automatically be started once this goes through the pipeline.

## Remove the old read replica

Remove the original `resource "aws_db_instance" "admin_read_replica"` resource definition from modules/admin_read_replica/main.tf

This original read replica will now be unused, with all radius servers connecting to the new read replica.

*Commit this change and push it through the pipeline*
