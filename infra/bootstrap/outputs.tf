output "aws_region" {
  value = var.aws_region
}

output "aws_role_to_assume" {
  value = aws_iam_role.pipeline.arn
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_key" {
  value = var.terraform_state_key
}

output "github_repository_variables" {
  description = "Valores para configurar em GitHub Actions repository variables."
  value = {
    AWS_REGION         = var.aws_region
    AWS_ROLE_TO_ASSUME = aws_iam_role.pipeline.arn
    TF_STATE_BUCKET    = aws_s3_bucket.terraform_state.bucket
    TF_STATE_KEY       = var.terraform_state_key
  }
}
