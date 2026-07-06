#!/usr/bin/env bash
# =============================================================================
# scripts/backup.sh — Create a timestamped PostgreSQL dump
#
# Usage:
#   ./scripts/backup.sh [OPTIONS]
#
# Options:
#   -h HOST     DB host      (default: localhost)
#   -p PORT     DB port      (default: 5432)
#   -U USER     DB user      (default: appuser)
#   -d DB       DB name      (default: hotel_booking)
#   -o DIR      Output dir   (default: ./backups)
#
# Examples:
#   ./scripts/backup.sh
#   ./scripts/backup.sh -d hotel_booking -o /tmp/backups
#
# The backup file is named:  backup_YYYYMMDD_HHMMSS.sql
# =============================================================================

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-appuser}"
DB_NAME="${DB_NAME:-hotel_booking}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# ─── Parse CLI flags ─────────────────────────────────────────────────────────
while getopts "h:p:U:d:o:" opt; do
  case $opt in
    h) DB_HOST="$OPTARG"   ;;
    p) DB_PORT="$OPTARG"   ;;
    U) DB_USER="$OPTARG"   ;;
    d) DB_NAME="$OPTARG"   ;;
    o) BACKUP_DIR="$OPTARG";;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# ─── Timestamp & filename ─────────────────────────────────────────────────────
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

# ─── Ensure output directory exists ──────────────────────────────────────────
mkdir -p "$BACKUP_DIR"

echo "=================================================="
echo "  Hotel Booking DB — Backup"
echo "=================================================="
echo "  Host      : ${DB_HOST}:${DB_PORT}"
echo "  Database  : ${DB_NAME}"
echo "  User      : ${DB_USER}"
echo "  Output    : ${BACKUP_FILE}"
echo "--------------------------------------------------"

# ─── Detect whether to use Docker or a local pg_dump ─────────────────────────
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^hotel_booking_db$'; then
  echo "  Mode      : Docker (container: hotel_booking_db)"
  echo "--------------------------------------------------"

  # Run pg_dump inside the running container
  docker exec hotel_booking_db \
    pg_dump \
      --username="$DB_USER" \
      --dbname="$DB_NAME" \
      --no-password \
      --format=plain \
      --no-owner \
      --no-privileges \
      --verbose \
    > "$BACKUP_FILE"

elif command -v pg_dump &>/dev/null; then
  echo "  Mode      : Local pg_dump"
  echo "--------------------------------------------------"

  PGPASSWORD="${DB_PASSWORD:-localpassword}" \
  pg_dump \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$DB_USER" \
    --dbname="$DB_NAME" \
    --no-password \
    --format=plain \
    --no-owner \
    --no-privileges \
    --verbose \
    > "$BACKUP_FILE"

else
  echo "ERROR: Neither Docker container 'hotel_booking_db' is running" >&2
  echo "       nor is pg_dump available locally." >&2
  echo "       Start the database with: cd docker && docker compose up -d" >&2
  exit 1
fi

# ─── Verify backup is non-empty ──────────────────────────────────────────────
if [[ ! -s "$BACKUP_FILE" ]]; then
  echo "ERROR: Backup file is empty — something went wrong." >&2
  rm -f "$BACKUP_FILE"
  exit 1
fi

BACKUP_SIZE="$(du -h "$BACKUP_FILE" | cut -f1)"
echo "   Backup completed successfully"

