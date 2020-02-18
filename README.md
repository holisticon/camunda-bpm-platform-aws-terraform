Terraform Provisioning of 

- [Camunda-BPM-Platform Docker Container](https://github.com/camunda/docker-camunda-bpm-platform)
on AWS Elastic Container Service (ECS) on AWS Fargate
- Aurora Serverless Database 

and the required underlying AWS Infrastructure:
- VPC, Subnets, Internet Gateway, Application Load Balancer, Security Groups, IAM Roles, DNS Route 53 record (Domain in Route 53 and SSL certificate required)

for training purposes.

What's not included:
- Domain (public hosted zone) in AWS Route 53 and SSL certificate in AWS Certifcate manager for Load Balancer 
- For simplicity reasons only public VPC Subnets are used: You may want to add private Subnets, NAT Gateways and VPC Endpoints in production scenarios
- Application Auto-Scaling
- Monitoring

Prerequisites:
- [Opt-in for new ECS ARN / ID](https://docs.aws.amazon.com/AmazonECS/latest/userguide/ecs-account-settings.html)
