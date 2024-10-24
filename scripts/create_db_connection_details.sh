#!/usr/bin/env bash

db_type=${1}
file_name=".db_connection.${ENV}.${db_type}"
terraform_outputs=$(terraform output -json)

if [ ${db_type} == "admin" ]; then
  ## Admin RDS
  admin_db_username=admin
  admin_db_fqdn=$(echo ${terraform_outputs} | jq -r '.terraform_outputs.value.admin.rds.fqdn')
  admin_db_port=$(echo ${terraform_outputs} | jq -r '.terraform_outputs.value.admin.rds.port')
  admin_db_name=$(echo ${terraform_outputs} | jq -r '.terraform_outputs.value.admin.rds.name')

cat << EOF > ./${file_name}
Connections strings for ${ENV} environment RDS

NAC Admin RDS:
Test connection:
Copy command below to test RDS DB access from Admin RDS Bastion.
----
curl -v telnet://${admin_db_fqdn}:${admin_db_port} --output rds.admin.txt



Connect to DB with MySQL client:
Copy command below to test RDS DB access from Admin RDS Bastion.
-----
mysql --user=${admin_db_username} --host=${admin_db_fqdn} --port=${admin_db_port} --password


Create DB dump and push to S3
--------
filename="\`date "+%Y_%m_%d-%H_%M_%S"\`_${ENV}_${admin_db_name}_rds-dump.sql"; \\
mysqldump \\
	-u "${admin_db_username}" \\
	-p \\
	--set-gtid-purged=OFF \\
	--triggers --routines --events \\
	-h "${admin_db_fqdn}"  \\
	"${admin_db_name}" > ~/\${filename}; \\
	ls -al; \\
aws s3 cp ~/\${filename} s3://mojo-file-transfer/ --profile s3-role; \\
aws s3 ls s3://mojo-file-transfer/ --profile s3-role;

EOF
fi

cat ./${file_name}
