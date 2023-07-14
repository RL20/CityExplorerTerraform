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
  load_balancers = [ aws_elb.app_elb.id ]# tell the aws_autoscaling_group to registered every instance it create to the load balancer
  lifecycle {
    // Use the `create_before_destroy` lifecycle block to ensure the new autoscaling group is created first
    create_before_destroy = true
  }
}

# Load Balancer
resource "aws_elb" "app_elb" {
  name               = "app-elb"
  security_groups    = [aws_security_group.load_blancer_SG.id]
  availability_zones = ["us-west-2a", "us-west-2b"] # Replace with your desired availability zones

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:5000/health" # Check if the instance is online at /health
  }

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
resource "aws_security_group" "load_blancer_SG" {
  name        = "load_blancer_SG"
  description = "security group for the city explorer app"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0" #from any port 
    to_port     = "0" #to any port
    protocol    = "-1" # any protocol 
    cidr_blocks = ["0.0.0.0/0"] # any url
  }
}

# RDS
resource "aws_db_instance" "city-explorer_db" {
  identifier            = "city-explorer-db"
  allocated_storage     = 20
  engine                = "mysql"
  engine_version        = "8.0.32"
  instance_class        = "db.t2.micro"
  username              = var.rds_username
  password              = var.rds_password
  publicly_accessible  = false
  skip_final_snapshot = true
  snapshot_identifier   = var.snapshot_identifier
  tags = {
    "name" = "city-explorer-db"
  }
} 

resource "aws_autoscaling_policy" "cityexplorer_policy_up" {
  name                   = "cityexplorer_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cityexplorer_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cityexplorer_cpu_alarm_up" {
  alarm_name          = "cityexplorer_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cityexplorer_asg.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.cityexplorer_policy_up.arn}"]
}

resource "aws_autoscaling_policy" "cityexplorer_policy_down" {
  name                   = "cityexplorer_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cityexplorer_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cityexplorer_cpu_alarm_down" {
  alarm_name          = "cityexplorer_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cityexplorer_asg.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.cityexplorer_policy_down.arn}"]
}