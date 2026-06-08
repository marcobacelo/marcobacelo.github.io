# Checklist de setup

Use este checklist antes do primeiro `terraform apply`.

## 1. Bootstrap AWS

- [ ] Executar `infra/bootstrap` localmente com uma identidade AWS administrativa.
- [ ] Confirmar output `aws_role_to_assume`.
- [ ] Confirmar output `terraform_state_bucket`.
- [ ] Configurar repository variables no GitHub.

## 2. SES

- [ ] Definir se esta stack vai gerenciar a identidade SES (`MANAGE_SES_DOMAIN_IDENTITY=true`) ou se ela sera importada/desativada.
- [ ] Se a identidade SES ja existir em outro state, importar antes do apply ou usar `MANAGE_SES_DOMAIN_IDENTITY=false`.
- [ ] Confirmar que a conta SES esta fora de sandbox.
- [ ] Se ainda estiver em sandbox, verificar `marcobacelo90@gmail.com` como destinatario no SES.

## 3. Repository variables

Configure em GitHub -> Settings -> Secrets and variables -> Actions -> Variables:

```text
AWS_REGION=us-east-1
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/rse-site-prod-email-forwarding-terraform
TF_STATE_BUCKET=<bucket-s3-do-terraform-state>
TF_STATE_KEY=royal-software-engineering-site/prod/email-forwarding/terraform.tfstate
CONTACT_FORWARD_TO_EMAIL=marcobacelo90@gmail.com
MANAGE_SES_DOMAIN_IDENTITY=true
```

## 4. Primeiro deploy

- [ ] Abrir o workflow `Terraform Email Forwarding`.
- [ ] Executar `workflow_dispatch` com `action=plan`.
- [ ] Revisar recursos planejados.
- [ ] Executar `workflow_dispatch` com `action=apply`.
- [ ] Copiar o output `ses_dkim_cname_records`, se a stack gerencia a identidade SES.
- [ ] Criar os CNAMEs DKIM no registro.br.
- [ ] Copiar o output `ses_inbound_mx_record`.
- [ ] Criar o MX no registro.br.
- [ ] Criar/ajustar SPF e DMARC, se ainda nao existirem.
- [ ] Enviar e-mail de teste para `contato@royalsoftwareengineering.com.br`.
- [ ] Confirmar recebimento em `marcobacelo90@gmail.com`.

## 5. Decisao futura

Se o dominio passar a usar Google Workspace, Microsoft 365, Zoho, Proton ou outro mailbox real, nao mantenha o MX raiz apontando para SES. Nesse caso, mova o recebimento humano para o provedor de mailbox e use SES apenas para envio transacional ou para um subdominio dedicado.
