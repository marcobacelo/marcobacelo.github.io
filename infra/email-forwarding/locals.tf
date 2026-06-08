locals {
  account_id        = data.aws_caller_identity.current.account_id
  name_prefix       = "${var.project_name}-${var.environment}"
  resource_prefix   = replace(local.name_prefix, "_", "-")
  receipt_rule_name = "${local.resource_prefix}-contact-forward"
  rule_set_name     = "${local.resource_prefix}-inbound"
  s3_prefix         = "contact/"
}
