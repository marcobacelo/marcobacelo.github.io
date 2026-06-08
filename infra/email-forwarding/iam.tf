data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "forward_contact_email" {
  name               = local.email_forwarder_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "forward_contact_email" {
  statement {
    sid    = "WriteLambdaLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.forward_contact_email.arn}:*",
    ]
  }

  statement {
    sid    = "ReadInboundEmailObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.inbound_email.arn}/${local.s3_prefix}*",
    ]
  }

  statement {
    sid    = "ForwardEmailWithSes"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_role_policy" "forward_contact_email" {
  name   = local.email_forwarder_name
  role   = aws_iam_role.forward_contact_email.id
  policy = data.aws_iam_policy_document.forward_contact_email.json
}
