locals {
  account_id           = data.aws_caller_identity.current.account_id
  name_prefix          = "${var.project_name}-${var.environment}"
  resource_prefix      = replace(local.name_prefix, "_", "-")
  email_bucket_name    = coalesce(var.email_bucket_name_override, "${local.resource_prefix}-email-inbound-${local.account_id}")
  email_forwarder_name = coalesce(var.email_forwarder_name_override, "${local.resource_prefix}-email-forwarder")
  receipt_rule_name    = coalesce(var.receipt_rule_name_override, "${local.resource_prefix}-contact-forward")
  rule_set_name        = coalesce(var.rule_set_name_override, "${local.resource_prefix}-email-inbound")
  s3_prefix            = "contact/"
}
