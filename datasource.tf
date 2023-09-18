# SFTP users
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "sftp" {
  statement {
    sid       = "AllowFullAccesstoS3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}