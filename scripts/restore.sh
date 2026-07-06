#!/usr/bin/env bash
# =============================================================================
# scripts/restore.sh — Restore a PostgreSQL backup into a fresh database
#
# Usage:
#   ./scripts/restore.sh <backup_file> [OPTIONS]
#
# Options:
#   -h HOST     DB host      (default: localhost)
#   -p PORT     DB port      (default: 5432)
#   -U USER     DB superuser (default: appuser)
#   -d DB       Target DB    (default: hotel_booking_restored)
#
# Examples:
#   ./scripts/restore.sh backups/backup_20240705_143022.sql
#   ./scripts/restore.sh backups/backup_20240705_143022.sql -d hotel_booking
#
# What this script does:
#   1. Drops the target database if it exists (clean slate)
#   2. Creates a fresh empty database
#   3. Restores all objects and data from the backup file
#   4. Runs verification queries to confirm success
# =============================================================================

set -euo pipefail

# ─── Validate argument ────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <backup_file> [-h host] [-p port] [-U user] [-d dbname]" >&2
  echo "Example: $0 backups/backup_20240705_143022.sql" >&2
  exit 1
fi

BACKUP_FILE="$1"
shift  # remove first arg so getopts can process the rest

# ─── Defaults ────────────────────────────────────────────────────────────────
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-appuser}"
RESTORE_DB="${RESTORE_DB:-hotel_booking_restored}"

# ─── Parse CLI flags ─────────────────────────────────────────────────────────
while getopts "h:p:U:d:" opt; do
  case $opt in
    h) DB_HOST="$OPTARG"   ;;
    p) DB_PORT="$OPTARG"   ;;
    U) DB_USER="$OPTARG"   ;;
    d) RESTORE_DB="$OPTARG";;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# ─── Check backup file exists ─────────────────────────────────────────────────
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERROR: Backup file not found: ${BACKUP_FILE}" >&2
  exit 1
fi

BACKUP_SIZE="$(du -h "$BACKUP_FILE" | cut -f1)"

echo "=================================================="
echo "  Hotel Booking DB — Restore"
echo "=================================================="
echo "  Backup    : ${BACKUP_FILE} (${BACKUP_SIZE})"
echo "  Target DB : ${RESTORE_DB}"
echo "  Host      : ${DB_HOST}:${DB_PORT}"
echo "  User      : ${DB_USER}"
echo "--------------------------------------------------"
echo "  ⚠️  This will DROP and recreate database: ${RESTORE_DB}"
echo "     (source database is NOT affected)"
echo "--------------------------------------------------"

# ─── Detect Docker vs local psql ─────────────────────────────────────────────
USE_DOCKER=false
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^hotel_booking_db$'; then
  USE_DOCKER=true
  echo "  Mode      : Docker (container: hotel_booking_db)"
elif command -v psql &>/dev/null; then
  echo "  Mode      : Local psql"
else
  echo "ERROR: Neither Docker container 'hotel_booking_db' is running" >&2
  echo "       nor is psql available locally." >&2
  echo "       Start the database with: cd docker && docker compose up -d" >&2
  exit 1
fi
echo "--------------------------------------------------"

# ─── Helper: run psql command ─────────────────────────────────────────────────
run_psql() {
  local sql="$1"
  if [[ "$USE_DOCKER" == "true" ]]; then
    docker exec hotel_booking_db \
      psql --username="$DB_USER" --dbname=postgres --no-password \
           --command="$sql"
  else
    PGPASSWORD="${DB_PASSWORD:-localpassword}" \
    psql --host="$DB_HOST" --port="$DB_PORT" \
         --username="$DB_USER" --dbname=postgres --no-password \
         --command="$sql"
  fi
}

# ─── Helper: restore from file ───────────────────────────────────────────────
run_restore() {
  if [[ "$USE_DOCKER" == "true" ]]; then
    # Copy the backup file into the container, then psql from inside
    docker cp "$BACKUP_FILE" hotel_booking_db:/tmp/restore_input.sql
    docker exec hotel_booking_db \
      psql --username="$DB_USER" --dbname="$RESTORE_DB" --no-password \
           --file=/tmp/restore_input.sql \
           --echo-errors
    # Clean up temp file inside container
    docker exec hotel_booking_db rm -f /tmp/restore_input.sql
  else
    PGPASSWORD="${DB_PASSWORD:-localpassword}" \
    psql --host="$DB_HOST" --port="$DB_PORT" \
         --username="$DB_USER" --dbname="$RESTORE_DB" --no-password \
         --file="$BACKUP_FILE" \
         --echo-errors
  fi
}

# ─── Step 1: Drop target database if exists ───────────────────────────────────
echo ""
echo "[1/4] Dropping existing database '${RESTORE_DB}' (if exists)..."
run_psql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${RESTORE_DB}';" > /dev/null 2>&1 || true
run_psql "DROP DATABASE IF EXISTS \"${RESTORE_DB}\";"
echo "      ✅ Done"

# ─── Step 2: Create fresh database ───────────────────────────────────────────
echo "[2/4] Creating fresh database '${RESTORE_DB}'..."
run_psql "CREATE DATABASE \"${RESTORE_DB}\" OWNER \"${DB_USER}\";"
echo "      ✅ Done"

# ─── Step 3: Restore backup ───────────────────────────────────────────────────
echo "[3/4] Restoring backup into '${RESTORE_DB}'..."
run_restore
echo "      ✅ Done"

# ─── Step 4: Verify restore ───────────────────────────────────────────────────
echo "[4/4] Verifying restore..."

if [[ "$USE_DOCKER" == "true" ]]; then
  VERIFY_CMD="docker exec hotel_booking_db psql --username=$DB_USER --dbname=$RESTORE_DB --no-password --no-align --tuples-only"
else
  VERIFY_CMD="PGPASSWORD=${DB_PASSWORD:-localpassword} psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USER --dbname=$RESTORE_DB --no-password --no-align --tuples-only"
fi

BOOKING_COUNT=$(eval "$VERIFY_CMD" --command="SELECT COUNT(*) FROM hotel_bookings;" 2>/dev/null | tr -d ' ')
EVENT_COUNT=$(eval   "$VERIFY_CMD" --command="SELECT COUNT(*) FROM booking_events;"  2>/dev/null | tr -d ' ')

echo ""
echo "=================================================="
echo "  ✅ Restore completed successfully" 
echo "=================================================="
echo "  Restored DB       : ${RESTORE_DB}"
echo "  hotel_bookings    : ${BOOKING_COUNT} rows"
echo "  booking_events    : ${EVENT_COUNT} rows"
echo "=================================================="
echo ""
echo "  Connect to the restored database:"
echo "    docker exec -it hotel_booking_db psql -U ${DB_USER} -d ${RESTORE_DB}"
echo ""
echo "  Run the optimisation query to verify data:"
echo "    SELECT org_id, status, COUNT(*), SUM(amount)"
echo "    FROM hotel_bookings"
echo "    WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'"
echo "    GROUP BY org_id, status;"
echo ""
