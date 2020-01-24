variable "aws_region" {
  description = "Target AWS region name"
}

variable "aws_profile" {
  description = "Named profile you configured in ~/.aws/credentials"
  default = "default"
}

variable "environment_name" {
  description = "Identifies the target environment. Allows to deploy multiple intfrastructures in the same account."
  default = "demo"
}

variable "app_port" {
  default = 8080
}

variable "domain_name" {
  description = "Name of the existing Route53 public hosted zone."
}

variable "alb_domain_name" {
  description = "Subdomain (full-qualified) for the application loaderbalancer. Route 53 record will be created."
}
