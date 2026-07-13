# wapaExchange — AWS Infrastructure

Terraform configuration for the production stack in **eu-west-3 (Paris)** — chosen for EU data residency and proximity to French banking partners.

## Layout

```
infrastructure/terraform/
├── modules/
│   ├── network/    # VPC, subnets (2 private + 1 public), NAT, SGs
│   ├── database/   # RDS Postgres 16 + automated backups
│   ├── cache/      # ElastiCache Redis 7 (single-node MVP, Multi-AZ later)
│   ├── storage/    # S3 bucket for KYC docs (SSE-KMS, versioned, no public)
│   └── ecs/        # Fargate cluster + API service + worker service + ALB
└── envs/
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── terraform.tfvars.example
        └── backend.tf   # remote state in S3 + DynamoDB lock
```

## Bootstrap (one-time)

```bash
# Create the S3 bucket + DynamoDB table that hold remote state.
aws s3api create-bucket --bucket wapa-tfstate-prod --region eu-west-3 \
    --create-bucket-configuration LocationConstraint=eu-west-3
aws s3api put-bucket-versioning --bucket wapa-tfstate-prod \
    --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name wapa-tfstate-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST --region eu-west-3
```

## Deploy

```bash
cd envs/prod
cp terraform.tfvars.example terraform.tfvars   # fill secrets
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## What this costs (eu-west-3, monthly)

| Resource | Size | €/mo |
|---|---|---|
| RDS Postgres | `db.t4g.small` Multi-AZ | ~75 |
| ElastiCache Redis | `cache.t4g.micro` single-node | ~15 |
| ECS Fargate (API) | 2 × 0.5 vCPU / 1 GB | ~30 |
| ECS Fargate (worker) | 1 × 0.25 vCPU / 0.5 GB | ~8 |
| ALB | 1 | ~20 |
| NAT Gateway | 1 (single-AZ) | ~35 |
| S3 + KMS | < 50 GB | ~5 |
| CloudWatch + Secrets | | ~15 |
| **Total** | | **~200 / mo** |

Swap NAT Gateway for a **VPC Endpoint** for S3 once spend matters — saves ~€30.

## Production hardening checklist

- [ ] Move Redis to Multi-AZ once revenue justifies (~€30/mo extra).
- [ ] Add a second NAT in a second AZ (~€35/mo extra) for AZ-failure resilience.
- [ ] Switch RDS from `gp3` to `io1` once p99 query latency matters.
- [ ] Enable RDS Performance Insights (free for 7 days retention).
- [ ] Add WAF in front of ALB once you have abuse (~€10/mo + per-request).
- [ ] Restrict the SSH bastion to your VPN CIDR; we leave 0.0.0.0/0 disabled by default.
