# Provider Configuration 
provider "aws" {
  # I configured the access_key and the secret_key in aws cli that I downloaded to the local computer
  # access_key = "YOUR_AWS_ACCESS_KEY"
  # secret_key = "YOUR_AWS_SECRET_KEY"
  # region     = "us-west-2" # Replace with your desired AWS region

  region     = var.region # Replace with your desired AWS region
}