# Request ACM certificate for portal domain
resource "aws_acm_certificate" "portal_cert" {
  domain_name       = var.portal_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Conditional Route 53 validation (only if using AWS DNS)
data "aws_route53_zone" "kanedata_net" {
  count        = var.use_route53 ? 1 : 0
  name         = var.zone_name
  private_zone = false
}


resource "aws_route53_record" "portal_cert_validation" {
  count = var.use_route53 ? length(aws_acm_certificate.portal_cert.domain_validation_options) : 0

  name    = element(aws_acm_certificate.portal_cert.domain_validation_options.*.resource_record_name, count.index)
  type    = element(aws_acm_certificate.portal_cert.domain_validation_options.*.resource_record_type, count.index)
  records = [element(aws_acm_certificate.portal_cert.domain_validation_options.*.resource_record_value, count.index)]
  ttl     = 60
  zone_id = data.aws_route53_zone.kanedata_net[0].zone_id
}

resource "aws_acm_certificate_validation" "portal_cert_validation" {
  count = var.use_route53 ? 1 : 0

  certificate_arn         = aws_acm_certificate.portal_cert.arn
  validation_record_fqdns = aws_route53_record.portal_cert_validation.*.fqdn
}

