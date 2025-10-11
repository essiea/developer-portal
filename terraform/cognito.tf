#######################################
# Amazon Cognito Configuration
#######################################

resource "aws_cognito_user_pool" "devportal_pool" {
  name = "${var.project_name}-userpool"

  # Verify and login by email
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  # Password policy
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  # MFA (optional)
  mfa_configuration = "OFF"

  email_verification_message = "Your verification code is {####}"
  email_verification_subject = "Verify your DevPortal account"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

#######################################
# Cognito App Client (Hosted UI)
#######################################

resource "aws_cognito_user_pool_client" "devportal_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.devportal_pool.id

  generate_secret = false

  # Hosted UI OAuth flows
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]

  callback_urls = [
    "https://${var.portal_domain}/",        # Main app redirect
    "https://${var.portal_domain}/api/auth" # API redirect (optional)
  ]

  logout_urls = [
    "https://${var.portal_domain}/"
  ]

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [aws_cognito_user_pool.devportal_pool]
}

#######################################
# Cognito Domain for Hosted UI
#######################################

resource "aws_cognito_user_pool_domain" "devportal_domain" {
  domain       = var.cognito_domain_prefixes[var.environment] # must be globally unique
  user_pool_id = aws_cognito_user_pool.devportal_pool.id
}

#######################################
# (Optional) Initial Admin User
#######################################

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.devportal_pool.id
  username     = "admin@${var.portal_domain}"

  attributes = {
    email          = "admin@${var.portal_domain}"
    email_verified = "true"
  }

  temporary_password = "Admin@123!"
  depends_on         = [aws_cognito_user_pool.devportal_pool]
}

