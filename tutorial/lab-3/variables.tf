variable environment_name {
    description = "Logical identifier for the camunda environment inside an AWS account"
}

variable shared_infrastructure_env {
    description = "name of the share infrastructure (variable environment_name in ../../infrastructure)"
}

variable domain_name {
    description = "The name of the hosted zone in route53"
}