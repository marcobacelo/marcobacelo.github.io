# Bootstrap AWS

Esta stack prepara a conta AWS para a pipeline Terraform do repo institucional.

Ela cria:

- Bucket S3 remoto para Terraform state.
- Provider OIDC do GitHub, quando `create_github_oidc_provider=true`.
- Role IAM `rse-prod-gha-terraform` assumida pelo GitHub Actions.
- Policy minima para a role aplicar a stack `infra/email-forwarding`.

## Execucao local

Esta stack precisa ser executada localmente com uma identidade AWS administrativa. Ela nao roda pelo GitHub Actions porque cria justamente a role que o GitHub Actions vai assumir.

```bash
cd infra/bootstrap
cp -n terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Depois configure no GitHub as repository variables retornadas pelos outputs:

```bash
terraform output github_repository_variables
```

Valores esperados apos a padronizacao:

```text
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/rse-prod-gha-terraform
TF_STATE_BUCKET=rse-prod-tfstate-<account-id>
TF_STATE_KEY=rse/prod/email-forwarding/terraform.tfstate
```

## Conta AWS que ja possui OIDC

O provider OIDC `token.actions.githubusercontent.com` e unico por conta AWS. Se ele ja existir, configure:

```hcl
create_github_oidc_provider = false
```

## Limite

Esta stack nao cria a identidade SES do dominio. Isso fica na stack principal `infra/email-forwarding`.
