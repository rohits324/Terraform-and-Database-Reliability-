# Hotel Booking — AWS Infrastructure & Database Assignment

A complete solution demonstrating:
- **Terraform** infrastructure-as-code for AWS (ALB → ECS/Fargate → RDS)
- **Multi-environment** Terraform setup (dev / prod)
- **GitHub Actions** CI pipeline (fmt → init → validate → plan on PRs)
- **Docker Compose** local PostgreSQL database
- **Database migrations** with optimised indexing
- **Backup & restore** scripts

---

## Repository Structure

```
.
├── infra/
│   ├── modules/
│   │   ├── network/        # VPC, public + private subnets, IGW, NAT GW
│   │   ├── alb/            # Application Load Balancer, SG, listener
│   │   ├── ecs/            # ECS cluster, Fargate service, task def, IAM, SG
│   │   └── rds/            # RDS PostgreSQL, subnet group, private SG
│   └── envs/
│       ├── dev/            # Dev environment (small sizing, no deletion protection)
│       └── prod/           # Prod environment (HA, Multi-AZ, deletion protection)
├── .github/
│   └── workflows/
│       └── terraform.yml   # CI: fmt + init + validate + plan on Pull Requests
├── docker/
│   └── docker-compose.yml  # Local PostgreSQL 16
├── migrations/
│   ├── 001_create_tables.sql  # hotel_bookings + booking_events tables + indexes
│   └── 002_seed_data.sql      # 120 bookings, 52 events across 5 cities / 4 orgs
├── scripts/
│   ├── backup.sh           # Timestamped pg_dump (Docker or local)
│   └── restore.sh          # Drop → Create → Restore → Verify
└── README.md
```

---

## Part 1 & 2: Terraform Infrastructure

### Architecture

```
Internet
   │  HTTP :80
   ▼
┌──────────────────────────┐
│  ALB (public subnets)    │  ← SG: 0.0.0.0/0:80 inbound
└──────────┬───────────────┘
           │  forward
           ▼
┌──────────────────────────┐
│  ECS/Fargate             │  ← SG: ALB SG only, on container port
│  (private subnets)       │
└──────────┬───────────────┘
           │  TCP 5432
           ▼
┌──────────────────────────┐
│  RDS PostgreSQL          │  ← SG: ECS SG only, port 5432
│  (private subnets)       │    publicly_accessible = false
└──────────────────────────┘
```

### Environment Differences

| Setting                  | dev                    | prod                      |
|--------------------------|------------------------|---------------------------|
| RDS instance class       | `db.t3.micro`          | `db.t3.medium`            |
| RDS storage              | 20 GB                  | 100 GB + autoscale 200 GB |
| Backup retention         | **1 day**              | **7 days**                |
| Multi-AZ                 | `false`                | `true`                    |
| Deletion protection      | `false`                | `true`                    |
| Final snapshot on delete | skipped                | always created            |
| NAT Gateway              | disabled (cost saving) | enabled (2 × AZ)          |
| ECS desired count        | 1                      | 2                         |
| Container CPU / memory   | 256 / 512              | 512 / 1024                |
| Performance Insights     | disabled               | enabled                   |
| Terraform state key      | `dev/terraform.tfstate`| `prod/terraform.tfstate`  |

### Running Terraform Locally

```bash
# ── Dev ──────────────────────────────────────────────────────────────────────
cd infra/envs/dev

terraform fmt -check -recursive ../../   # check formatting
terraform init -backend=false             # init (no real S3 backend needed)
terraform validate                        # syntax + consistency check
terraform plan -refresh=false             # preview what would be created

# ── Prod ─────────────────────────────────────────────────────────────────────
cd infra/envs/prod
terraform init -backend=false
terraform validate
terraform plan -refresh=false
```

> **Note:** `db_password` defaults to the value in `terraform.tfvars`.
> In a real deployment, use `TF_VAR_db_password` or AWS Secrets Manager.

### Remote State (Optional — for real deployments)

Uncomment and fill in the `backend "s3"` block in `infra/envs/<env>/backend.tf`.
Bootstrap the S3 bucket and DynamoDB lock table once:

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

The workflow in [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml)
triggers on every **Pull Request** targeting `main` or `master`.

### Jobs

| Job | Steps |
|-----|-------|
| `fmt` | `terraform fmt -check -recursive infra/` — fails on any formatting issue |
| `terraform-dev` | init → validate → plan for `infra/envs/dev` |
| `terraform-prod` | init → validate → plan for `infra/envs/prod` |

### PR Comment Output

The plan for each environment is automatically posted as a **collapsible PR comment** and also uploaded as a **workflow artifact** (retained 7 days).

To use with real AWS credentials, add repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## Part 4: Local Database Setup

**Prerequisites:** Docker Desktop running

```bash
cd docker
docker compose up -d
```

This starts PostgreSQL 16 on port `5432`. The `migrations/` directory is mounted as
`/docker-entrypoint-initdb.d/` — PostgreSQL auto-runs all `.sql` files alphabetically
on the **first** container start.

### Connection details

| Setting  | Value           |
|----------|-----------------|
| Host     | `localhost`     |
| Port     | `5432`          |
| Database | `hotel_booking` |
| User     | `appuser`       |
| Password | `localpassword` |

```bash
# Connect via psql
docker exec -it hotel_booking_db psql -U appuser -d hotel_booking

# Or with pgAdmin (runs separately)
docker compose --profile tools up -d   # starts pgAdmin at http://localhost:5050
```

### Verify tables exist

```sql
\dt                        -- list all tables
SELECT COUNT(*) FROM hotel_bookings;   -- should return 120
SELECT COUNT(*) FROM booking_events;  -- should return 52
```

---

## Part 5: Seed Data & Index Optimisation

### Seed data summary

| Dimension       | Values                                                      |
|-----------------|-------------------------------------------------------------|
| Cities          | delhi, mumbai, bangalore, chennai, hyderabad                |
| Organisations   | 4 (org1–org4, fixed UUIDs)                                  |
| Statuses        | confirmed, cancelled, pending, checked_in, checked_out      |
| Bookings        | **120 rows** (27 in delhi within last 30 days)              |
| Events          | **52 rows** — booking_created, payment_received, checked_in, checked_out, booking_cancelled, status_updated, reminder_sent |

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

The query has **two filter predicates** — an equality on `city` and a range on `created_at`:

1. **`city` as the leftmost column** — PostgreSQL uses the equality predicate to jump directly to the B-tree leaf pages for `'delhi'`, eliminating all other cities without scanning them.

2. **`created_at DESC` as the second column** — within the `'delhi'` subtree, PostgreSQL performs an index range scan for `created_at >= NOW() - INTERVAL '30 days'`, reading only the last 30 days worth of pages rather than all Delhi rows.

3. **`org_id` and `status` are not in the index** — they appear only in `GROUP BY`, not in `WHERE`. Adding them would increase index maintenance cost and size without helping filter selectivity, since the index already reduces the scanned rows by 99%+ before the hash aggregate runs.

**Without the index:** PostgreSQL does a full sequential scan of all 120 rows and filters in memory.
**With the index:** PostgreSQL reads only the matching leaf pages (~27 rows for Delhi/last-30-days), then hashes them by `(org_id, status)`.

Additional supporting indexes (also in `001_create_tables.sql`):
- `idx_hotel_bookings_org_id` — fast per-tenant queries
- `idx_booking_events_booking_id` — fast event lookups per booking
- `idx_booking_events_created_at` — time-range event queries

### Verify the index is being used

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

## Part 6: Backup & Restore

### Backup

```bash
./scripts/backup.sh
```

Creates a file like `backups/backup_20240705_143022.sql`.

The script auto-detects whether to use the Docker container or a local `pg_dump`.

### Restore

```bash
./scripts/restore.sh backups/backup_20240705_143022.sql
```

The restore script:
1. Terminates all connections to the target database
2. **Drops** `hotel_booking_restored` (if it exists)
3. **Creates** a fresh empty `hotel_booking_restored` database
4. **Restores** all tables, indexes, data from the backup file
5. **Verifies** by printing row counts for both tables

To restore into the **original** database name:

```bash
./scripts/restore.sh backups/backup_20240705_143022.sql -d hotel_booking
```

### Verify the restore worked

After restore completes, the script automatically prints:

```
✅ Restore completed successfully
  Restored DB       : hotel_booking_restored
  hotel_bookings    : 120 rows
  booking_events    : 52 rows
```

You can also verify manually:

```bash
# Connect to the restored database
docker exec -it hotel_booking_db psql -U appuser -d hotel_booking_restored

# Check row counts
SELECT COUNT(*) FROM hotel_bookings;   -- expect 120
SELECT COUNT(*) FROM booking_events;  -- expect 52

# Run the optimisation query against restored data
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status
ORDER BY org_id, status;

# Verify indexes were restored
\di hotel_bookings*
```

---

## Full Submission Checklist

| Item | Location |
|------|----------|
| ✅ Terraform infrastructure code | `infra/modules/` |
| ✅ Dev environment | `infra/envs/dev/` |
| ✅ Prod environment | `infra/envs/prod/` |
| ✅ Docker Compose database setup | `docker/docker-compose.yml` |
| ✅ SQL migration files | `migrations/001_create_tables.sql` |
| ✅ Seed data script | `migrations/002_seed_data.sql` |
| ✅ Database backup script | `scripts/backup.sh` |
| ✅ Database restore script | `scripts/restore.sh` |
| ✅ GitHub Actions CI | `.github/workflows/terraform.yml` |
| ✅ README with setup & verification | `README.md` |

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
cd docker && docker compose up -d

# Wait for healthy (postgres:16 initialises in ~5s)
docker compose ps

# Backup
cd .. && ./scripts/backup.sh

# Restore (into hotel_booking_restored)
./scripts/restore.sh backups/backup_<timestamp>.sql
```
