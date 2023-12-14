# TerraformAWSproject
# EC2 Utilization Monitoring and Alerting

## Project Description

This project aims to monitor the utilization of an EC2 instance, and when it exceeds 40%, trigger an alarm through the AWS Simple Notification Service (SNS). The SNS service then triggers a Lambda function, which uses the Twilio API to send an alert message to the designated engineer.

## Technologies Used

- *AWS Services:*
  - EC2
  - CloudWatch
  - SNS
  - Lambda

- *External API:*
  - Twilio API for sending SMS notifications

- *Infrastructure as Code:*
  - Terraform
