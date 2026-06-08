variable "aws_region" {
  description = "Regiao AWS do state bucket e da pipeline."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base dos recursos de bootstrap."
  type        = string
  default     = "royal-software-engineering-site"
}

variable "environment" {
  description = "Ambiente."
  type        = string
  default     = "prod"
}

variable "github_owner" {
  description = "Owner do repositorio GitHub."
  type        = string
  default     = "marcobacelo"
}

variable "github_repo" {
  description = "Nome do repositorio GitHub."
  type        = string
  default     = "marcobacelo.github.io"
}

variable "terraform_state_bucket_name" {
  description = "Nome do bucket S3 de state. Vazio usa rse-site-tf-state-<account-id>."
  type        = string
  default     = ""
}

variable "terraform_state_key" {
  description = "Key do state remoto da stack principal."
  type        = string
  default     = "royal-software-engineering-site/prod/email-forwarding/terraform.tfstate"
}

variable "pipeline_role_name" {
  description = "Nome da role OIDC assumida pelo GitHub Actions."
  type        = string
  default     = "rse-site-prod-email-forwarding-terraform"
}

variable "create_github_oidc_provider" {
  description = "Cria o provider OIDC do GitHub. Em conta greenfield deve ser true. Se a conta ja tiver provider, use false."
  type        = bool
  default     = true
}
