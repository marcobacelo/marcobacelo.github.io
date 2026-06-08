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

Esta infra nao cria a identidade SES do dominio porque ela ja existe no projeto da Whiskeria para `noreply@royalsoftwareengineering.com.br`. O dominio precisa estar verificado no SES na mesma conta/regiao usada aqui.

## Recursos criados

- Bucket S3 privado para armazenar e-mails brutos recebidos.
- Lifecycle para remover mensagens apos `inbound_email_retention_days`.
- Lambda Python sem dependencias externas para ler o `.eml` no S3 e encaminhar via SES.
- IAM role/policy minima para a Lambda.
- SES receipt rule set, receipt rule e ativacao opcional do rule set.
- Outputs com registros DNS necessarios.

## Pre-requisitos AWS

- Conta AWS com SES na regiao configurada em `aws_region`.
- Dominio `royalsoftwareengineering.com.br` verificado no SES.
- DKIM publicado no DNS conforme output da infra que criou a identidade SES.
- SES fora de sandbox, ou pelo menos `marcobacelo90@gmail.com` verificado como destinatario enquanto estiver em sandbox.
- Nenhum outro SES receipt rule set ativo que precise continuar ativo na mesma regiao/conta. A AWS permite apenas um rule set ativo por regiao.

## DNS necessario no registro.br

Apos `terraform apply`, publique o output `ses_inbound_mx_record`:

```text
royalsoftwareengineering.com.br. MX 10 inbound-smtp.us-east-1.amazonaws.com
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

Configure no GitHub:

### Repository variables

```text
AWS_REGION=us-east-1
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/<role-oidc-do-repo>
TF_STATE_BUCKET=<bucket-s3-do-terraform-state>
TF_STATE_KEY=royal-software-engineering-site/prod/email-forwarding/terraform.tfstate
CONTACT_FORWARD_TO_EMAIL=marcobacelo90@gmail.com
```

### Repository secrets

Nenhum secret AWS e necessario se OIDC estiver configurado. Evite access keys long-lived.

## Bootstrap OIDC

Crie uma role IAM confiando no repo `marcobacelo/marcobacelo.github.io` e permita `sts:AssumeRoleWithWebIdentity`.

Trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:marcobacelo/marcobacelo.github.io:*"
        }
      }
    }
  ]
}
```

Permissoes necessarias para essa role:

- Backend Terraform: `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket`.
- SES: gerenciar receipt rule set/rules e enviar e-mails de teste via SES se necessario.
- S3: criar e gerenciar o bucket de inbound email.
- Lambda: criar/atualizar/remover a funcao.
- IAM: criar/atualizar/remover role/policy da Lambda e `iam:PassRole`.
- CloudWatch Logs: criar/gerenciar log group da Lambda.

## Validacao operacional

1. `terraform output ses_inbound_mx_record`.
2. Criar o MX no registro.br.
3. Aguardar propagacao DNS.
4. Enviar um e-mail externo para `contato@royalsoftwareengineering.com.br`.
5. Confirmar objeto no bucket S3.
6. Confirmar recebimento em `marcobacelo90@gmail.com`.
7. Verificar logs da Lambda se nao chegar.

## Riscos e trade-offs

- Apontar o MX raiz para SES faz o dominio entregar e-mail para SES. Se no futuro existir Google Workspace/Microsoft 365/Zoho no mesmo dominio, o MX devera apontar para o provedor de mailbox, nao para SES.
- SES inbound nao fornece webmail, IMAP ou caixa postal. O acesso humano sera pelo Gmail de destino ou pelos `.eml` salvos no S3.
- Se a conta SES estiver em sandbox, o encaminhamento para Gmail pode falhar ate o destinatario ser verificado ou a conta sair da sandbox.
- A ativacao de `aws_ses_active_receipt_rule_set` substitui qualquer outro rule set ativo na regiao.
