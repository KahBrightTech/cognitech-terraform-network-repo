---
mode: agent
tools: ['edit', 'search', 'runCommands', 'runTasks', 'terminal', 'problems']
description: Deploy or update an EKS cluster in the Cognitech Terraform network repo. Scaffolds the deployment folder and GitHub Actions workflow if they don't exist yet, wires up the `eks` block in terragrunt.hcl following this repo's conventions, and walks through running the terragrunt pipeline.
---

# Deploy EKS Cluster

Invoke with `/deploy-eks` when asked to deploy, create, or update an EKS cluster for an account/environment in this repo. This repo has no standalone "EKS module" folder — EKS clusters are entries in the `eks` variable inside a deployment's `terragrunt.hcl`, built by the shared `Deploy-eks` module.

## 1. Get the target coordinates

If not already given, ask for:
- Account tier: `int-preproduction` | `int-production` | `md-preproduction` | `md-production`
- Account type: `Tenant-account` | `Shared-account`
- Environment folder name: e.g. `dev`, `sit`, `uat`, `prod`, `Trn` (must match existing sibling folders under that account type)
- Region context: `primary` | `secondary`
- EKS cluster key/name, and whether this is a new cluster or an update to an existing one

## 2. Locate or scaffold the deployment folder

Target: `Terraform/deployments/<tier>/<account-type>/<environment>/<region-context>/terragrunt.hcl`

- If it exists, open it — the `eks` list variable lives near the bottom of `inputs`. Use `Terraform/deployments/int-production/Tenant-account/prod/primary/terragrunt.hcl` as the reference for the full schema.
- If it does **not** exist:
  1. Create the folder.
  2. Copy the nearest sibling environment's `terragrunt.hcl` under the same account type (e.g. an existing `dev` or `sit` folder) as the starting point rather than writing one from scratch.
  3. Update the environment-specific locals: `vpc_name`, `vpc_name_abr`, and anything under the `## Updates these variables as per the product/service` comment.
  4. Confirm the environment is already defined in the parent `locals-env.hcl` / `locals-cloud.hcl` (resolved via `find_in_parent_folders`). If it isn't, this is a full account-onboarding task — point the person to `Account-Creation-Runbook/README.md` instead of improvising new account metadata.

## 3. Add or update the `eks` block

Follow the existing schema exactly — don't invent a different shape or module. The formation-level module lives in `Terraform/formations/<account-type>/main.tf` as `module "eks"`, sourced from `git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Deploy-eks`.

An `eks` entry typically includes:
- `create_eks_cluster`, `create_node_group`, `create_service_accounts`, `enable_eks_pia`, `create_rbac`, `create_namespaces` — booleans, usually pulled from `local.*`
- `key` / `name` — the key comes from `include.env.locals.eks_cluster_keys.<name>` in `locals-env.hcl`; add a new key there first if this is a brand-new cluster
- `role_arn` — usually `dependency.platform.outputs.IAM_roles.shared-eks.iam_role_arn`
- `oidc_thumbprint` — `get_env("TF_VAR_EKS_CLUSTER_THUMPRINT")`
- `access_entries` — admin/readonly/audit principal ARNs from `include.env.locals.eks_roles`
- `auth`, `namespaces`, `subnet_keys`, `security_groups`, `security_group_rules`, `launch_templates`, `service_accounts`, `eks_pia`, `iam_roles` — copy the structure from an existing cluster block and adjust names/namespaces for this deployment

Never hand-roll IAM policy JSON inline in the `.hcl` — reference a file under `Terraform/deployments/iam_policies/`, creating a new one there (following the naming style of `eks-cluster-autoscaler-policy.json`) if a new policy is needed.

## 4. Locate or scaffold the GitHub Actions workflow

Target: `.github/workflows/deploy-primary-<tier>-<env-suffix>.yaml`

- If it exists, no changes are needed unless `DEPLOYMENT_PATH` or required secrets changed.
- If it does **not** exist, copy the closest existing workflow (e.g. `deploy-primary-int-production-prod.yaml`) and update:
  - `name`
  - `env.IAM_ROLE` — the OIDC role ARN for the target account
  - `env.DEPLOYMENT_PATH` — the folder from step 2
  - the `paths:` filter under the `push` trigger
  - any new `TF_VAR_*` secrets the new `eks` block needs (e.g. for a new IAM policy)

## 5. Run the pipeline

This repo deploys through GitHub Actions (`terragrunt run-all plan/apply`), not local `terraform apply` directly:
1. Commit the `terragrunt.hcl` / workflow changes and push.
2. Trigger the workflow via `workflow_dispatch` with `terragrunt_action: plan` first and review the plan summary in the job output.
3. Re-run with `terragrunt_action: apply` — production workflows gate `apply` behind an `Approve` job/environment, so it will wait for manual approval.
4. If Terraform/Terragrunt are installed locally, run `terragrunt validate` and `terragrunt plan` from the deployment folder before pushing, to catch errors early.

## Guardrails

- Don't modify `Terraform/formations/**` or the remote `Deploy-eks` module source — those are shared across every account.
- Don't commit real secrets, thumbprints, or account IDs — those flow in via GitHub Actions secrets (`TF_VAR_*`) referenced through `get_env(...)`.
- If a CIDR range, account ID, or IAM role ARN would have to be guessed, stop and ask rather than inventing a value.
