# Highly Available AWS Solution

This Terraform configuration will deploy a highly available AWS solution consist of 2 EC2 instances in 2 Availability Zones with an Application LoadBalancer that distribute traffic and DynamoDB, S3 for keeping the Employee Data

**It will:

- Create AMI instance template that AutoScaling will use to create ASG instances
- Create an Auto Scaling Group to maintain the desired number of EC2 instances in 2 Availability Zones
- Create an Application Load Balancer in front of the instances
- Assign security groups to allow traffic to the instances
- Create S3 for the Application images with DynamoDB


### In the Terraform configuration, you can define:

EC2 instance type
AMI
Security group rules
Load Balancer settings
Auto Scaling Group settings like min/max instance count and health check grace period


## Usage

1. Install Terraform
2. Configure your AWS credentials (access key and secret access key)
3. Run `terraform init` to initialize Terraform and download required providers
4. Run `terraform plan` to see the infrastructure changes Terraform will make
5. Run `terraform apply` to apply the changes


## Terraform Files

- `variables.tf` - Defines variables used in the configuration
- `output.tf` - Defines output values to display after running Terraform 


## Notes

- If you make changes to the configuration, run `terraform plan` to preview changes and `terraform apply` to apply them. 
- Terraform will avoid recreating resources that don't need to change.
- The Auto Scaling Group will maintain 2 up to 4 EC2 instances at all times and replace any instances that are terminated.
- The Application Load Balancer will distribute traffic between the two EC2 instances for high availability.


