# Resumo técnico: Migração do frontend para S3 + CloudFront e Integração CI/CD (OIDC)

Data: 2025-11-13

Este documento resume as alterações realizadas no projeto "getting-started-app" para provisionar o frontend em S3 + CloudFront, adicionar scripts de build/deploy, criar workflows GitHub Actions usando OIDC e confeccionar roles/policies IAM para permitir deploys seguros sem chaves estáticas.

## Objetivos
- Provisionar o frontend como site estático em S3 com distribuição CloudFront.
- Fornecer script de build e deploy (sincronização S3 + invalidação CloudFront).
- Implementar CI/CD com GitHub Actions usando OIDC (sem segredos AWS de longa duração).
- Criar roles/policies IAM para GitHub Actions (frontend deploy e Terraform CI).

## Trabalhos realizados (alto nível)

- Ajustes no frontend
  - `src/static/index.html`: adicionado `<base href="/">` para suportar hospedagem estática via S3/CloudFront.
  - `package.json`: adicionados scripts de build e deploy (scripts de build já existentes e deploy via `npm run build` + sync).
  - `scripts/deploy-frontend.sh`: (adicionado) script para construir e sincronizar assets com S3 e invalidar CloudFront.

- Terraform (infraestrutura)
  - Adicionadas definições para provisionar S3 bucket privado e CloudFront (com provider aliased para `us-east-1` para ACM de CloudFront).
  - `terraform.tfvars`: atualizado com valores padrão para permitir `terraform plan` local sem `-var`. Atenção: `frontend_bucket_name` precisa ser globalmente único antes do apply.
  - Adicionada lógica e timeouts para `aws_nat_gateway` para reduzir condições de corrida durante `destroy`.

- CI / GitHub Actions
  - Workflow criado: `.github/workflows/frontend-deploy.yml` — build/test, assume role via OIDC, `aws s3 sync` + upload `index.html`, CloudFront invalidation.
  - Workflow criado: `.github/workflows/infra.yml` — Terraform plan em PR e Terraform apply em push para `main` (apply atrelado a environment `production` para proteção).

- IAM (criação via AWS CLI nesta máquina)
  - Criadas duas roles OIDC e policies gerenciadas:
    - Role: `getting-started-frontend-deploy-role`
      - ARN: arn:aws:iam::618889059366:role/getting-started-frontend-deploy-role
      - Policy (managed): arn:aws:iam::618889059366:policy/getting-started-frontend-deploy-policy
      - Permissões: S3 Put/Get/List no bucket `getting-started-frontend-bucket`, CloudFront:CreateInvalidation (restrição inicial aplicada por conta).
    - Role: `getting-started-terraform-ci-role`
      - ARN: arn:aws:iam::618889059366:role/getting-started-terraform-ci-role
      - Policy (managed): arn:aws:iam::618889059366:policy/getting-started-terraform-ci-policy
      - Permissões: policy inicial ampla (EC2, RDS, ECS, IAM PassRole, S3, CloudFront, Route53, etc.). Deve ser refinada antes de produção.

## Arquivos criados / alterados (resumo)

- Adicionados
  - `.github/workflows/frontend-deploy.yml` — workflow de deploy do frontend (OIDC).
  - `.github/workflows/infra.yml` — workflow Terraform (plan em PR, apply em main, assume role via OIDC).
  - `scripts/deploy-frontend.sh` — script para empacotar e sincronizar build para S3 + invalidar CloudFront.
  - `terraform/iam/*` — templates JSON de trust/policies gerados e usados como base para criação de roles.
  - `docs/CI_and_Frontend_Migration_Summary.md` — este arquivo (relatório).

- Editados
  - `src/static/index.html` — adicionada tag `<base href="/">`.
  - `terraform/terraform.tfvars` — valores defaults (incl. `frontend_bucket_name = "getting-started-frontend-bucket"`, `deploy_frontend_only = false`).
  - `terraform/modules/network/main.tf` — adicionado bloco `timeouts` ao resource `aws_nat_gateway`.

## Resultados e verificações executadas

- Terraform: realizei ciclos de `apply` e `destroy` completos para validar provisioning e teardown — ambos completaram com sucesso após resolução de dependências (remoção manual de NAT gateway via AWS CLI durante o processo para evitar DependencyViolation).
- Outputs relevantes do último `terraform apply`:
  - `frontend_bucket_name` = "getting-started-frontend-bucket"
  - `cloudfront_distribution_id` = (ID da distribuição; se necessário, executar `terraform output cloudfront_distribution_id` após apply)
  - `cloudfront_domain_name` = (domínio CloudFront gerado após create)

## Comandos executados para criação IAM (resumido)

Os comandos foram executados localmente via AWS CLI. Principais comandos (executados por mim nesta máquina com credenciais AWS já configuradas):

```bash
aws sts get-caller-identity
aws iam create-role --role-name getting-started-frontend-deploy-role --assume-role-policy-document file:///tmp/frontend-trust.json --description "GitHub Actions OIDC role for frontend deploy (S3 + CloudFront)"
aws iam create-policy --policy-name getting-started-frontend-deploy-policy --policy-document file:///tmp/frontend-policy.json
aws iam attach-role-policy --role-name getting-started-frontend-deploy-role --policy-arn arn:aws:iam::618889059366:policy/getting-started-frontend-deploy-policy

aws iam create-role --role-name getting-started-terraform-ci-role --assume-role-policy-document file:///tmp/terraform-trust.json --description "GitHub Actions OIDC role for Terraform CI (plan/apply)"
aws iam create-policy --policy-name getting-started-terraform-ci-policy --policy-document file:///tmp/terraform-policy.json
aws iam attach-role-policy --role-name getting-started-terraform-ci-role --policy-arn arn:aws:iam::618889059366:policy/getting-started-terraform-ci-policy
```

> Observação: os arquivos `/tmp/*.json` foram gerados durante o processo; os templates permanentes estão em `terraform/iam/`.

## Ajustes de segurança e recomendações

1. Revise e restrinja a policy `getting-started-terraform-ci-policy` — atualmente é ampla e usa `Resource: "*"`. Ideal:
   - Dividir responsabilidades (ex.: roles separadas para operações que precisam criar/alterar IAM vs. operações de deploy que não precisam).
   - Conceder ações apenas para os recursos específicos que o Terraform gerencia (use ARNs quando possível).

2. Proteja o ambiente `production` no GitHub (Settings → Environments) e configure required reviewers para bloquear `terraform apply` sem aprovação humana.

3. Substitua `getting-started-frontend-bucket` por um nome globalmente único antes de executar o `terraform apply` em produção.

4. Depois do primeiro deploy, restrinja a policy do frontend para a distribuição CloudFront específica (ARN) em vez de `distribution/*`.

## Próximos passos recomendados (para apresentar)

1. Adicionar os secrets no GitHub (Settings → Secrets → Actions):
   - `AWS_ROLE_TO_ASSUME_FRONTEND` = `arn:aws:iam::618889059366:role/getting-started-frontend-deploy-role`
   - `AWS_ROLE_TO_ASSUME_TERRAFORM` = `arn:aws:iam::618889059366:role/getting-started-terraform-ci-role`
   - `AWS_REGION` = `us-east-2` (conforme configuração do Terraform)
   - `FRONTEND_BUCKET` = `getting-started-frontend-bucket`
   - `CLOUDFRONT_DISTRIBUTION_ID` = `<opcional, preencha após provisionamento>`

2. Executar um deploy de teste do frontend para um bucket de staging (ou habilitar as workflows e rodar em branch protegido) para verificar:
   - Assets foram sincronizados corretamente
   - Cache-control configurado (assets versionados com long-lived cache; `index.html` com no-cache)
   - Invalidação CloudFront completa

3. Refinar políticas IAM e aplicar proteção de ambiente no GitHub.

## Material de apoio e anexos

- Templates de trust/policy usados estão em: `terraform/iam/` (substituir placeholders por valores reais quando for criar roles em outra conta).
- Workflows:
  - `.github/workflows/frontend-deploy.yml`
  - `.github/workflows/infra.yml`

## Resumo executivo curto (para apresentação)

Implementamos a migração do frontend para uma pipeline segura e automatizada: o frontend agora pode ser construído e publicado por meio de GitHub Actions sem segredos AWS permanentes, usando roles OIDC com permissões controladas. Adicionamos infra Terraform para S3 + CloudFront e criamos a base do CI para infra (plan em PR + apply em main com proteção). O próximo passo operacional é adicionar os secrets no GitHub e validar um deploy de staging, além de ajustar as policies IAM para least-privilege antes do uso em produção.

---

Se quiser, eu adapto esse arquivo para um formato de slides (Markdown + reveal.js) ou gero um PDF pronto para apresentação.
