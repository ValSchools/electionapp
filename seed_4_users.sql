-- =========================================================
-- 1. MAKE YOUR ACCOUNT ADMIN
-- =========================================================
INSERT INTO staff (user_id, role)
SELECT id, 'admin' FROM auth.users WHERE email = 'obiajuluonuchukwu@gmail.com'
ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

-- =========================================================
-- 2. SEED 4 SAMPLE REGISTERED VOTERS (YTH-001 to YTH-004)
-- =========================================================
INSERT INTO registered_voters (voter_id, name)
VALUES 
  ('YTH-001', 'Alex Johnson'),
  ('YTH-002', 'Sarah Williams'),
  ('YTH-003', 'David Chukwu'),
  ('YTH-004', 'Emily Davis')
ON CONFLICT DO NOTHING;
