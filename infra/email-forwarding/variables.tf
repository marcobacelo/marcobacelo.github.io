variable "aws_region" {
  description = "Regiao AWS onde o SES inbound sera configurado. Deve suportar recebimento SES."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base usado em recursos AWS."
  type        = string
  default     = "rse"
}

variable "environment" {
  description = "Ambiente da infraestrutura."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Dominio institucional que recebera e-mails."
  type        = string
  default     = "royalsoftwareengineering.com.br"
}

variable "manage_ses_domain_identity" {
  description = "Cria a identidade SES do dominio nesta stack. Em conta greenfield deve ser true. Se a identidade ja existir em outro state, importe antes do apply ou mude para false."
  type        = bool
  default     = true
}

variable "contact_recipient" {
  description = "Endereco publico recebido pelo SES inbound."
  type        = string
  default     = "contato@royalsoftwareengineering.com.br"
}

variable "forward_to_address" {
  description = "Endereco pessoal que recebera os encaminhamentos."
  type        = string
  default     = "marcobacelo90@gmail.com"
}

variable "forward_from_address" {
  description = "Endereco verificado no SES usado como remetente do encaminhamento."
  type        = string
  default     = "contato@royalsoftwareengineering.com.br"
}

variable "subject_prefix" {
  description = "Prefixo aplicado aos assuntos encaminhados."
  type        = string
  default     = "[Royal Software Engineering]"
}

variable "inbound_email_retention_days" {
  description = "Quantidade de dias para manter a copia bruta dos e-mails recebidos no S3."
  type        = number
  default     = 90

  validation {
    condition     = var.inbound_email_retention_days >= 1
    error_message = "inbound_email_retention_days deve ser maior ou igual a 1."
  }
}

variable "activate_receipt_rule_set" {
  description = "Ativa o rule set SES. Atenção: existe apenas um receipt rule set ativo por regiao/conta."
  type        = bool
  default     = true
}
