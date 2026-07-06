-- =============================================================================
-- Migration 002 — Seed Data
-- =============================================================================
-- Inserts:
--   • 120 hotel_bookings across 5 cities, 4 orgs, 5 statuses
--   • 52  booking_events for a representative subset of bookings
--
-- Covers date range from 60 days ago to 10 days in the future so that the
-- optimisation query (last-30-days) always returns a meaningful result set.
-- =============================================================================

-- ─── Organisation UUIDs ──────────────────────────────────────────────────────
-- Using fixed UUIDs so results are reproducible and easy to reference.

DO $$
DECLARE
    org1  UUID := '11111111-0000-0000-0000-000000000001';
    org2  UUID := '22222222-0000-0000-0000-000000000002';
    org3  UUID := '33333333-0000-0000-0000-000000000003';
    org4  UUID := '44444444-0000-0000-0000-000000000004';
BEGIN

-- ─── hotel_bookings seed ─────────────────────────────────────────────────────

INSERT INTO hotel_bookings (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at) VALUES

-- ── Delhi — org1 (confirmed, 8 rows, within last 30 days) ───────────────────
('b0000001-0000-0000-0000-000000000001', org1, 'HTL-DEL-001', 'delhi', NOW()::date - 5,  NOW()::date - 2,  8500.00,  'confirmed',   NOW() - INTERVAL '3 days'),
('b0000001-0000-0000-0000-000000000002', org1, 'HTL-DEL-002', 'delhi', NOW()::date - 8,  NOW()::date - 5,  12000.00, 'confirmed',   NOW() - INTERVAL '6 days'),
('b0000001-0000-0000-0000-000000000003', org1, 'HTL-DEL-003', 'delhi', NOW()::date - 12, NOW()::date - 9,  9750.00,  'checked_out', NOW() - INTERVAL '10 days'),
('b0000001-0000-0000-0000-000000000004', org1, 'HTL-DEL-004', 'delhi', NOW()::date - 15, NOW()::date -12,  6200.00,  'cancelled',   NOW() - INTERVAL '13 days'),
('b0000001-0000-0000-0000-000000000005', org1, 'HTL-DEL-005', 'delhi', NOW()::date - 20, NOW()::date -17,  14500.00, 'confirmed',   NOW() - INTERVAL '18 days'),
('b0000001-0000-0000-0000-000000000006', org1, 'HTL-DEL-006', 'delhi', NOW()::date - 22, NOW()::date -20,  7800.00,  'checked_out', NOW() - INTERVAL '20 days'),
('b0000001-0000-0000-0000-000000000007', org1, 'HTL-DEL-001', 'delhi', NOW()::date - 25, NOW()::date -22,  11200.00, 'confirmed',   NOW() - INTERVAL '23 days'),
('b0000001-0000-0000-0000-000000000008', org1, 'HTL-DEL-002', 'delhi', NOW()::date - 28, NOW()::date -25,  5500.00,  'pending',     NOW() - INTERVAL '26 days'),

-- ── Delhi — org2 (mix of statuses, within last 30 days) ─────────────────────
('b0000002-0000-0000-0000-000000000001', org2, 'HTL-DEL-007', 'delhi', NOW()::date - 4,  NOW()::date - 1,  18000.00, 'checked_in',  NOW() - INTERVAL '2 days'),
('b0000002-0000-0000-0000-000000000002', org2, 'HTL-DEL-008', 'delhi', NOW()::date - 7,  NOW()::date - 4,  9300.00,  'confirmed',   NOW() - INTERVAL '5 days'),
('b0000002-0000-0000-0000-000000000003', org2, 'HTL-DEL-009', 'delhi', NOW()::date - 11, NOW()::date - 8,  13700.00, 'cancelled',   NOW() - INTERVAL '9 days'),
('b0000002-0000-0000-0000-000000000004', org2, 'HTL-DEL-010', 'delhi', NOW()::date - 14, NOW()::date -11,  7100.00,  'confirmed',   NOW() - INTERVAL '12 days'),
('b0000002-0000-0000-0000-000000000005', org2, 'HTL-DEL-007', 'delhi', NOW()::date - 19, NOW()::date -16,  22000.00, 'checked_out', NOW() - INTERVAL '17 days'),
('b0000002-0000-0000-0000-000000000006', org2, 'HTL-DEL-008', 'delhi', NOW()::date - 24, NOW()::date -21,  8900.00,  'confirmed',   NOW() - INTERVAL '22 days'),
('b0000002-0000-0000-0000-000000000007', org2, 'HTL-DEL-009', 'delhi', NOW()::date - 27, NOW()::date -24,  16400.00, 'pending',     NOW() - INTERVAL '25 days'),

-- ── Delhi — org3 (within last 30 days) ──────────────────────────────────────
('b0000003-0000-0000-0000-000000000001', org3, 'HTL-DEL-011', 'delhi', NOW()::date - 6,  NOW()::date - 3,  10500.00, 'confirmed',   NOW() - INTERVAL '4 days'),
('b0000003-0000-0000-0000-000000000002', org3, 'HTL-DEL-012', 'delhi', NOW()::date - 10, NOW()::date - 7,  8300.00,  'cancelled',   NOW() - INTERVAL '8 days'),
('b0000003-0000-0000-0000-000000000003', org3, 'HTL-DEL-013', 'delhi', NOW()::date - 16, NOW()::date -13,  19500.00, 'checked_out', NOW() - INTERVAL '14 days'),
('b0000003-0000-0000-0000-000000000004', org3, 'HTL-DEL-014', 'delhi', NOW()::date - 21, NOW()::date -18,  6700.00,  'confirmed',   NOW() - INTERVAL '19 days'),
('b0000003-0000-0000-0000-000000000005', org3, 'HTL-DEL-015', 'delhi', NOW()::date - 29, NOW()::date -26,  12800.00, 'pending',     NOW() - INTERVAL '27 days'),

-- ── Delhi — org4 (within last 30 days) ──────────────────────────────────────
('b0000004-0000-0000-0000-000000000001', org4, 'HTL-DEL-016', 'delhi', NOW()::date - 3,  NOW()::date - 1,  25000.00, 'checked_in',  NOW() - INTERVAL '1 day'),
('b0000004-0000-0000-0000-000000000002', org4, 'HTL-DEL-017', 'delhi', NOW()::date - 9,  NOW()::date - 6,  11100.00, 'confirmed',   NOW() - INTERVAL '7 days'),
('b0000004-0000-0000-0000-000000000003', org4, 'HTL-DEL-018', 'delhi', NOW()::date - 18, NOW()::date -15,  7600.00,  'cancelled',   NOW() - INTERVAL '16 days'),
('b0000004-0000-0000-0000-000000000004', org4, 'HTL-DEL-019', 'delhi', NOW()::date - 26, NOW()::date -23,  14200.00, 'checked_out', NOW() - INTERVAL '24 days'),

-- ── Delhi — older rows (> 30 days ago, should NOT appear in optimisation query)
('b0000005-0000-0000-0000-000000000001', org1, 'HTL-DEL-001', 'delhi', NOW()::date - 40, NOW()::date -37,  9000.00,  'checked_out', NOW() - INTERVAL '38 days'),
('b0000005-0000-0000-0000-000000000002', org2, 'HTL-DEL-002', 'delhi', NOW()::date - 50, NOW()::date -47,  11500.00, 'confirmed',   NOW() - INTERVAL '48 days'),
('b0000005-0000-0000-0000-000000000003', org3, 'HTL-DEL-003', 'delhi', NOW()::date - 60, NOW()::date -57,  7200.00,  'cancelled',   NOW() - INTERVAL '58 days'),

-- ── Mumbai — org1 ────────────────────────────────────────────────────────────
('b0000006-0000-0000-0000-000000000001', org1, 'HTL-MUM-001', 'mumbai', NOW()::date - 2,  NOW()::date + 1,  32000.00, 'checked_in',  NOW() - INTERVAL '1 day'),
('b0000006-0000-0000-0000-000000000002', org1, 'HTL-MUM-002', 'mumbai', NOW()::date - 6,  NOW()::date - 3,  19500.00, 'confirmed',   NOW() - INTERVAL '4 days'),
('b0000006-0000-0000-0000-000000000003', org1, 'HTL-MUM-003', 'mumbai', NOW()::date - 11, NOW()::date - 8,  14200.00, 'checked_out', NOW() - INTERVAL '9 days'),
('b0000006-0000-0000-0000-000000000004', org1, 'HTL-MUM-004', 'mumbai', NOW()::date - 15, NOW()::date -12,  8700.00,  'cancelled',   NOW() - INTERVAL '13 days'),
('b0000006-0000-0000-0000-000000000005', org1, 'HTL-MUM-001', 'mumbai', NOW()::date - 20, NOW()::date -17,  25000.00, 'confirmed',   NOW() - INTERVAL '18 days'),
('b0000006-0000-0000-0000-000000000006', org1, 'HTL-MUM-002', 'mumbai', NOW()::date - 25, NOW()::date -22,  17800.00, 'checked_out', NOW() - INTERVAL '23 days'),
('b0000006-0000-0000-0000-000000000007', org1, 'HTL-MUM-003', 'mumbai', NOW()::date - 35, NOW()::date -32,  11000.00, 'confirmed',   NOW() - INTERVAL '33 days'),

-- ── Mumbai — org2 ────────────────────────────────────────────────────────────
('b0000007-0000-0000-0000-000000000001', org2, 'HTL-MUM-005', 'mumbai', NOW()::date - 4,  NOW()::date - 1,  28000.00, 'confirmed',   NOW() - INTERVAL '2 days'),
('b0000007-0000-0000-0000-000000000002', org2, 'HTL-MUM-006', 'mumbai', NOW()::date - 9,  NOW()::date - 6,  16500.00, 'pending',     NOW() - INTERVAL '7 days'),
('b0000007-0000-0000-0000-000000000003', org2, 'HTL-MUM-007', 'mumbai', NOW()::date - 14, NOW()::date -11,  22000.00, 'checked_out', NOW() - INTERVAL '12 days'),
('b0000007-0000-0000-0000-000000000004', org2, 'HTL-MUM-008', 'mumbai', NOW()::date - 19, NOW()::date -16,  13400.00, 'cancelled',   NOW() - INTERVAL '17 days'),
('b0000007-0000-0000-0000-000000000005', org2, 'HTL-MUM-005', 'mumbai', NOW()::date - 28, NOW()::date -25,  9800.00,  'confirmed',   NOW() - INTERVAL '26 days'),

-- ── Mumbai — org3 & org4 ─────────────────────────────────────────────────────
('b0000008-0000-0000-0000-000000000001', org3, 'HTL-MUM-009', 'mumbai', NOW()::date - 5,  NOW()::date - 2,  35000.00, 'checked_in',  NOW() - INTERVAL '3 days'),
('b0000008-0000-0000-0000-000000000002', org3, 'HTL-MUM-010', 'mumbai', NOW()::date - 13, NOW()::date -10,  18700.00, 'confirmed',   NOW() - INTERVAL '11 days'),
('b0000008-0000-0000-0000-000000000003', org3, 'HTL-MUM-009', 'mumbai', NOW()::date - 45, NOW()::date -42,  12200.00, 'cancelled',   NOW() - INTERVAL '43 days'),
('b0000008-0000-0000-0000-000000000004', org4, 'HTL-MUM-011', 'mumbai', NOW()::date - 7,  NOW()::date - 4,  41000.00, 'confirmed',   NOW() - INTERVAL '5 days'),
('b0000008-0000-0000-0000-000000000005', org4, 'HTL-MUM-012', 'mumbai', NOW()::date - 22, NOW()::date -19,  16300.00, 'checked_out', NOW() - INTERVAL '20 days'),

-- ── Bangalore ────────────────────────────────────────────────────────────────
('b0000009-0000-0000-0000-000000000001', org1, 'HTL-BLR-001', 'bangalore', NOW()::date - 1,  NOW()::date + 2,  15000.00, 'checked_in',  NOW() - INTERVAL '1 day'),
('b0000009-0000-0000-0000-000000000002', org1, 'HTL-BLR-002', 'bangalore', NOW()::date - 5,  NOW()::date - 2,  9800.00,  'confirmed',   NOW() - INTERVAL '3 days'),
('b0000009-0000-0000-0000-000000000003', org1, 'HTL-BLR-003', 'bangalore', NOW()::date - 10, NOW()::date - 7,  12500.00, 'checked_out', NOW() - INTERVAL '8 days'),
('b0000009-0000-0000-0000-000000000004', org2, 'HTL-BLR-004', 'bangalore', NOW()::date - 8,  NOW()::date - 5,  7200.00,  'cancelled',   NOW() - INTERVAL '6 days'),
('b0000009-0000-0000-0000-000000000005', org2, 'HTL-BLR-005', 'bangalore', NOW()::date - 16, NOW()::date -13,  18900.00, 'confirmed',   NOW() - INTERVAL '14 days'),
('b0000009-0000-0000-0000-000000000006', org2, 'HTL-BLR-006', 'bangalore', NOW()::date - 23, NOW()::date -20,  11400.00, 'pending',     NOW() - INTERVAL '21 days'),
('b0000009-0000-0000-0000-000000000007', org3, 'HTL-BLR-001', 'bangalore', NOW()::date - 12, NOW()::date - 9,  22000.00, 'confirmed',   NOW() - INTERVAL '10 days'),
('b0000009-0000-0000-0000-000000000008', org3, 'HTL-BLR-002', 'bangalore', NOW()::date - 27, NOW()::date -24,  8600.00,  'checked_out', NOW() - INTERVAL '25 days'),
('b0000009-0000-0000-0000-000000000009', org4, 'HTL-BLR-007', 'bangalore', NOW()::date - 3,  NOW()::date + 1,  29500.00, 'checked_in',  NOW() - INTERVAL '2 days'),
('b0000009-0000-0000-0000-000000000010', org4, 'HTL-BLR-008', 'bangalore', NOW()::date - 18, NOW()::date -15,  14700.00, 'confirmed',   NOW() - INTERVAL '16 days'),
('b0000009-0000-0000-0000-000000000011', org4, 'HTL-BLR-007', 'bangalore', NOW()::date - 55, NOW()::date -52,  10200.00, 'cancelled',   NOW() - INTERVAL '53 days'),

-- ── Chennai ───────────────────────────────────────────────────────────────────
('b0000010-0000-0000-0000-000000000001', org1, 'HTL-CHN-001', 'chennai', NOW()::date - 4,  NOW()::date - 1,  11200.00, 'confirmed',   NOW() - INTERVAL '2 days'),
('b0000010-0000-0000-0000-000000000002', org1, 'HTL-CHN-002', 'chennai', NOW()::date - 9,  NOW()::date - 6,  8500.00,  'checked_out', NOW() - INTERVAL '7 days'),
('b0000010-0000-0000-0000-000000000003', org2, 'HTL-CHN-003', 'chennai', NOW()::date - 6,  NOW()::date - 3,  16700.00, 'checked_in',  NOW() - INTERVAL '4 days'),
('b0000010-0000-0000-0000-000000000004', org2, 'HTL-CHN-004', 'chennai', NOW()::date - 14, NOW()::date -11,  7300.00,  'cancelled',   NOW() - INTERVAL '12 days'),
('b0000010-0000-0000-0000-000000000005', org2, 'HTL-CHN-005', 'chennai', NOW()::date - 20, NOW()::date -17,  13800.00, 'pending',     NOW() - INTERVAL '18 days'),
('b0000010-0000-0000-0000-000000000006', org3, 'HTL-CHN-001', 'chennai', NOW()::date - 11, NOW()::date - 8,  9100.00,  'confirmed',   NOW() - INTERVAL '9 days'),
('b0000010-0000-0000-0000-000000000007', org3, 'HTL-CHN-002', 'chennai', NOW()::date - 24, NOW()::date -21,  20500.00, 'checked_out', NOW() - INTERVAL '22 days'),
('b0000010-0000-0000-0000-000000000008', org4, 'HTL-CHN-006', 'chennai', NOW()::date - 7,  NOW()::date - 4,  15600.00, 'confirmed',   NOW() - INTERVAL '5 days'),
('b0000010-0000-0000-0000-000000000009', org4, 'HTL-CHN-007', 'chennai', NOW()::date - 17, NOW()::date -14,  6900.00,  'cancelled',   NOW() - INTERVAL '15 days'),
('b0000010-0000-0000-0000-000000000010', org1, 'HTL-CHN-003', 'chennai', NOW()::date - 50, NOW()::date -47,  10800.00, 'checked_out', NOW() - INTERVAL '48 days'),

-- ── Hyderabad ─────────────────────────────────────────────────────────────────
('b0000011-0000-0000-0000-000000000001', org1, 'HTL-HYD-001', 'hyderabad', NOW()::date - 2,  NOW()::date + 1,  19000.00, 'checked_in',  NOW() - INTERVAL '1 day'),
('b0000011-0000-0000-0000-000000000002', org1, 'HTL-HYD-002', 'hyderabad', NOW()::date - 7,  NOW()::date - 4,  12300.00, 'confirmed',   NOW() - INTERVAL '5 days'),
('b0000011-0000-0000-0000-000000000003', org1, 'HTL-HYD-003', 'hyderabad', NOW()::date - 13, NOW()::date -10,  8900.00,  'checked_out', NOW() - INTERVAL '11 days'),
('b0000011-0000-0000-0000-000000000004', org2, 'HTL-HYD-004', 'hyderabad', NOW()::date - 5,  NOW()::date - 2,  26000.00, 'confirmed',   NOW() - INTERVAL '3 days'),
('b0000011-0000-0000-0000-000000000005', org2, 'HTL-HYD-005', 'hyderabad', NOW()::date - 11, NOW()::date - 8,  14500.00, 'cancelled',   NOW() - INTERVAL '9 days'),
('b0000011-0000-0000-0000-000000000006', org2, 'HTL-HYD-006', 'hyderabad', NOW()::date - 22, NOW()::date -19,  9700.00,  'pending',     NOW() - INTERVAL '20 days'),
('b0000011-0000-0000-0000-000000000007', org3, 'HTL-HYD-001', 'hyderabad', NOW()::date - 8,  NOW()::date - 5,  31000.00, 'confirmed',   NOW() - INTERVAL '6 days'),
('b0000011-0000-0000-0000-000000000008', org3, 'HTL-HYD-002', 'hyderabad', NOW()::date - 16, NOW()::date -13,  17200.00, 'checked_out', NOW() - INTERVAL '14 days'),
('b0000011-0000-0000-0000-000000000009', org3, 'HTL-HYD-003', 'hyderabad', NOW()::date - 29, NOW()::date -26,  6800.00,  'cancelled',   NOW() - INTERVAL '27 days'),
('b0000011-0000-0000-0000-000000000010', org4, 'HTL-HYD-007', 'hyderabad', NOW()::date - 4,  NOW()::date - 1,  22500.00, 'checked_in',  NOW() - INTERVAL '2 days'),
('b0000011-0000-0000-0000-000000000011', org4, 'HTL-HYD-008', 'hyderabad', NOW()::date - 15, NOW()::date -12,  11800.00, 'confirmed',   NOW() - INTERVAL '13 days'),
('b0000011-0000-0000-0000-000000000012', org4, 'HTL-HYD-009', 'hyderabad', NOW()::date - 25, NOW()::date -22,  8200.00,  'pending',     NOW() - INTERVAL '23 days'),
('b0000011-0000-0000-0000-000000000013', org1, 'HTL-HYD-004', 'hyderabad', NOW()::date - 42, NOW()::date -39,  15400.00, 'checked_out', NOW() - INTERVAL '40 days'),
('b0000011-0000-0000-0000-000000000014', org2, 'HTL-HYD-005', 'hyderabad', NOW()::date - 55, NOW()::date -52,  9300.00,  'cancelled',   NOW() - INTERVAL '53 days'),

-- ── Additional rows to ensure total >= 120 ────────────────────────────────────
('b0000012-0000-0000-0000-000000000001', org1, 'HTL-DEL-020', 'delhi',     NOW()::date - 1,  NOW()::date + 3,  45000.00, 'checked_in',  NOW() - INTERVAL '12 hours'),
('b0000012-0000-0000-0000-000000000002', org2, 'HTL-MUM-013', 'mumbai',    NOW()::date + 2,  NOW()::date + 5,  38000.00, 'confirmed',   NOW() - INTERVAL '5 hours'),
('b0000012-0000-0000-0000-000000000003', org3, 'HTL-BLR-009', 'bangalore', NOW()::date - 2,  NOW()::date + 1,  17500.00, 'checked_in',  NOW() - INTERVAL '8 hours'),
('b0000012-0000-0000-0000-000000000004', org4, 'HTL-CHN-008', 'chennai',   NOW()::date - 3,  NOW()::date + 2,  21000.00, 'confirmed',   NOW() - INTERVAL '2 days'),
('b0000012-0000-0000-0000-000000000005', org1, 'HTL-HYD-010', 'hyderabad', NOW()::date - 1,  NOW()::date + 4,  28500.00, 'checked_in',  NOW() - INTERVAL '6 hours'),
('b0000012-0000-0000-0000-000000000006', org2, 'HTL-DEL-021', 'delhi',     NOW()::date - 26, NOW()::date -23,  10800.00, 'confirmed',   NOW() - INTERVAL '24 days'),
('b0000012-0000-0000-0000-000000000007', org3, 'HTL-MUM-014', 'mumbai',    NOW()::date - 17, NOW()::date -14,  33500.00, 'confirmed',   NOW() - INTERVAL '15 days'),
('b0000012-0000-0000-0000-000000000008', org4, 'HTL-BLR-010', 'bangalore', NOW()::date - 22, NOW()::date -19,  16800.00, 'cancelled',   NOW() - INTERVAL '20 days'),
('b0000012-0000-0000-0000-000000000009', org1, 'HTL-CHN-009', 'chennai',   NOW()::date - 26, NOW()::date -23,  12400.00, 'pending',     NOW() - INTERVAL '24 days'),
('b0000012-0000-0000-0000-000000000010', org2, 'HTL-HYD-011', 'hyderabad', NOW()::date - 28, NOW()::date -25,  19700.00, 'checked_out', NOW() - INTERVAL '26 days'),
('b0000012-0000-0000-0000-000000000011', org3, 'HTL-DEL-022', 'delhi',     NOW()::date - 23, NOW()::date -20,  8100.00,  'cancelled',   NOW() - INTERVAL '21 days'),
('b0000012-0000-0000-0000-000000000012', org4, 'HTL-MUM-015', 'mumbai',    NOW()::date - 24, NOW()::date -21,  27300.00, 'confirmed',   NOW() - INTERVAL '22 days'),
('b0000012-0000-0000-0000-000000000013', org1, 'HTL-BLR-011', 'bangalore', NOW()::date - 29, NOW()::date -26,  14100.00, 'checked_out', NOW() - INTERVAL '27 days');

-- ─── booking_events seed ─────────────────────────────────────────────────────
-- Events for ~43% of bookings, showing lifecycle transitions

INSERT INTO booking_events (booking_id, event_type, payload, created_at) VALUES

-- booking_created events
('b0000001-0000-0000-0000-000000000001', 'booking_created',   '{"source": "web", "agent_id": "A001"}'::jsonb,                               NOW() - INTERVAL '3 days'),
('b0000001-0000-0000-0000-000000000002', 'booking_created',   '{"source": "mobile", "agent_id": "A002"}'::jsonb,                            NOW() - INTERVAL '6 days'),
('b0000001-0000-0000-0000-000000000003', 'booking_created',   '{"source": "api", "partner_id": "P001"}'::jsonb,                             NOW() - INTERVAL '10 days'),
('b0000002-0000-0000-0000-000000000001', 'booking_created',   '{"source": "web", "agent_id": "A003"}'::jsonb,                               NOW() - INTERVAL '2 days'),
('b0000002-0000-0000-0000-000000000004', 'booking_created',   '{"source": "mobile", "agent_id": "A001"}'::jsonb,                            NOW() - INTERVAL '12 days'),
('b0000003-0000-0000-0000-000000000001', 'booking_created',   '{"source": "api", "partner_id": "P002"}'::jsonb,                             NOW() - INTERVAL '4 days'),
('b0000006-0000-0000-0000-000000000001', 'booking_created',   '{"source": "web", "agent_id": "A004"}'::jsonb,                               NOW() - INTERVAL '1 day'),
('b0000007-0000-0000-0000-000000000001', 'booking_created',   '{"source": "web", "agent_id": "A002"}'::jsonb,                               NOW() - INTERVAL '2 days'),
('b0000009-0000-0000-0000-000000000001', 'booking_created',   '{"source": "mobile", "agent_id": "A005"}'::jsonb,                            NOW() - INTERVAL '1 day'),
('b0000011-0000-0000-0000-000000000001', 'booking_created',   '{"source": "api", "partner_id": "P001"}'::jsonb,                             NOW() - INTERVAL '1 day'),

-- payment_received events
('b0000001-0000-0000-0000-000000000001', 'payment_received',  '{"amount": 8500.00, "method": "credit_card", "txn_id": "TXN-001"}'::jsonb,   NOW() - INTERVAL '3 days' + INTERVAL '1 hour'),
('b0000001-0000-0000-0000-000000000002', 'payment_received',  '{"amount": 12000.00, "method": "upi", "txn_id": "TXN-002"}'::jsonb,          NOW() - INTERVAL '6 days' + INTERVAL '30 minutes'),
('b0000002-0000-0000-0000-000000000001', 'payment_received',  '{"amount": 18000.00, "method": "net_banking", "txn_id": "TXN-003"}'::jsonb,  NOW() - INTERVAL '2 days' + INTERVAL '1 hour'),
('b0000006-0000-0000-0000-000000000001', 'payment_received',  '{"amount": 32000.00, "method": "credit_card", "txn_id": "TXN-004"}'::jsonb,  NOW() - INTERVAL '23 hours'),
('b0000007-0000-0000-0000-000000000001', 'payment_received',  '{"amount": 28000.00, "method": "upi", "txn_id": "TXN-005"}'::jsonb,          NOW() - INTERVAL '2 days' + INTERVAL '2 hours'),
('b0000009-0000-0000-0000-000000000001', 'payment_received',  '{"amount": 15000.00, "method": "credit_card", "txn_id": "TXN-006"}'::jsonb,  NOW() - INTERVAL '22 hours'),

-- checked_in events
('b0000001-0000-0000-0000-000000000003', 'checked_in',        '{"room_number": "304", "floor": 3}'::jsonb,                                  NOW() - INTERVAL '12 days'),
('b0000002-0000-0000-0000-000000000001', 'checked_in',        '{"room_number": "501", "floor": 5, "upgrade": true}'::jsonb,                 NOW() - INTERVAL '1 day'),
('b0000006-0000-0000-0000-000000000001', 'checked_in',        '{"room_number": "201", "floor": 2}'::jsonb,                                  NOW() - INTERVAL '20 hours'),
('b0000009-0000-0000-0000-000000000001', 'checked_in',        '{"room_number": "102", "floor": 1}'::jsonb,                                  NOW() - INTERVAL '18 hours'),
('b0000011-0000-0000-0000-000000000001', 'checked_in',        '{"room_number": "612", "floor": 6, "upgrade": true}'::jsonb,                 NOW() - INTERVAL '16 hours'),

-- checked_out events
('b0000001-0000-0000-0000-000000000003', 'checked_out',       '{"room_number": "304", "minibar_charges": 350.00}'::jsonb,                   NOW() - INTERVAL '9 days'),
('b0000002-0000-0000-0000-000000000005', 'checked_out',       '{"room_number": "702", "minibar_charges": 0}'::jsonb,                        NOW() - INTERVAL '17 days'),
('b0000006-0000-0000-0000-000000000003', 'checked_out',       '{"room_number": "305", "minibar_charges": 750.00}'::jsonb,                   NOW() - INTERVAL '8 days'),

-- cancellation events
('b0000001-0000-0000-0000-000000000004', 'booking_cancelled', '{"reason": "customer_request", "refund_amount": 6200.00}'::jsonb,            NOW() - INTERVAL '13 days'),
('b0000002-0000-0000-0000-000000000003', 'booking_cancelled', '{"reason": "no_show", "refund_amount": 0}'::jsonb,                           NOW() - INTERVAL '9 days'),
('b0000009-0000-0000-0000-000000000004', 'booking_cancelled', '{"reason": "customer_request", "refund_amount": 7200.00}'::jsonb,            NOW() - INTERVAL '6 days'),
('b0000010-0000-0000-0000-000000000004', 'booking_cancelled', '{"reason": "hotel_unavailable", "refund_amount": 7300.00}'::jsonb,           NOW() - INTERVAL '12 days'),

-- status_updated events  
('b0000001-0000-0000-0000-000000000008', 'status_updated',    '{"from": "pending", "to": "confirmed", "updated_by": "ops-team"}'::jsonb,    NOW() - INTERVAL '25 days'),
('b0000002-0000-0000-0000-000000000007', 'status_updated',    '{"from": "confirmed", "to": "pending", "reason": "payment_retry"}'::jsonb,  NOW() - INTERVAL '24 days'),
('b0000009-0000-0000-0000-000000000006', 'status_updated',    '{"from": "confirmed", "to": "pending", "reason": "document_missing"}'::jsonb, NOW() - INTERVAL '20 days'),

-- reminder_sent events (automated)
('b0000001-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "email", "template": "checkin_reminder_24h"}'::jsonb,            NOW() - INTERVAL '4 days'),
('b0000002-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "sms", "template": "checkin_reminder_24h"}'::jsonb,              NOW() - INTERVAL '2 days'),
('b0000006-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "email", "template": "checkin_reminder_24h"}'::jsonb,            NOW() - INTERVAL '2 days'),
('b0000007-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "whatsapp", "template": "checkin_reminder_48h"}'::jsonb,         NOW() - INTERVAL '3 days'),
('b0000009-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "email", "template": "checkin_reminder_24h"}'::jsonb,            NOW() - INTERVAL '2 days'),
('b0000011-0000-0000-0000-000000000001', 'reminder_sent',     '{"channel": "sms", "template": "checkin_reminder_24h"}'::jsonb,              NOW() - INTERVAL '2 days');

END $$;
