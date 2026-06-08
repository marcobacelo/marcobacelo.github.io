data "aws_caller_identity" "current" {}

resource "aws_sesv2_email_identity" "domain" {
  count          = var.manage_ses_domain_identity ? 1 : 0
  email_identity = var.domain_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_s3_bucket" "inbound_email" {
  bucket = "${local.resource_prefix}-inbound-email-${local.account_id}"
}

resource "aws_s3_bucket_public_access_block" "inbound_email" {
  bucket = aws_s3_bucket.inbound_email.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inbound_email" {
  bucket = aws_s3_bucket.inbound_email.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "inbound_email" {
  bucket = aws_s3_bucket.inbound_email.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "inbound_email" {
  bucket = aws_s3_bucket.inbound_email.id

  rule {
    id     = "expire-inbound-email"
    status = "Enabled"

    filter {
      prefix = local.s3_prefix
    }

    expiration {
      days = var.inbound_email_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.inbound_email_retention_days
    }
  }
}

data "aws_iam_policy_document" "ses_put_inbound_email" {
  statement {
    sid    = "AllowSesReceiptRuleToStoreEmail"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.inbound_email.arn}/${local.s3_prefix}*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:ses:${var.aws_region}:${local.account_id}:receipt-rule-set/${local.rule_set_name}:receipt-rule/${local.receipt_rule_name}",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "inbound_email" {
  bucket = aws_s3_bucket.inbound_email.id
  policy = data.aws_iam_policy_document.ses_put_inbound_email.json
}

data "archive_file" "forward_contact_email" {
  type        = "zip"
  source_file = "${path.module}/lambda/forward_contact_email.py"
  output_path = "${path.module}/.terraform/build/forward_contact_email.zip"
}

resource "aws_cloudwatch_log_group" "forward_contact_email" {
  name              = "/aws/lambda/${local.resource_prefix}-forward-contact-email"
  retention_in_days = 30
}

resource "aws_lambda_function" "forward_contact_email" {
  function_name    = "${local.resource_prefix}-forward-contact-email"
  description      = "Encaminha e-mails recebidos em ${var.contact_recipient} para ${var.forward_to_address}."
  role             = aws_iam_role.forward_contact_email.arn
  runtime          = "python3.12"
  handler          = "forward_contact_email.handler"
  filename         = data.archive_file.forward_contact_email.output_path
  source_code_hash = data.archive_file.forward_contact_email.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      S3_BUCKET       = aws_s3_bucket.inbound_email.bucket
      S3_PREFIX       = local.s3_prefix
      CONTACT_ADDRESS = var.contact_recipient
      FORWARD_FROM    = var.forward_from_address
      FORWARD_TO      = var.forward_to_address
      SUBJECT_PREFIX  = var.subject_prefix
    }
  }

  depends_on = [aws_cloudwatch_log_group.forward_contact_email]
}

resource "aws_lambda_permission" "allow_ses" {
  statement_id   = "AllowExecutionFromSes"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.forward_contact_email.function_name
  principal      = "ses.amazonaws.com"
  source_account = local.account_id
  source_arn     = "arn:aws:ses:${var.aws_region}:${local.account_id}:receipt-rule-set/${local.rule_set_name}:receipt-rule/${local.receipt_rule_name}"
}

resource "aws_ses_receipt_rule_set" "contact" {
  rule_set_name = local.rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "contact" {
  count         = var.activate_receipt_rule_set ? 1 : 0
  rule_set_name = aws_ses_receipt_rule_set.contact.rule_set_name
}

resource "aws_ses_receipt_rule" "contact" {
  name          = local.receipt_rule_name
  rule_set_name = aws_ses_receipt_rule_set.contact.rule_set_name
  enabled       = true
  scan_enabled  = true
  recipients    = [var.contact_recipient]

  s3_action {
    bucket_name       = aws_s3_bucket.inbound_email.bucket
    object_key_prefix = local.s3_prefix
    position          = 1
  }

  lambda_action {
    function_arn    = aws_lambda_function.forward_contact_email.arn
    invocation_type = "Event"
    position        = 2
  }

  depends_on = [
    aws_lambda_permission.allow_ses,
    aws_s3_bucket_policy.inbound_email,
  ]
}
