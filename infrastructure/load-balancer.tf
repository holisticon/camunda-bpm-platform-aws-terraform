data "aws_acm_certificate" "domain_cert" {
  domain = var.alb_domain_name
}

resource "aws_alb" "main" {
  name            = "${var.environment_name}-alb"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]

  tags = {
    Environment = var.environment_name
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.main.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = data.aws_acm_certificate.domain_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No service available"
      status_code  = "404"
    }
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}