variable "service_uuid" {
  description = "UUID of the UpCloud Managed Object Storage service"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket (e.g., postgres-backup-prod)"
  type        = string
}

variable "user_name" {
  description = "Name of the IAM user (e.g., postgres-backup-prod-user)"
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM policy (e.g., postgres-backup-prod-policy)"
  type        = string
}

variable "description" {
  description = "Description of what this bucket/user is for"
  type        = string
}
