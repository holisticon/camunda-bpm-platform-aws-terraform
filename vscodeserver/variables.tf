variable environment_name {
  description = "Logical identifier for the IDE inside the AWS account"
  type        = set(string)
}

variable shared_infrastructure_env {
  description = "name of the share infrastructure (variable environment_name in ../../infrastructure)"
}

variable domain_name {
  description = "The name of the hosted zone in route53"
}

variable container_image {
  default = "codercom/code-server:2.1698"
}

variable fargate_cpu {
  default = 1024
}

variable fargate_memory {
  default = 2048
}

variable password {
  description = "vscode server password"
}
