# Design Notes — Wallet Backend Infrastructure

This covers the reasoning behind the architecture in `architecture.drawio` and the Terraform in `/terraform`.

## Region

I picked **eu-west-1 (Ireland)** over af-south-1 (Cape Town), which looks like the obvious choice for a Nigerian product. Two reasons: af-south-1 still lags on service availability and runs noticeably more expensive across most services, and real-world latency from Lagos to Ireland is comparable to Lagos–Cape Town because so much West African traffic routes through Europe anyway. If latency testing later says otherwise, nothing in this design is region-specific, so moving is a Terraform variable change.

## Network layout

One VPC (`10.0.0.0/16`) across two AZs, with three subnet tiers per AZ:

- **Public subnets** hold only the ALB and NAT gateways. Nothing with application logic gets a public IP.
- **Private app subnets** run the ECS tasks. Outbound internet (payment provider APIs, KYC vendors) goes through NAT.
- **Private data subnets** hold RDS and have **no route to the internet at all**. The DB is only reachable from the app tier's security group on 5432.

Security groups are chained rather than CIDR-based: internet → ALB (443) → app tasks (8080, source = ALB SG) → RDS (5432, source = app SG). VPC endpoints for ECR, Secrets Manager, and CloudWatch Logs keep that traffic off the NAT path — this is both a security win (traffic never leaves AWS) and a cost win (NAT data processing charges add up fast with container image pulls).

## Compute: ECS on Fargate

I went with ECS Fargate over EKS and plain EC2:

- **vs EKS**: Kubernetes buys flexibility we don't need yet and charges for it in ops burden (cluster upgrades, node management, add-on lifecycle) plus ~$73/month per cluster before a single pod runs. For one backend API owned by a small team, that's overhead without payoff. If we grow into service mesh / multi-team territory, containers built for ECS move to EKS without rework.
- **vs EC2**: patching, AMI hygiene, and capacity management are undifferentiated work. Fargate removes the host layer entirely, which also shrinks the compliance surface — relevant for a fintech that will face audits.

The service runs minimum 2 tasks spread across AZs behind the ALB, with target-tracking auto scaling on CPU and request count per target. Deployments are rolling with the ALB health check as the gate, and a circuit breaker rolls back automatically on failed deploys.

## Database

**RDS PostgreSQL, Multi-AZ**, encrypted at rest with a customer-managed KMS key. Postgres because wallet/ledger work is exactly what a relational store with real transactions is for — double-entry balances need ACID, not eventual consistency.

Backups: automated daily snapshots with **30-day retention plus point-in-time recovery** (5-minute granularity via transaction logs). Deletion protection on, final snapshot required. For real production I'd add AWS Backup with a vault in a second region — a wallet losing its ledger is an existential event, so backup copies shouldn't share a blast radius with the primary.

## Secrets and data protection

- **No secrets in code, task definitions, or CI variables.** DB credentials live in Secrets Manager with automatic rotation; the ECS task definition references the secret ARN and the container gets the value injected at start. The task execution role is the only principal that can read it.
- Two IAM roles per service, deliberately separate: the **execution role** (pull image, fetch secrets, write logs) and the **task role** (what the app itself may touch — its S3 prefix, nothing more). Both scoped to specific resource ARNs, no wildcards.
- **KYC documents** go to S3 with SSE-KMS, versioning, all public access blocked, and access only via the task role. Presigned URLs for user-facing upload/download so documents never proxy through the API unnecessarily.
- TLS everywhere: ACM cert on the ALB, `rds.force_ssl` on Postgres. WAF on the ALB with the AWS managed common rule set plus rate limiting on auth endpoints.
- CloudTrail + VPC Flow Logs on from day one — for NDPA compliance and any card-scheme audit, you want the audit trail to predate the incident.

## Cost awareness

The design has one deliberate dev/prod split: **one NAT gateway in dev, one per AZ in prod** (a NAT GW is ~$32/month each before data charges — fine to save in dev, not worth the AZ-failure coupling in prod). Fargate tasks are sized small (0.25 vCPU / 512MB) and scale out rather than running big idle tasks. RDS starts on a burstable instance class. Biggest future levers: Fargate Spot for non-critical workers, Compute Savings Plans once usage stabilizes, and watching NAT data processing (the classic surprise line item — hence the VPC endpoints).

## What I'd add for real production

Multi-region DR posture for the database, a bastion-less access path (SSM Session Manager only), ECR image scanning gating deploys, structured audit logging for all money movement, GuardDuty + Security Hub, and per-environment Terraform state with locking in S3/DynamoDB and CI-driven plans.
