output "inbound_email_bucket" {
  description = "Bucket S3 onde o SES salva as mensagens brutas recebidas."
  value       = aws_s3_bucket.inbound_email.bucket
}

output "contact_recipient" {
  description = "Endereco publico recebido pelo SES."
  value       = var.contact_recipient
}

output "forward_to_address" {
  description = "Endereco final que recebe o encaminhamento."
  value       = var.forward_to_address
}

output "ses_inbound_mx_record" {
  description = "Registro MX que deve ser criado no DNS do dominio, por exemplo no registro.br."
  value = {
    name     = var.domain_name
    type     = "MX"
    priority = 10
    value    = "inbound-smtp.${var.aws_region}.amazonaws.com"
  }
}

output "recommended_spf_record" {
  description = "SPF recomendado quando SES for usado para enviar e encaminhar e-mails deste dominio. Combine com outros provedores se existirem."
  value = {
    name  = var.domain_name
    type  = "TXT"
    value = "v=spf1 include:amazonses.com ~all"
  }
}

output "recommended_dmarc_record" {
  description = "DMARC inicial recomendado. Troque rua para um endereco que ja receba mensagens."
  value = {
    name  = "_dmarc.${var.domain_name}"
    type  = "TXT"
    value = "v=DMARC1; p=none; rua=mailto:${var.forward_to_address}"
  }
}
