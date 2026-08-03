name: eks-from-terragrunt
description: "Use when creating, preparing, deploying, deleting, or troubleshooting an EKS cluster from a Terragrunt deployment file in this repo. Resolve account context from the matching locals-env.hcl when available, otherwise ask for the target account and an optional terragrunt.hcl path, update main with a fast-forward pull, create and track a branch from main before making deployment changes, ensure the required EKS and monitoring locals are set correctly, handle optional OpenSearch enablement, verify workflow trigger patterns before choosing a branch name or relying on PR events, run plan, merge when the branch plan succeeds, trigger apply only from main, monitor until success, troubleshoot failures until resolved or blocked, and delete the local branch after a successful create or delete apply."
---

# EKS From Terragrunt

Use this skill for the Cognitech Terraform network repo when the task is to prepare, deploy, delete, monitor, or troubleshoot an EKS cluster driven by a deployment Terragrunt file.

## Inputs

Collect these inputs first:
- Optional absolute Terragrunt path, for example `C:\Users\Owner\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\Terraform\deployments\int-production\Tenant-account\prod\primary\terragrunt.hcl`.
- Whether OpenSearch logging should also be enabled for this deployment.
- Whether the requested operation is EKS `create` or EKS `delete`.

For `create` requests, resolve the account variables from the deployment's nearest `locals-env.hcl` before asking the user for them.

- For the example path above, read `C:\Users\Owner\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\Terraform\deployments\int-production\locals-env.hcl`.
- Use that file to gather the environment account context, especially:
	- `name_abr`
	- `eks_roles`
	- `eks_cluster_keys`
- Treat `name_abr` as the target account identifier when the user did not provide one separately.
- If the Terragrunt path is provided and the matching `locals-env.hcl` exists, do not ask the user for the target account identifier unless the file is missing the needed values.
- If the path is not provided, or the matching `locals-env.hcl` is missing or incomplete, ask the minimum follow-up needed.

If the path is not provided, resolve it from the account details by locating the matching deployment under `Terraform/deployments/<tier>/<account-type>/<environment>/<region>/terragrunt.hcl`.

If the account name alone is ambiguous, ask the minimum follow-up needed to identify one deployment path:
- account tier
- account type
- environment folder
- region context

When deriving from `locals-env.hcl`, prefer the values in that file over inferred account metadata from folder names.

## Target file rules

- Prefer the user-provided Terragrunt path when it exists.
- Stop and ask if the resolved path does not exist.
- Only modify the deployment `terragrunt.hcl` file that controls the target EKS cluster.
- Work in the `locals` block under `## eks related variables` when updating the booleans.

## Operation modes

Support two modes:

- `create`: prepare and deploy the EKS cluster.
- `delete`: reverse the EKS enablement changes and destroy the cluster through the normal workflow.

For `create`, follow the enablement rules below.

Before editing for `create`, read the nearest `locals-env.hcl`, then complete the git workflow to pull `main` and create the working branch before modifying the deployment file. Carry forward the discovered account context in the working summary so later plan, PR, and approval updates can refer to the resolved account identifier and cluster key.

For `delete`, reverse those same flags:
- `create_eks_cluster = false`
- `create_node_group = false`
- `create_service_accounts = false`
- `enable_eks_pia = false`
- `create_rbac = false`
- `create_namespaces = false`
- `enable_karpenter = false`
- `create_opensearch = false`
- `create_firehose = false`
- `enable_cloudwatch_observability = true`
- `enable_kube_prometheus_stack = false`

For delete mode:
- Preserve the same file structure and comments.
- Only reverse the locals that this workflow manages.
- Do not delete unrelated configuration blocks unless the user explicitly asks.

## Required EKS locals

The following locals must exist and be set to `true`:

```hcl
create_eks_cluster      = true
create_node_group       = true
create_service_accounts = true
enable_eks_pia          = true
create_rbac             = true
create_namespaces       = true
enable_karpenter        = true
enable_kube_prometheus_stack = true
```

Apply these rules:
- If any of the locals already exist with `false`, change them to `true`.
- If any of the locals are missing, add them inside the `## eks related variables` block.
- Preserve spacing and surrounding comments.

The following monitoring local must also be present:

```hcl
enable_cloudwatch_observability = true
```

Apply these rules:
- If OpenSearch is not being enabled, `enable_cloudwatch_observability` must be `true`.
- If OpenSearch is being enabled, set `enable_cloudwatch_observability = false` to match the inline comment guidance in the Terragrunt file.
- If the local is missing, add it in the existing `## eks monitoring` block.

## Optional OpenSearch logging

Ask the user whether they want OpenSearch enabled.

- If the answer is `yes`, set both of these locals to `true` in the `## eks monitoring` block:

```hcl
create_opensearch = true
create_firehose   = true
```

- When the answer is `yes`, also set:

```hcl
enable_cloudwatch_observability = false
```

- If either local is missing, add it in the existing monitoring block.
- If the answer is `no`, leave `create_opensearch` and `create_firehose` unchanged and ensure `enable_cloudwatch_observability = true`.
- Do not automatically change `enable_fluent_bit`; only report if the current combination looks inconsistent with the comment guidance.

## Git workflow

Before making any Terragrunt changes for `create` or `delete`, prepare a branch from `main`.

1. Check the worktree state first.
2. If unrelated local changes would block switching branches or pulling, stop and ask the user how to proceed. Do not reset or discard changes.
3. If the worktree is in a safe state, update `main` with a fast-forward pull.
4. Create a new branch from `main` before making any EKS-related file changes.
5. Make the Terragrunt changes on that new branch.

Preferred command sequence:

```powershell
git status --short
git checkout main
git pull --ff-only origin main
git checkout -b <generated-branch-name>
```

Branch naming guidance:
- Generate a random branch suffix for uniqueness.
- Base the branch name on the target deployment plus that random suffix.
- Inspect the target workflow trigger before choosing the branch format.
- If the workflow uses `push.branches: [main, "*"]`, avoid `/` in branch names because `*` does not match slash-delimited names.
- Prefer a slashless pattern like `eks-int-production-tenant-prod-primary-<random-suffix>` for this repo.
- Use a short lowercase alphanumeric suffix, for example 6 to 8 characters.
- If the branch name would be too long, shorten repeated deployment parts before shortening the random suffix.

Branch tracking rules:
- Record the branch name in the working summary and use it consistently for all later status updates.
- Report the branch name to the user after branch creation.
- If a pull request is created, include the branch name and PR link or identifier in subsequent updates.
- Do not edit the target `terragrunt.hcl` until the branch has been created successfully.

## Deployment execution

After the Terragrunt file changes are validated, continue through the deployment workflow instead of stopping at file prep when the user wants the cluster created or deleted.

1. Commit the deployment changes on the new branch.
2. Push the branch.
3. Push the branch and confirm the branch `plan` workflow run starts.
4. Open or update the pull request for review and merge tracking.
5. If this repo applies only from `main`, merge only after the branch `plan` succeeds.
6. After merge, monitor the `main` plan run triggered by the merge commit.
7. Trigger `apply` only from `main`, preferably with GitHub CLI when available.
8. Keep monitoring workflow progress until the apply stage succeeds or fails.

Apply rules:
- Do not stop after `plan` if the user asked for full cluster creation.
- In this repo, branch pushes trigger `plan`, but `apply` is limited to `workflow_dispatch` on `main`.
- Do not assume the PR itself triggers plan; verify the push-triggered workflow run for the branch.
- Do not require an explicit reviewer count unless branch protection or repo policy actually blocks the merge.
- After the branch plan succeeds, merge to `main`, allow a short review window when the user wants one, then monitor the new `main` plan run.
- If GitHub CLI is available, trigger apply with the repo's normal workflow path, for example `gh workflow run deploy-primary-int-production-prod.yaml --ref main -f terragrunt_action=apply`.
- Keep checking branch, PR, and workflow state until a terminal success or failure state is reached, and report the current branch, PR identifier, workflow run identifier, and whether the run is waiting on approval, running, succeeded, or failed.

For `delete` mode, use the same branch, PR, plan, approval, and apply flow, but treat success as confirmed destruction of the EKS-managed resources represented by these locals.

## Branch cleanup

After a successful create apply or successful delete apply:

1. Confirm the final workflow completed successfully.
2. Confirm the branch is no longer needed for additional fixes.
3. Delete the local branch that was created for this workflow.

Rules:
- Only delete the local branch after the create or delete apply has succeeded.
- Do not delete the branch if the workflow is still running, failed, awaiting approval, or still needed for follow-up fixes.
- Do not delete remote branches unless the user explicitly asks.
- Report to the user that the local branch was deleted.

## Failure handling

If the workflow fails, keep troubleshooting locally and iteratively until either the failure is fixed or a real blocker remains.

Follow this loop:
1. Capture the exact failing job, step, and error message.
2. Identify whether the failure comes from Terragrunt formatting, validation, plan, apply, missing variables, permissions, or a runtime dependency.
3. Make the smallest targeted fix in the owning Terragrunt or workflow file.
4. Re-run the narrowest validation available.
5. Re-run the plan or apply workflow as appropriate.
6. Continue until success or until the remaining blocker requires information or permissions the agent cannot supply.

When blocked, notify the user with:
- the exact failing step
- the current branch name
- the concrete error
- the next missing input, permission, or approval needed

Do not claim success until the apply stage has completed successfully.

## Validation

After editing the Terragrunt file, run the narrowest validation available:
- Run `terragrunt hclfmt` from the repo root, or use the existing workspace task for Terragrunt HCL formatting.
- Re-check the target file to confirm the required EKS locals are set to `true`, `enable_kube_prometheus_stack = true`, and `enable_cloudwatch_observability` matches the OpenSearch choice.
- Summarize exactly which flags changed and report the new branch name.
- If deployment is in scope, continue monitoring until apply succeeds or a concrete blocker is identified.

For delete mode validation:
- Re-check the target file to confirm the managed EKS locals have been reversed to their delete-state values.
- Continue monitoring until destroy apply succeeds or a concrete blocker is identified.

## Guardrails

- Do not modify shared Terraform formation code unless the user explicitly asks.
- Do not invent account metadata, IAM role ARNs, secrets, or cluster names.
- When `locals-env.hcl` is available, source account metadata from that file instead of asking the user to restate it.
- Do not run deployment commands unless the user asked for full cluster creation or deletion beyond file preparation.
- Do not discard user changes to make the branch workflow easier.
- Do not delete any branch before the corresponding create or delete apply has succeeded.