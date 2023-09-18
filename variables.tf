variable "region" {
  description = "AWS Region where to provision VPC Network"
  type        = string
  default     = "eu-west-1"
}

variable "sftp_users" {
  description = "a sftp users list"
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "s3_bucket_name"
  type        = string
  default     = "tf-agencies-bucket"
}