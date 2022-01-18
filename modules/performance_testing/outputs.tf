output "iam" {
  value = {
    ec2_task_role_arn = aws_iam_role.moj_auth_poc_role.arn
  }
}
