# CityExplorerTerraform

This is the Terraform repository for my CityExplorer project. It contains infrastructure-as-code (IaC) configurations to deploy and manage the CityExplorer application on AWS.
The other repositories are [CityExplorerChef](https://github.com/RL20/CityExplorerChef.git) ,[CityExplorer](https://github.com/RL20/CityExplorer.git), 

## Prerequisites

Before you begin, ensure that you have the following prerequisites:

- AWS CLI installed on your local computer
- Access Key and Secret Key configured in the AWS CLI
- Desired AWS region set in the configuration

## Getting Started

To get started with the CityExplorer Terraform project, follow these steps:

1. Clone the repository:
   
   git clone https://github.com/RL20/CityExplorerTerraform.git
   


2. Navigate to the project directory:
   
   cd CityExplorerTerraform
   


3. Update the variables in variables.tf to match your requirements.

4. Initialize the Terraform project:
   
   terraform init
   


5. Review the execution plan:
   
   terraform plan
   


6. Deploy the infrastructure:
   
   terraform apply
   


## Configuration

The main.tf file contains the following Terraform resources:

- Provider Configuration: Configures the AWS provider using the specified region.

- Launch Configuration: Defines the launch configuration for the CityExplorer instances, including instance type, security groups, and user data.

- Auto Scaling Group: Configures the auto scaling group for the CityExplorer instances, specifying the minimum and maximum number of instances.

- Load Balancer: Sets up the load balancer for the CityExplorer application, with the specified listener settings.

- Security Group: Defines the security group rules for the CityExplorer instances, allowing inbound traffic on ports 5000, 22, and 3306. The egress rules allow outbound traffic to any destination.

- RDS: Creates an RDS instance for the CityExplorer database, using MySQL as the engine.

- Auto Scaling Policies and CloudWatch Alarms: Configures auto scaling policies and associated CloudWatch alarms for scaling the instances based on CPU utilization.

Please ensure that you have the necessary permissions and access keys configured to deploy and manage the infrastructure.

## License

This project is licensed under the [MIT License](LICENSE).


