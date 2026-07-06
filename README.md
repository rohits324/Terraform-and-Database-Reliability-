# Hotel Booking — AWS Infrastructure & Database Assignment

A complete solution demonstrating:
- **Terraform** infrastructure-as-code for AWS (Internet -> ALB -> ECS/Fargate -> RDS)
- **Multi-environment** Terraform (dev / prod) with separate sizing, state, and settings
- **GitHub Actions** CI pipeline (fmt -> init -> validate -> plan on PRs)
- **Docker Compose** local PostgreSQL database
- **Database migrations** with optimised indexing
- **Backup and restore** shell scripts

---

## Repository Structure

```
.
├── infra/
│   ├── modules/
│   │   ├── network/        # VPC, public + private subnets, IGW, NAT Gateway
│   │   ├── alb/            # Application Load Balancer, SG, HTTP listener
│   │   ├── ecs/            # ECS Fargate cluster, service, task def, IAM, SG
│   │   └── rds/            # RDS PostgreSQL, private subnet group, SG
│   └── envs/
│       ├── dev/            # dev: small sizing, 1-day backup, no deletion protection
│       └── prod/           # prod: HA, Multi-AZ, 7-day backup, deletion protection
├── .github/
│   └── workflows/
│       └── terraform.yml   # CI: fmt + init + validate + plan on Pull Requests
├── docker/
│   └── docker-compose.yml  # Local PostgreSQL 16
├── migrations/
│   ├── 001_create_tables.sql   # hotel_bookings + booking_events tables + indexes
│   └── 002_seed_data.sql       # 120 bookings, 52 events, 5 cities, 4 orgs
├── scripts/
│   ├── backup.sh           # Timestamped pg_dump (Docker-aware)
│   └── restore.sh          # Drop -> Create -> Restore -> Verify
└── README.md
```

---

## Part 1 & 2: Terraform Infrastructure

### Architecture

```
Internet
   |  HTTP :80
   v
+---------------------------+
|  ALB  (public subnets)    |  SG: 0.0.0.0/0:80 inbound only
+------------+--------------+
             |  forward
             v
+---------------------------+
|  ECS / Fargate            |  SG: ALB SG inbound only
|  (private subnets)        |
+------------+--------------+
             |  TCP 5432
             v
+---------------------------+
|  RDS PostgreSQL           |  SG: ECS SG inbound on 5432 only
|  (private subnets)        |  publicly_accessible = false
+---------------------------+
```

### Environment Differences

| Setting                  | dev                     | prod                       |
|--------------------------|-------------------------|----------------------------|
| RDS instance class       | `db.t3.micro`           | `db.t3.medium`             |
| RDS storage              | 20 GB                   | 100 GB + autoscale 200 GB  |
| Backup retention         | 1 day                   | 7 days                     |
| Multi-AZ                 | false                   | true                       |
| Deletion protection      | false                   | true                       |
| Final snapshot on delete | skipped                 | always created             |
| NAT Gateway              | disabled (cost saving)  | enabled (2 AZs)            |
| ECS desired count        | 1                       | 2                          |
| Terraform state key      | `dev/terraform.tfstate` | `prod/terraform.tfstate`   |

### Running Terraform Locally

```bash
# Dev environment
cd infra/envs/dev
terraform fmt -check -recursive ../../   # check formatting
terraform init -backend=false            # init without remote state
terraform validate                       # syntax and consistency check
terraform plan -refresh=false            # preview all resources

# Prod environment
cd infra/envs/prod
terraform init -backend=false
terraform validate
terraform plan -refresh=false
```

> **Note:** `db_password` is in `terraform.tfvars` for local plan review only.
> In a real deployment use `TF_VAR_db_password` or AWS Secrets Manager.

### Remote State (for real deployments)

Uncomment the `backend "s3"` block in `infra/envs/<env>/backend.tf` and bootstrap:

```bash
aws s3api create-bucket --bucket your-tf-state-bucket --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## Part 3: GitHub Actions CI

Workflow file: `.github/workflows/terraform.yml`

Triggers on every **Pull Request** to `main` that changes files under `infra/`.

### Jobs

| Job | Steps |
|-----|-------|
| `fmt` | `terraform fmt -check -recursive infra/` |
| `terraform-dev` | init -> validate -> plan for `infra/envs/dev` |
| `terraform-prod` | init -> validate -> plan for `infra/envs/prod` |

The plan output for each environment is posted as a **collapsible PR comment** and
uploaded as a **workflow artifact** (retained 7 days).

To use real AWS credentials add repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Without secrets the workflow uses placeholder credentials and still runs
`terraform plan -refresh=false` successfully (no state refresh needed).

---

## Part 4: Local Database Setup

**Prerequisites:** Docker Desktop running

```bash
cd docker
docker compose up -d
```

PostgreSQL 16 starts on port `5432`. The `migrations/` folder is mounted as
`/docker-entrypoint-initdb.d/` — all `.sql` files run automatically in alphabetical
order on the first container start.

### Connection details

| Setting  | Value           |
|----------|-----------------|
| Host     | `localhost`     |
| Port     | `5432`          |
| Database | `hotel_booking` |
| User     | `appuser`       |
| Password | `localpassword` |

```bash
# Connect via psql inside the container
docker exec -it hotel_booking_db psql -U appuser -d hotel_booking

# Optional pgAdmin web UI at http://localhost:5050
docker compose --profile tools up -d
```

### Verify tables exist

```sql
\dt
SELECT COUNT(*) FROM hotel_bookings;   -- expected: 120
SELECT COUNT(*) FROM booking_events;  -- expected: 52
```

---

## Part 5: Seed Data and Index Optimisation

### Seed data summary

| Dimension     | Values                                                         |
|---------------|----------------------------------------------------------------|
| Cities        | delhi, mumbai, bangalore, chennai, hyderabad                   |
| Organisations | 4 (fixed UUIDs: org1-org4)                                     |
| Statuses      | confirmed, cancelled, pending, checked_in, checked_out         |
| Bookings      | 120 rows (27 in delhi within last 30 days)                     |
| Events        | 52 rows covering full lifecycle                                |

### Optimisation Query

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

### Index Added

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at DESC);
```

### Why This Index?

The query has two filter predicates: an equality on `city` and a range on `created_at`.

**`city` as the leftmost column** eliminates all non-delhi rows at the B-tree
root level before touching any leaf pages.

**`created_at DESC` as the second column** performs an index range scan within
the delhi subtree, reading only the last-30-days pages instead of all delhi rows.

**`org_id` and `status` are not in the index** because they appear only in
`GROUP BY`, not in `WHERE`. They have low filter selectivity and adding them
would increase index maintenance cost with minimal benefit — the index already
reduces scanned rows by 99%+ before the hash aggregate runs.

Without the index: full sequential scan of all 120 rows.
With the index: reads only matching leaf pages (~27 rows).

Additional supporting indexes (also in `001_create_tables.sql`):
- `idx_hotel_bookings_org_id` — fast per-tenant queries
- `idx_booking_events_booking_id` — fast event lookups per booking
- `idx_booking_events_created_at` — time-range event queries

### Verify the index is used

```sql
EXPLAIN ANALYZE
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Look for `Index Scan using idx_hotel_bookings_city_created_at` in the output.

---

## Part 6: Backup and Restore

### Backup

```bash
./scripts/backup.sh
```

Creates a timestamped file: `backups/backup_YYYYMMDD_HHMMSS.sql`

The script auto-detects whether to use the running Docker container or a local
`pg_dump` binary.

### Restore

```bash
./scripts/restore.sh backups/backup_YYYYMMDD_HHMMSS.sql
```

The restore script:
1. Terminates all existing connections to the target database
2. Drops `hotel_booking_restored` (if it exists)
3. Creates a fresh empty `hotel_booking_restored` database
4. Restores all tables, indexes, and data from the backup file
5. Prints row counts to verify the restore succeeded

### Verify the restore worked

The script automatically prints on completion:

```
Restore completed successfully
  Restored DB       : hotel_booking_restored
  hotel_bookings    : 120 rows
  booking_events    : 52 rows
```

Verify manually inside the restored database:

```bash
docker exec -it hotel_booking_db psql -U appuser -d hotel_booking_restored
```

```sql
-- Check row counts match the original
SELECT COUNT(*) FROM hotel_bookings;   -- expect 120
SELECT COUNT(*) FROM booking_events;  -- expect 52

-- Run the optimisation query on restored data
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status
ORDER BY org_id, status;

-- Verify indexes were restored
\di hotel_bookings*
```

To restore into the original database name instead:

```bash
./scripts/restore.sh backups/backup_YYYYMMDD_HHMMSS.sql -d hotel_booking
```

---

## Reviewer Commands

### Terraform

```bash
# Dev
cd infra/envs/dev
terraform fmt -check -recursive ../../
terraform init -backend=false
terraform validate
terraform plan -refresh=false

# Prod
cd ../prod
terraform init -backend=false
terraform validate
terraform plan -refresh=false
```

### Database

```bash
# Start local database (runs migrations + seed data automatically)
cd docker && docker compose up -d

# Wait ~5 seconds for postgres to initialise, then verify
docker exec hotel_booking_db psql -U appuser -d hotel_booking \
  -c "SELECT COUNT(*) FROM hotel_bookings;"

# Backup
cd .. && ./scripts/backup.sh

# Restore
./scripts/restore.sh backups/backup_<timestamp>.sql

# Connect and verify manually
docker exec -it hotel_booking_db psql -U appuser -d hotel_booking_restored
```

---

## Submission Checklist

| Item | Location | Status |
|------|----------|--------|
| Terraform infrastructure code | `infra/modules/` | Done |
| dev Terraform environment | `infra/envs/dev/` | Done |
| prod Terraform environment | `infra/envs/prod/` | Done |
| Docker Compose database setup | `docker/docker-compose.yml` | Done |
| SQL migration files | `migrations/001_create_tables.sql` | Done |
| Seed data script | `migrations/002_seed_data.sql` | Done |
| Database backup script | `scripts/backup.sh` | Done |
| Database restore script | `scripts/restore.sh` | Done |
| README with setup and verification | `README.md` | Done |
| GitHub Actions CI | `.github/workflows/terraform.yml` | Done |
