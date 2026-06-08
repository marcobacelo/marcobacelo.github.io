# Checklist de setup

Use este checklist antes do primeiro `terraform apply`.

## 1. AWS

- [ ] Confirmar a conta AWS correta.
- [ ] Confirmar regiao `us-east-1`, ou outra regiao suportada por SES receiving.
- [ ] Confirmar que `royalsoftwareengineering.com.br` esta verificado no SES na mesma regiao.
- [ ] Confirmar que DKIM do dominio esta publicado no DNS.
- [ ] Confirmar que a conta SES esta fora de sandbox.
- [ ] Se ainda estiver em sandbox, verificar `marcobacelo90@gmail.com` como destinatario no SES.

## 2. Terraform state

- [ ] Criar ou escolher um bucket S3 para state remoto.
- [ ] Garantir versionamento e criptografia no bucket de state.
- [ ] Definir a key: `royal-software-engineering-site/prod/email-forwarding/terraform.tfstate`.
- [ ] Garantir permissao da role do GitHub Actions no bucket de state.

## 3. GitHub Actions OIDC

- [ ] Criar provider OIDC `token.actions.githubusercontent.com` na conta AWS, se ainda nao existir.
- [ ] Criar role IAM para o repo `marcobacelo/marcobacelo.github.io`.
- [ ] Configurar trust policy com `repo:marcobacelo/marcobacelo.github.io:*`.
- [ ] Anexar permissoes para S3 state, SES receipt rules, S3 inbound, Lambda, IAM PassRole e CloudWatch Logs.

## 4. Repository variables

Configure em GitHub -> Settings -> Secrets and variables -> Actions -> Variables:

```text
AWS_REGION=us-east-1
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/<role-oidc-do-repo>
TF_STATE_BUCKET=<bucket-s3-do-terraform-state>
TF_STATE_KEY=royal-software-engineering-site/prod/email-forwarding/terraform.tfstate
CONTACT_FORWARD_TO_EMAIL=marcobacelo90@gmail.com
```

## 5. Primeiro deploy

- [ ] Abrir o workflow `Terraform Email Forwarding`.
- [ ] Executar `workflow_dispatch` com `action=plan`.
- [ ] Revisar recursos planejados.
- [ ] Executar `workflow_dispatch` com `action=apply`.
- [ ] Copiar o output `ses_inbound_mx_record`.
- [ ] Criar o MX no registro.br.
- [ ] Criar/ajustar SPF e DMARC, se ainda nao existirem.
- [ ] Enviar e-mail de teste para `contato@royalsoftwareengineering.com.br`.
- [ ] Confirmar recebimento em `marcobacelo90@gmail.com`.

## 6. Decisao futura

Se o dominio passar a usar Google Workspace, Microsoft 365, Zoho, Proton ou outro mailbox real, nao mantenha o MX raiz apontando para SES. Nesse caso, mova o recebimento humano para o provedor de mailbox e use SES apenas para envio transacional ou para um subdominio dedicado.
