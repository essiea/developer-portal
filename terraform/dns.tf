resource "aws_route53_record" "devportal_alias" {
  zone_id = data.aws_route53_zone.kanedata_net[0].zone_id
  name    = "devportal.kanedata.net"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_lb.this]
}

