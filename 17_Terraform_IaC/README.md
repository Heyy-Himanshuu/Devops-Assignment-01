# Session 18: Terraform & Infrastructure as Code

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

This session has two parts. The first takes an S3 bucket through the whole Terraform lifecycle, from `init` to `destroy`, and checks every step against the API with the `aws` CLI. The second is a study of five core AWS services (IAM, EC2, S3, VPC, and DynamoDB/RDS), each with a small hands-on demo.

> **No real AWS account was used.** The AWS API is emulated by **[LocalStack](https://github.com/localstack/localstack) 4.9.2 (community edition)** running in Docker on `localhost:4566`. Terraform and the `aws` CLI send the same requests they would send to AWS, and LocalStack answers them. Each document says where the emulator falls short of real AWS. That covers IAM/bucket-policy enforcement, RDS, real VMs and two S3 tagging bugs.

Every screenshot is the real terminal output of the command shown in it. Nothing is mocked or typed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) (`session18-terraform-iac`).

---

## Contents

| # | Deliverable | What it demonstrates |
| --- | --- | --- |
| 1 | [**Terraform S3 Demo**](./terraform-s3-demo/README.md) | `init` → `fmt` → `validate` → `plan` → `apply` → `show` → `output` → `state` → `destroy` on a versioned, encrypted, private bucket. Also catches real drift (tags lost on create), traces it to an emulator gap with `TF_LOG=DEBUG`, and reconciles it. |
| 2 | [**IAM: Governance**](./aws-services/01-iam/README.md) | Users, groups, roles, policies, permission evaluation, least privilege and best practices. Demo: group + least-privilege policy + an EC2 role assumed through STS. |
| 3 | [**EC2: Compute**](./aws-services/02-ec2/README.md) | AMIs, instance types, key pairs, security groups, EBS, public vs private IP, and the lifecycle. Demo: the public IP changes across stop/start while the private IP stays. |
| 4 | [**S3: Storage**](./aws-services/03-s3/README.md) | Buckets, objects, storage classes, versioning, lifecycle, encryption and bucket policies. Demo: undeleting a file by removing its delete marker. |
| 5 | [**VPC: Networking**](./aws-services/04-vpc/README.md) | CIDR, subnets, route tables, IGW, NAT, SGs, NACLs, public vs private. Demo: one route-table line is the whole difference between public and private. |
| 6 | [**DynamoDB & RDS: Databases**](./aws-services/05-dynamodb-rds/README.md) | Partition and sort keys, items and attributes. RDS engines, Multi-AZ vs read replicas, backups and security. Demo: a sort-key range query. |

---

## Layout

```
17_Terraform_IaC/
├── README.md                 <- this index
├── .gitignore                <- .terraform/, *.tfstate*, *.tfplan
├── terraform-s3-demo/
│   ├── main.tf  variables.tf  outputs.tf  provider.tf  terraform.tfvars
│   ├── .terraform.lock.hcl
│   ├── README.md             <- full workflow write-up
│   └── screenshots/
└── aws-services/
    ├── 01-iam/           README.md, policy JSON, screenshots/
    ├── 02-ec2/           README.md, screenshots/
    ├── 03-s3/            README.md, lifecycle + bucket policy JSON, screenshots/
    ├── 04-vpc/           README.md, screenshots/
    └── 05-dynamodb-rds/  README.md, screenshots/
```

## Reproducing

```bash
docker run -d --name localstack -p 4566:4566 localstack/localstack:4.9   # :latest now needs an auth token
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null   # never touch ~/.aws

cd terraform-s3-demo
terraform init && terraform plan -out=s3.tfplan && terraform apply s3.tfplan
terraform destroy -auto-approve
```

## What LocalStack could not do

| Gap | Where it shows up |
| --- | --- |
| `:latest` image needs an auth token since 2026; pinned to `4.9` | All labs |
| Ignores tags sent inside `CreateBucket` (AWS provider v6 sends them there) → drift on the next plan | [S3 demo, step 9](./terraform-s3-demo/README.md#9-drift-plan-notices-the-missing-tags) |
| Keeps a deleted bucket's tags and hands them to a new bucket with the same name | Same section |
| Does not evaluate IAM policies (`simulate-principal-policy` → always `explicitDeny`) | [IAM, step 3](./aws-services/01-iam/README.md#3-policy-simulation-the-emulators-limit) |
| Stores bucket policies but does not enforce them | [S3, step 4](./aws-services/03-s3/README.md#4-default-sse-kms-encryption-and-a-bucket-policy) |
| EC2 instances are API records, not running VMs | [EC2](./aws-services/02-ec2/README.md#hands-on-localstack) |
| RDS is not in the community edition | [DynamoDB & RDS, step 5](./aws-services/05-dynamodb-rds/README.md#5-rds-not-emulated-in-localstack-community) |
