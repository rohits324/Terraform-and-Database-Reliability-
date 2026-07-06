-- =============================================================================
-- Migration 001 — Create Tables
-- =============================================================================
-- Tables:
--   hotel_bookings  — Core booking records
--   booking_events  — Audit/event log for bookings (JSONB payload)
--
-- Run order: PostgreSQL runs /docker-entrypoint-initdb.d/*.sql alphabetically,
--            so 001_ always runs before 002_.
-- =============================================================================

-- ─── hotel_bookings ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS hotel_bookings (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id        UUID          NOT NULL,
    hotel_id      VARCHAR(100)  NOT NULL,
    city          VARCHAR(100)  NOT NULL,
    checkin_date  DATE          NOT NULL,
    checkout_date DATE          NOT NULL,
    amount        NUMERIC(12,2) NOT NULL,
    status        VARCHAR(50)   NOT NULL,
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW(),

    -- Ensure checkout is after checkin
    CONSTRAINT chk_dates CHECK (checkout_date > checkin_date),
    -- Valid statuses
    CONSTRAINT chk_status CHECK (
        status IN ('confirmed', 'cancelled', 'pending', 'checked_in', 'checked_out')
    ),
    -- Amount must be positive
    CONSTRAINT chk_amount CHECK (amount > 0)
);

COMMENT ON TABLE hotel_bookings IS 'Core hotel booking records for all organisations';
COMMENT ON COLUMN hotel_bookings.org_id      IS 'Organisation that made the booking';
COMMENT ON COLUMN hotel_bookings.hotel_id    IS 'External hotel identifier';
COMMENT ON COLUMN hotel_bookings.status      IS 'confirmed|cancelled|pending|checked_in|checked_out';

-- ─── booking_events ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS booking_events (
    id         BIGSERIAL    PRIMARY KEY,
    booking_id UUID         NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    payload    JSONB,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE booking_events  IS 'Append-only event log for booking lifecycle changes';
COMMENT ON COLUMN booking_events.event_type IS 'e.g. booking_created, payment_received, checked_in, cancelled';
COMMENT ON COLUMN booking_events.payload    IS 'Arbitrary JSON context for the event';

-- ─── Indexes ──────────────────────────────────────────────────────────────────

-- PRIMARY optimisation index for the assignment query:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- Why (city, created_at DESC)?
--   1. Equality filter on city  → leftmost column reduces scan to one city's rows
--   2. Range filter on created_at → index range scan picks only last-30-day rows
--   3. DESC order matches "latest first" query patterns, avoids sort for ORDER BY created_at DESC
--   4. org_id and status are the GROUP BY columns but have low cardinality and are
--      NOT in the WHERE clause, so adding them to the index provides little benefit
--      at this data volume; the index already slashes 99%+ of irrelevant rows.
--
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at DESC);

-- Supporting index for org_id-based tenant queries (common SaaS access pattern)
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_org_id
    ON hotel_bookings (org_id);

-- Index on booking_events.booking_id for fast event lookups per booking
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id);

-- Index on booking_events.created_at for time-range event queries
CREATE INDEX IF NOT EXISTS idx_booking_events_created_at
    ON booking_events (created_at DESC);
