# Defines what variables you are using

variable "region" {
  description = "AWS Deployment region"
  default = "us-west-2"
}

variable "keypair_name" {
  description = "SSH Key"
  sensitive = true
}

variable "api_key" {
  description = "API Key for the weather api"
  sensitive = true
}

variable "snapshot_identifier" {
  description = "RDS snapshot"
  sensitive = true
}

variable "rds_username" {
  description = "RDS username"
  sensitive = true
}

variable "rds_password" {
  description = "RDS password"
  sensitive = true
}