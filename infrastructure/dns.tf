data "aws_route53_zone" "hosted_zone" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "alb_subdomain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.alb_domain_name
  type    = "A"

  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = true
  }
}