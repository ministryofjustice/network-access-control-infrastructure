# Terraform State Move Scripts

During the update, upgrade and maintenance of this and other Terraform projects there will be occasions where a different Terraform code will manage existing resources.
The [terraform state mv](https://developer.hashicorp.com/terraform/cli/v1.1.x/commands/state/mv) command is very useful for this

```terraform
terraform state mv [options] SOURCE DESTINATION
```

## Scripts

In order to make this operation repeatable for each environment and have an audit of changes we have created a script which is invoked via `make` target.
This enables consistency and ability to have different commands for each environment when necessary.

### How to use the script:

1. Copy template script and give same name as branch including the Jira reference.
1. Prepare script with the changes.
1. Test script against a workspace or development environment.
   1. Run plan (see changes)
   2. Run script (move resources within state file)
   3. Run plan (see no changes should be required)

### How to prepare the script

```shell
cp scripts/tf_mv/a_template.sh scripts/tf_mv/$(git_current_branch).sh
```

Assuming the code is refactored at this point, run a `make plan`
Then copy the changes of the `destroy` resource and create resource.

In our example we have `Plan: 10 to add, 2 to change, 10 to destroy`

So we would take each `destroy` resource reference (SOURCE)

```shell
module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_api[0]
```

And each corresponding `create` (DESTINATION)

```shell
module.radius_vpc.aws_vpc_endpoint.ecr_api
```

And format the two items as an associative array element. [e.g. ND-134-vpc-module.sh line 12](../scripts/tf_mv/ND-134-vpc-module.sh)

```shell
["module.radius_vpc.module.vpc.aws_vpc_endpoint.ecr_api[0]"]='module.radius_vpc.aws_vpc_endpoint.ecr_api'
```

Where the item references an explicit AWS resource, in our next example a route table ID;

```shell
module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2] will be destroyed
  # (because aws_vpc_endpoint_route_table_association.private_s3 is not in configuration)
  - resource "aws_vpc_endpoint_route_table_association" "private_s3" {
      - id              = "a-vpce-0ecc49001cee421f03369608862" -> null
      - route_table_id  = "rtb-083c893b7acb2dd7d" -> null
      - vpc_endpoint_id = "vpce-0ecc49001cee421f0" -> null
    }
```

```shell
module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-083c893b7acb2dd7d"]
```

We match the count index with the route_table_id and would create and entry for the environment in the environment specific array as follows:
see [e.g. ND-134-vpc-module.sh line 25](../scripts/tf_mv/ND-134-vpc-module.sh)

```shell
["module.radius_vpc.module.vpc.aws_vpc_endpoint_route_table_association.private_s3[2]"]='module.radius_vpc.aws_vpc_endpoint_route_table_association.private_s3["rtb-083c893b7acb2dd7d"]'
```

The script will merge the common resources with the specific environment resources.

## Check changes

Once the script is prepared for each environment it can be applied. By default the script will run the `terraform state mv` command with the `--dry-run` flag.

The following make command uses the `SCRIPT` argument to select the correct script (no file extension should be used)

```shell
make move_script SCRIPT="ND-134-vpc-module"
```

## Apply changes

As above but add an additional argument `APPLY=true`

```shell
make move_script SCRIPT="ND-134-vpc-module" APPLY=true
```

## External URLS

- https://developer.hashicorp.com/terraform/cli/v1.1.x/commands/state/mv
