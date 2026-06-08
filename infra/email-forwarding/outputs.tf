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

output "ses_domain_identity_arn" {
  description = "ARN da identidade SES do dominio, quando gerenciada por esta stack."
  value       = var.manage_ses_domain_identity ? aws_sesv2_email_identity.domain[0].arn : null
}

output "ses_dkim_cname_records" {
  description = "CNAMEs DKIM para publicar no DNS quando a identidade SES for criada por esta stack."
  value = var.manage_ses_domain_identity ? [
    for token in aws_sesv2_email_identity.domain[0].dkim_signing_attributes[0].tokens : {
      name  = "${token}._domainkey.${var.domain_name}"
      type  = "CNAME"
      value = "${token}.dkim.amazonses.com"
    }
  ] : []
}

output "ses_verified_for_sending_status" {
  description = "Status de verificacao da identidade SES para envio, quando gerenciada por esta stack."
  value       = var.manage_ses_domain_identity ? aws_sesv2_email_identity.domain[0].verified_for_sending_status : null
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
