# Provider Configuration 
provider "aws" {
  # I configured the access_key and the secret_key in aws cli that I downloaded to the local computer
  # access_key = "YOUR_AWS_ACCESS_KEY"
  # secret_key = "YOUR_AWS_SECRET_KEY"
  # region     = "us-west-2" # Replace with your desired AWS region

  region     = var.region # Replace with your desired AWS region
}

# Launch Configuration
resource "aws_launch_configuration" "cityexplorer_lc" {
  name_prefix   = "cityexplorer-"
  image_id      = "ami-03f65b8614a860c29" # Replace with your desired AMI ID example →#ami-03f65b8614a860c29 (64-bit (x86)) 
  key_name = var.keypair_name
  
  instance_type = "t2.micro" # Replace with your desired instance type
  security_groups = [aws_security_group.cityexplorer_app.id]
  user_data = templatefile("templates/userdata.sh", {
    api_key = var.api_key,
    rds_username = var.rds_username,
    rds_password = var.rds_password,
    rds_url = aws_db_instance.city-explorer_db.address
  })
  # iam_instance_profile        = var.iam // if i defined a diffrent user so it can jave access to specific service (example ec2)
  #so it can create only ec2 and won't have an access to any other services 
  lifecycle {
    // Use the `create_before_destroy` lifecycle block to ensure the new launch configuration is created first
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "cityexplorer_asg" {
  name                 = "cityexplorer_asg"
  launch_configuration = aws_launch_configuration.cityexplorer_lc.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  availability_zones = [ "${var.region}a" ]
  lifecycle {
    // Use the `create_before_destroy` lifecycle block to ensure the new autoscaling group is created first
    create_before_destroy = true
  }
}

# Load Balancer
resource "aws_elb" "app_elb" {
  name               = "app-elb"
  security_groups    = [aws_security_group.cityexplorer_app.id]
  availability_zones = ["us-west-2a", "us-west-2b"] # Replace with your desired availability zones

  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

# Security Group
resource "aws_security_group" "cityexplorer_app" {
  name        = "cityexplorer_app"
  description = "security group for the city explorer app"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Gives the possibility to connect to any external source, 
  # for example if I want to update a package for the application or download a file, 
  # then it gives permission to download or connect anywhere ↓
  egress {
    from_port   = "0" #from any port 
    to_port     = "0" #to any port
    protocol    = "-1" # any protocol 
    cidr_blocks = ["0.0.0.0/0"] # any url
  }
}
