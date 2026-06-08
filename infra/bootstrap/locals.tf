data "aws_caller_identity" "current" {}

locals {
  account_id                  = data.aws_caller_identity.current.account_id
  repository_slug             = "${var.github_owner}/${var.github_repo}"
  name_prefix                 = "${var.project_name}-${var.environment}"
  terraform_state_bucket_name = var.terraform_state_bucket_name != "" ? var.terraform_state_bucket_name : "${local.name_prefix}-tfstate-${local.account_id}"
  inbound_email_bucket_name   = "${local.name_prefix}-email-inbound-${local.account_id}"
  lambda_function_name        = "${local.name_prefix}-email-forwarder"
  lambda_role_name            = "${local.name_prefix}-email-forwarder"
  github_oidc_provider_arn    = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}
