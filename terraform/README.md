
# CloudSQL import/export (Setup with Terraform)

## Prerequisites

```sh
export TF_VAR_project_id="project-id"
export TF_VAR_access_token="$(gcloud auth print-access-token)"
export TF_VAR_user_email="$(gcloud config list account --format "value(core.account)")"
terraform init
```

## Setting up

```sh
terraform apply
```

## Tearing down

```sh
terraform destroy
```
