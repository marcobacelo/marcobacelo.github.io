# Email forwarding institucional

Infra Terraform para receber mensagens enviadas para `contato@royalsoftwareengineering.com.br` via Amazon SES e encaminhar para `marcobacelo90@gmail.com`.

## Arquitetura

```text
contato@royalsoftwareengineering.com.br
  -> MX do dominio aponta para SES inbound
  -> SES Receipt Rule
  -> S3 guarda a mensagem bruta
  -> Lambda le a mensagem e encaminha via SES
  -> marcobacelo90@gmail.com
```

Esta stack cria a identidade SES do dominio por padrao (`manage_ses_domain_identity=true`), para funcionar em uma conta AWS greenfield.

Se a identidade SES `royalsoftwareengineering.com.br` ja existir na mesma conta/regiao e estiver gerenciada por outro Terraform state, o primeiro `apply` vai falhar com conflito de recurso existente. Nesse caso, escolha uma das opcoes:

1. Importar a identidade para esta stack:

```bash
terraform import 'aws_sesv2_email_identity.domain[0]' royalsoftwareengineering.com.br
```

2. Ou manter a identidade fora desta stack e configurar:

```hcl
manage_ses_domain_identity = false
```

## Recursos criados

- Identidade SES do dominio e outputs de DKIM, quando `manage_ses_domain_identity=true`.
- Bucket S3 privado para armazenar e-mails brutos recebidos.
- Lifecycle para remover mensagens apos `inbound_email_retention_days`.
- Lambda Python sem dependencias externas para ler o `.eml` no S3 e encaminhar via SES.
- IAM role/policy minima para a Lambda.
- SES receipt rule set, receipt rule e ativacao opcional do rule set.
- Outputs com registros DNS necessarios.

## Pre-requisitos AWS

- Conta AWS com SES na regiao configurada em `aws_region`.
- Se `manage_ses_domain_identity=true`, publicar os CNAMEs de DKIM retornados por `ses_dkim_cname_records`.
- Se `manage_ses_domain_identity=false`, garantir que `royalsoftwareengineering.com.br` ja esta verificado no SES.
- SES fora de sandbox, ou pelo menos `marcobacelo90@gmail.com` verificado como destinatario enquanto estiver em sandbox.
- Nenhum outro SES receipt rule set ativo que precise continuar ativo na mesma regiao/conta. A AWS permite apenas um rule set ativo por regiao.

## DNS necessario no registro.br

Apos `terraform apply`, publique o output `ses_inbound_mx_record`:

```text
royalsoftwareengineering.com.br. MX 10 inbound-smtp.us-east-1.amazonaws.com
```

Se `manage_ses_domain_identity=true`, publique tambem todos os CNAMEs retornados por:

```bash
terraform output ses_dkim_cname_records
```

Tambem publique SPF e DMARC se ainda nao existirem:

```text
royalsoftwareengineering.com.br. TXT "v=spf1 include:amazonses.com ~all"
_dmarc.royalsoftwareengineering.com.br. TXT "v=DMARC1; p=none; rua=mailto:marcobacelo90@gmail.com"
```

Se outro provedor tambem enviar e-mails pelo dominio, nao crie um segundo SPF. Combine tudo em um unico TXT SPF.

## Execucao local

```bash
cd infra/email-forwarding
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use `terraform.tfvars.example` como base para um `terraform.tfvars` local nao versionado.

## GitHub Actions

O workflow `.github/workflows/terraform-email-forwarding.yml` executa `fmt`, `validate`, `plan` e, manualmente, `apply`.

Antes dele funcionar, execute localmente a stack `infra/bootstrap`.

Configure no GitHub:

### Repository variables

```text
AWS_REGION=us-east-1
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/rse-site-prod-email-forwarding-terraform
TF_STATE_BUCKET=<bucket-s3-do-terraform-state>
TF_STATE_KEY=royal-software-engineering-site/prod/email-forwarding/terraform.tfstate
CONTACT_FORWARD_TO_EMAIL=marcobacelo90@gmail.com
MANAGE_SES_DOMAIN_IDENTITY=true
```

### Repository secrets

Nenhum secret AWS e necessario se OIDC estiver configurado. Evite access keys long-lived.

## Validacao operacional

1. `terraform output ses_dkim_cname_records`, se esta stack gerencia a identidade SES.
2. Criar os CNAMEs DKIM no registro.br.
3. `terraform output ses_inbound_mx_record`.
4. Criar o MX no registro.br.
5. Aguardar propagacao DNS.
6. Confirmar no SES que a identidade ficou verificada.
7. Enviar um e-mail externo para `contato@royalsoftwareengineering.com.br`.
8. Confirmar objeto no bucket S3.
9. Confirmar recebimento em `marcobacelo90@gmail.com`.
10. Verificar logs da Lambda se nao chegar.

## Riscos e trade-offs

- Em conta que ja possui `royalsoftwareengineering.com.br` no SES por outro Terraform state, `manage_ses_domain_identity=true` gera conflito. Importe o recurso ou use `false`.
- Apontar o MX raiz para SES faz o dominio entregar e-mail para SES. Se no futuro existir Google Workspace/Microsoft 365/Zoho no mesmo dominio, o MX devera apontar para o provedor de mailbox, nao para SES.
- SES inbound nao fornece webmail, IMAP ou caixa postal. O acesso humano sera pelo Gmail de destino ou pelos `.eml` salvos no S3.
- Se a conta SES estiver em sandbox, o encaminhamento para Gmail pode falhar ate o destinatario ser verificado ou a conta sair da sandbox.
- A ativacao de `aws_ses_active_receipt_rule_set` substitui qualquer outro rule set ativo na regiao.
