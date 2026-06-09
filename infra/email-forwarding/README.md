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

## Ownership

O repo `marcobacelo.github.io` e o owner da identidade SES `royalsoftwareengineering.com.br`, dos registros DKIM/MX e do forwarding institucional.

Projetos consumidores, como a Whiskeria, nao devem criar a identidade SES. Eles devem apenas usar `email_provider=ses`, `email_from=noreply@royalsoftwareengineering.com.br` e permissao runtime `ses:SendEmail`/`ses:SendRawEmail`.

Se a identidade SES `royalsoftwareengineering.com.br` ja existir na mesma conta/regiao e estiver gerenciada por outro Terraform state, o primeiro `apply` vai falhar com conflito de recurso existente. Nesse caso, escolha uma das opcoes:

1. Importar a identidade para esta stack:

```bash
terraform import 'aws_sesv2_email_identity.domain[0]' royalsoftwareengineering.com.br
```

2. Ou manter a identidade fora desta stack e configurar:

```hcl
manage_ses_domain_identity = false
```

## Migracao da Whiskeria para este repo

Quando a identidade SES ainda estiver no state da Whiskeria:

1. Aplicar a infra da Whiskeria com o `removed` block `destroy=false`, para remover a identidade do state sem destruir o recurso AWS.
2. Neste repo, importar a identidade existente:

```bash
cd infra/email-forwarding
terraform import 'aws_sesv2_email_identity.domain[0]' royalsoftwareengineering.com.br
```

3. Rodar `terraform plan` e confirmar que a identidade SES nao sera recriada nem destruida.

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

## Migracao de nomes `rse-prod-*`

Os nomes fisicos foram padronizados para `rse-prod-*`. Em uma conta que ja possui recursos antigos (`rse-site-*` ou `royal-software-engineering-site-*`), nao execute `apply` sem revisar o `plan`.

Antes de aplicar:

1. Migrar ou copiar o state remoto para `TF_STATE_BUCKET=rse-prod-tfstate-<account-id>` e `TF_STATE_KEY=rse/prod/email-forwarding/terraform.tfstate`, se a mudanca de bucket/key for adotada.
2. Rodar `terraform plan` e identificar replacements de bucket, Lambda, IAM role e SES receipt rule set.
3. Para recursos com dados, como bucket S3 de e-mails recebidos, decidir se as mensagens antigas serao copiadas ou mantidas em bucket legado por uma janela de retencao.
4. Aplicar primeiro o bootstrap, atualizar GitHub variables, e so entao aplicar a stack de email.

Na migracao executada em 2026-06-09, os recursos antigos foram recriados com nomes `rse-prod-*` apos backup dos buckets. O bucket inbound antigo e o bucket de state antigo foram removidos depois da validacao.

## GitHub Actions

O workflow `.github/workflows/terraform-email-forwarding.yml` executa `fmt`, `validate`, `plan` e, manualmente, `apply`.

Antes dele funcionar, execute localmente a stack `infra/bootstrap`.

Configure no GitHub:

### Repository variables

```text
AWS_REGION=us-east-1
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/rse-prod-gha-terraform
TF_STATE_BUCKET=<bucket-s3-do-terraform-state>
TF_STATE_KEY=rse/prod/email-forwarding/terraform.tfstate
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

## Estado atual de DNS, nomes e testes

Validacao em 2026-06-08 e migracao final em 2026-06-09:

- DKIM da identidade SES `royalsoftwareengineering.com.br` esta verificado.
- `marcobacelo90@gmail.com` esta verificado no SES, o que permite teste enquanto a conta ainda esta em sandbox.
- GitHub Pages do dominio raiz esta resolvendo para os quatro IPs oficiais do GitHub Pages.
- `www.royalsoftwareengineering.com.br` esta resolvendo para `marcobacelo.github.io`.
- DNS de email publicado no Registro.br:

```text
royalsoftwareengineering.com.br. MX 10 inbound-smtp.us-east-1.amazonaws.com
royalsoftwareengineering.com.br. TXT "v=spf1 include:amazonses.com ~all"
_dmarc.royalsoftwareengineering.com.br. TXT "v=DMARC1; p=none; rua=mailto:marcobacelo90@gmail.com"
```

- Recursos ativos:
  - State: `s3://rse-prod-tfstate-058495187765/rse/prod/email-forwarding/terraform.tfstate`
  - Bucket inbound: `rse-prod-email-inbound-058495187765`
  - Lambda/IAM role: `rse-prod-email-forwarder`
  - SES rule set: `rse-prod-email-inbound`
  - SES receipt rule: `rse-prod-contact-forward`
- Recursos legados removidos apos backup:
  - `rse-site-tf-state-058495187765`
  - `royal-software-engineering-site-prod-inbound-email-058495187765`
  - `rse-site-prod-email-forwarding-terraform`
  - `royal-software-engineering-site-prod-forward-contact-email`
- Backups de migracao preservados em:
  - `s3://rse-prod-tfstate-058495187765/backups/royal-software-engineering-site-prod-inbound-email-058495187765/20260609T120624Z/`
  - `s3://rse-prod-tfstate-058495187765/backups/rse-site-tf-state-058495187765/20260609T120624Z/`
- Smoke final aprovado:
  - `MessageId=0100019eac4baab6-a2b4c2b7-cb4f-4734-818c-1dc28dedf6e2-000000`
  - Objeto S3 `contact/s411ftle7dhkv1ppertuvj2tee9304sj5hsell01`
  - Log stream Lambda `2026/06/09/[$LATEST]bbac22718e614d2d97585609b515da1a` sem `ERROR`.

## Riscos e trade-offs

- Em conta que ja possui `royalsoftwareengineering.com.br` no SES por outro Terraform state, `manage_ses_domain_identity=true` gera conflito. Importe o recurso ou use `false`.
- Apontar o MX raiz para SES faz o dominio entregar e-mail para SES. Se no futuro existir Google Workspace/Microsoft 365/Zoho no mesmo dominio, o MX devera apontar para o provedor de mailbox, nao para SES.
- SES inbound nao fornece webmail, IMAP ou caixa postal. O acesso humano sera pelo Gmail de destino ou pelos `.eml` salvos no S3.
- Se a conta SES estiver em sandbox, o encaminhamento para Gmail pode falhar ate o destinatario ser verificado ou a conta sair da sandbox.
- A ativacao de `aws_ses_active_receipt_rule_set` substitui qualquer outro rule set ativo na regiao.
