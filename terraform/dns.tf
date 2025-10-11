#################################
# Route53 Zone Lookup
#################################
data "aws_route53_zone" "kanedata_net" {
  name         = "kanedata.net."
  private_zone = false
}

#################################
# ACM Certificate + Validation
#################################
resource "aws_acm_certificate" "devportal_cert" {
  domain_name       = "devportal.kanedata.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "portal_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.devportal_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.kanedata_net.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "devportal_cert" {
  certificate_arn         = aws_acm_certificate.devportal_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.portal_cert_validation : record.fqdn]
}

#################################
# Route53 Alias Record to ALB
#################################
resource "aws_route53_record" "devportal_alias" {
  zone_id = data.aws_route53_zone.kanedata_net.zone_id
  name    = "${var.environment}.devportal.kanedata.net"
  type    = "A"

  alias {
    name                   = aws_lb.devportal.dns_name
    zone_id                = aws_lb.devportal.zone_id
    evaluate_target_health = true
  }
}

