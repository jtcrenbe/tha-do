terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = var.region
  access_key = "AKIA2X2ION4KRCHUWZEO"
  secret_key = "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"
}

# S3
resource "aws_s3_bucket" "agencies_s3" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = "Stage"
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 14
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.agencies_s3.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "agencies_s3_versioning" {
  bucket = aws_s3_bucket.agencies_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SFTP server
resource "aws_cloudwatch_log_group" "sftp_server" {
  name_prefix = "sftp_server_"
}

resource "aws_iam_role" "sftp_server_logs" {
  name_prefix         = "sftp_server_logs_"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  logging_role  = aws_iam_role.sftp_server_logs.arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.sftp_server.arn}:*"
  ]

  tags = {
    NAME = "tf-transfer-server"
  }
}

# SFTP users
resource "aws_iam_role" "transfer_user" {
  name               = "tf-transfer-user-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "tu_policy" {
  name   = "tf-transfer-user-iam-policy"
  role   = aws_iam_role.transfer_user.id
#  policy = file("iam_policies/tu_policy.json")
  policy = data.aws_iam_policy_document.sftp.json
}

resource "aws_transfer_user" "sftp_user" {
  for_each  = toset(var.sftp_users)
  server_id = aws_transfer_server.sftp_server.id
  user_name = each.key
  role      = aws_iam_role.transfer_user.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.agencies_s3.id}/$${Transfer:UserName}"
  }
}

resource "aws_transfer_ssh_key" "sftp_user_key" {
  for_each  = toset(var.sftp_users)
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user[each.key].user_name
  body      = file("sftp_keys/${each.key}.pub")
}

# Route53
# resource "aws_route53_record" "docs" {
#   zone_id = aws_route53_zone.primary.zone_id
#   name    = "docs"
#   type    = "CNAME"
#   ttl     = 5

#   records        = [aws_transfer_server.sftp_server.endpoint]
# }