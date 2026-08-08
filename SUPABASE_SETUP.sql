-- ============================================================
-- YOUTH ELECTION 2025 — COMPLETE SUPABASE SETUP SCRIPT
-- Run this ONCE in Supabase SQL Editor
-- ============================================================

-- 1. STAFF TABLE (admin & operator roles)
CREATE TABLE IF NOT EXISTS staff (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        text NOT NULL CHECK (role IN ('admin', 'operator')),
  created_at  timestamptz DEFAULT now()
);

-- 1.4 CREATE THE ADMIN AUTH USER
-- The SQL function auth.admin_create_user is not available in all Supabase
-- versions, so create the user manually in the dashboard instead:
--   Authentication → Users → Add user
--   Email: obiajuluonuchukwu@gmail.com
--   Password: ChangeMe123!
--   Check "Auto Confirm User"
-- Then run section 1.5 below (it links the user to the admin staff role).

-- 1.5 ⚠️ MAKE YOUR ACCOUNT ADMIN (links the auth user to staff role)
-- Safe to re-run; it only sets the admin role.
INSERT INTO staff (user_id, role)
SELECT id, 'admin'
FROM auth.users
WHERE email = 'obiajuluonuchukwu@gmail.com'   -- ⚠️ CHANGE THIS to your admin email
ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

-- 2. REGISTERED VOTERS TABLE
CREATE TABLE IF NOT EXISTS registered_voters (
  voter_id    text PRIMARY KEY,
  name        text,
  has_voted   boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);
-- Safely add columns if table already existed without them
ALTER TABLE registered_voters ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE registered_voters ADD COLUMN IF NOT EXISTS has_voted boolean DEFAULT false;

-- 3. POSITIONS TABLE
CREATE TABLE IF NOT EXISTS positions (
  id          serial PRIMARY KEY,
  name        text UNIQUE NOT NULL,
  sort_order  bigint DEFAULT 0
);
-- Safely add sort_order if table already existed without it
ALTER TABLE positions ADD COLUMN IF NOT EXISTS sort_order bigint DEFAULT 0;
-- Convert existing integer column to bigint so Date.now() timestamps fit
ALTER TABLE positions ALTER COLUMN sort_order TYPE bigint;

-- 4. CANDIDATES TABLE
CREATE TABLE IF NOT EXISTS candidates (
  id          serial PRIMARY KEY,
  position_id integer REFERENCES positions(id) ON DELETE CASCADE,
  name        text NOT NULL
);

-- 5. BALLOTS TABLE
CREATE TABLE IF NOT EXISTS ballots (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id    text REFERENCES registered_voters(voter_id),
  cast_at     timestamptz DEFAULT now()
);
-- Safely add columns if table already existed without them
ALTER TABLE ballots ADD COLUMN IF NOT EXISTS voter_id text;
ALTER TABLE ballots ADD COLUMN IF NOT EXISTS cast_at timestamptz DEFAULT now();

-- 6. VOTES TABLE
CREATE TABLE IF NOT EXISTS votes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ballot_id    uuid REFERENCES ballots(id) ON DELETE CASCADE,
  position_id  integer REFERENCES positions(id),
  candidate_id integer REFERENCES candidates(id),
  is_abstain   boolean DEFAULT false
);

-- ============================================================
-- 7. RPC: my_role — returns the current user's role
-- ============================================================
DROP FUNCTION IF EXISTS my_role();
CREATE OR REPLACE FUNCTION my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT role FROM staff WHERE user_id = auth.uid();
$$;

-- ============================================================
-- 8. RPC: election_ballot — returns positions + candidates
-- ============================================================
DROP FUNCTION IF EXISTS election_ballot();
CREATE OR REPLACE FUNCTION election_ballot()
RETURNS json
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT json_build_object(
    'positions', (
      SELECT json_agg(
        json_build_object(
          'name', p.name,
          'candidates', (
            SELECT json_agg(c.name ORDER BY c.name)
            FROM candidates c WHERE c.position_id = p.id
          )
        ) ORDER BY COALESCE(p.sort_order, p.id)
      )
      FROM positions p
    )
  );
$$;

-- ============================================================
-- 9. RPC: verify_voter — checks if voter exists & hasn't voted
-- ============================================================
DROP FUNCTION IF EXISTS verify_voter(text);
CREATE OR REPLACE FUNCTION verify_voter(p_voter text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists boolean;
  v_voted  boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM registered_voters WHERE voter_id = p_voter) INTO v_exists;
  IF NOT v_exists THEN
    RETURN json_build_object('ok', false, 'reason', 'Voter ID not found in register.');
  END IF;

  SELECT COALESCE(has_voted, false) INTO v_voted FROM registered_voters WHERE voter_id = p_voter LIMIT 1;
  IF v_voted THEN
    RETURN json_build_object('ok', false, 'reason', 'This voter has already cast a ballot.');
  END IF;

  RETURN json_build_object('ok', true);
END;
$$;

-- ============================================================
-- 10. RPC: cast_ballot — records votes (drop json & jsonb overloads)
-- ============================================================
DROP FUNCTION IF EXISTS cast_ballot(text, json);
DROP FUNCTION IF EXISTS cast_ballot(text, jsonb);

CREATE OR REPLACE FUNCTION cast_ballot(p_voter text, p_picks json)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  bid     uuid;
  v_exists boolean;
  v_voted  boolean;
  pos     positions;
  chosen  text;
  cid     integer;
BEGIN
  SELECT EXISTS(SELECT 1 FROM registered_voters WHERE voter_id = p_voter) INTO v_exists;
  IF NOT v_exists THEN
    RETURN json_build_object('ok', false, 'reason', 'Voter ID not found in register.');
  END IF;

  SELECT COALESCE(has_voted, false) INTO v_voted FROM registered_voters WHERE voter_id = p_voter LIMIT 1;
  IF v_voted THEN
    RETURN json_build_object('ok', false, 'reason', 'This voter has already cast a ballot.');
  END IF;

  INSERT INTO ballots (voter_id) VALUES (p_voter) RETURNING id INTO bid;

  FOR pos IN SELECT * FROM positions LOOP
    chosen := p_picks ->> pos.name;
    IF chosen IS NULL OR chosen = 'Abstain' THEN
      INSERT INTO votes (ballot_id, position_id, is_abstain) VALUES (bid, pos.id, true);
    ELSE
      SELECT id INTO cid FROM candidates WHERE position_id = pos.id AND name = chosen LIMIT 1;
      INSERT INTO votes (ballot_id, position_id, candidate_id, is_abstain)
      VALUES (bid, pos.id, cid, false);
    END IF;
  END LOOP;

  UPDATE registered_voters SET has_voted = true WHERE voter_id = p_voter;
  RETURN json_build_object('ok', true);
END;
$$;

-- ============================================================
-- 11. RPC: election_results — live tally
-- ============================================================
CREATE OR REPLACE FUNCTION election_results()
RETURNS json
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT json_build_object(
    'ballots',    (SELECT COUNT(*) FROM ballots),
    'registered', (SELECT COUNT(*) FROM registered_voters),
    'positions',  (
      SELECT json_agg(
        json_build_object(
          'name', p.name,
          'candidates', (
            SELECT json_agg(
              json_build_object(
                'name', c.name,
                'votes', (SELECT COUNT(*) FROM votes v WHERE v.candidate_id = c.id AND NOT v.is_abstain)
              ) ORDER BY c.name
            )
            FROM candidates c WHERE c.position_id = p.id
          )
        ) ORDER BY COALESCE(p.sort_order, p.id)
      )
      FROM positions p
    )
  );
$$;

-- ============================================================
-- 12. PERMISSIONS & ROW LEVEL SECURITY
-- ============================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

ALTER TABLE staff              ENABLE ROW LEVEL SECURITY;
ALTER TABLE registered_voters  ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE ballots            ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes              ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_positions" ON positions;
CREATE POLICY "allow_all_positions" ON positions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_candidates" ON candidates;
CREATE POLICY "allow_all_candidates" ON candidates FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_staff" ON staff;
CREATE POLICY "allow_all_staff" ON staff FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_voters" ON registered_voters;
CREATE POLICY "allow_all_voters" ON registered_voters FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_ballots" ON ballots;
CREATE POLICY "allow_all_ballots" ON ballots FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_votes" ON votes;
CREATE POLICY "allow_all_votes" ON votes FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- 14. SAMPLE DATA — 4 Registered Voters
-- ============================================================
INSERT INTO registered_voters (voter_id, name) VALUES
  ('YTH-001', 'Alex Johnson'),
  ('YTH-002', 'Sarah Williams'),
  ('YTH-003', 'David Chukwu'),
  ('YTH-004', 'Emily Davis')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 15. SAMPLE DATA — 2 Positions with Candidates
-- ============================================================
INSERT INTO positions (name, sort_order) VALUES
  ('President', 1),
  ('Secretary General', 2)
ON CONFLICT DO NOTHING;

INSERT INTO candidates (position_id, name)
SELECT p.id, c.name
FROM (VALUES
  ('President',          'Candidate A'),
  ('President',          'Candidate B'),
  ('President',          'Candidate C'),
  ('Secretary General',  'Candidate D'),
  ('Secretary General',  'Candidate E')
) AS c(pos, name)
JOIN positions p ON p.name = c.pos
WHERE NOT EXISTS (
  SELECT 1 FROM candidates x WHERE x.position_id = p.id AND x.name = c.name
);


-- ============================================================
-- 16. ELECTION SETTINGS TABLE — Customizable application title
-- ============================================================
CREATE TABLE IF NOT EXISTS election_settings (
  id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  app_title text NOT NULL DEFAULT 'Youth Election Terminal',
  election_status text NOT NULL DEFAULT 'open' CHECK (election_status IN ('draft', 'open', 'closed')),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO election_settings (id, app_title, election_status)
VALUES (1, 'Youth Election Terminal', 'open')
ON CONFLICT (id) DO UPDATE SET
  app_title = COALESCE(election_settings.app_title, EXCLUDED.app_title),
  election_status = COALESCE(election_settings.election_status, EXCLUDED.election_status);

-- ============================================================
-- 17. AUDIT LOG TABLE — Track all admin actions
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id serial PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  user_email text,
  action text NOT NULL,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 18. RPC: election_settings — Read current settings
-- ============================================================
 CREATE OR REPLACE FUNCTION election_settings()
 RETURNS json
 LANGUAGE sql
 SECURITY DEFINER
 AS $$
   SELECT COALESCE(
     (SELECT json_build_object('app_title', app_title, 'election_status', election_status)
      FROM election_settings WHERE id = 1),
     json_build_object('app_title', 'Youth Election Terminal', 'election_status', 'open')
   );
 $$;

-- ============================================================
-- 19. RPC: update_election_title — Admin-only title update
-- ============================================================
CREATE OR REPLACE FUNCTION update_election_title(p_title text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role text;
  v_email text;
BEGIN
  SELECT role INTO v_role FROM staff WHERE user_id = auth.uid();
  
  IF v_role <> 'admin' THEN
    RAISE EXCEPTION 'Admin role required';
  END IF;

  IF length(trim(p_title)) = 0 OR length(trim(p_title)) > 80 THEN
    RAISE EXCEPTION 'Title must contain between 1 and 80 characters';
  END IF;

  INSERT INTO election_settings (id, app_title, updated_at)
  VALUES (1, trim(p_title), now())
  ON CONFLICT (id)
  DO UPDATE SET app_title = EXCLUDED.app_title, updated_at = now();

  -- Log the action
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  INSERT INTO audit_log (user_id, user_email, action, details)
  VALUES (auth.uid(), v_email, 'update_title', json_build_object('new_title', trim(p_title)));

  RETURN json_build_object('ok', true, 'app_title', trim(p_title));
END;
$$;

-- ============================================================
-- 20. RPC: update_election_status — Admin-only status control
-- ============================================================
CREATE OR REPLACE FUNCTION update_election_status(p_status text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role text;
  v_email text;
BEGIN
  SELECT role INTO v_role FROM staff WHERE user_id = auth.uid();
  
  IF v_role <> 'admin' THEN
    RAISE EXCEPTION 'Admin role required';
  END IF;

  IF p_status NOT IN ('draft', 'open', 'closed') THEN
    RAISE EXCEPTION 'Invalid status. Must be: draft, open, or closed';
  END IF;

  UPDATE election_settings SET election_status = p_status, updated_at = now() WHERE id = 1;

  -- Log the action
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  INSERT INTO audit_log (user_id, user_email, action, details)
  VALUES (auth.uid(), v_email, 'update_status', json_build_object('new_status', p_status));

  RETURN json_build_object('ok', true, 'election_status', p_status);
END;
$$;

-- ============================================================
-- 21. RPC: reset_election — Admin-only data reset with audit
-- ============================================================
CREATE OR REPLACE FUNCTION reset_election(
  p_confirmation text,
  p_delete_voters boolean DEFAULT false,
  p_delete_structure boolean DEFAULT false
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role text;
  v_email text;
  v_ballots_count int;
  v_votes_count int;
  v_voters_count int;
  v_positions_count int;
BEGIN
  SELECT role INTO v_role FROM staff WHERE user_id = auth.uid();
  
  IF v_role <> 'admin' THEN
    RAISE EXCEPTION 'Admin role required';
  END IF;

  IF p_confirmation <> 'RESET' THEN
    RAISE EXCEPTION 'Reset confirmation is invalid';
  END IF;

  -- Capture counts before deletion for audit log
  SELECT COUNT(*) INTO v_ballots_count FROM ballots;
  SELECT COUNT(*) INTO v_votes_count FROM votes;
  SELECT COUNT(*) INTO v_voters_count FROM registered_voters;
  SELECT COUNT(*) INTO v_positions_count FROM positions;

  -- Clear votes first, then ballots (respects foreign keys)
  DELETE FROM votes;
  DELETE FROM ballots;

  IF p_delete_voters THEN
    DELETE FROM registered_voters;
  ELSE
    UPDATE registered_voters SET has_voted = false;
  END IF;

  IF p_delete_structure THEN
    DELETE FROM candidates;
    DELETE FROM positions;
  END IF;

  -- Log the reset action with details
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  INSERT INTO audit_log (user_id, user_email, action, details)
  VALUES (auth.uid(), v_email, 'reset_election', json_build_object(
    'ballots_deleted', v_ballots_count,
    'votes_deleted', v_votes_count,
    'voters_deleted', CASE WHEN p_delete_voters THEN v_voters_count ELSE 0 END,
    'voters_reset', CASE WHEN NOT p_delete_voters THEN v_voters_count ELSE 0 END,
    'structure_deleted', p_delete_structure,
    'positions_deleted', CASE WHEN p_delete_structure THEN v_positions_count ELSE 0 END
  ));

  RETURN json_build_object(
    'ok', true,
    'message', 'Election data has been reset successfully.'
  );
END;
$$;

-- ============================================================
-- 22. ENHANCED RPC: verify_voter — Check election status
-- ============================================================
DROP FUNCTION IF EXISTS verify_voter(text);
CREATE OR REPLACE FUNCTION verify_voter(p_voter text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists boolean;
  v_voted  boolean;
  v_status text;
BEGIN
  -- Check if election is open (default to 'open' if settings row is missing)
  SELECT COALESCE(election_status, 'open') INTO v_status FROM election_settings WHERE id = 1;
  IF v_status IS DISTINCT FROM 'open' THEN
    RETURN json_build_object('ok', false, 'reason', 'Election is currently ' || COALESCE(v_status, 'unknown') || '. Voting is only allowed when election is open.');
  END IF;

  SELECT EXISTS(SELECT 1 FROM registered_voters WHERE voter_id = p_voter) INTO v_exists;
  IF NOT v_exists THEN
    RETURN json_build_object('ok', false, 'reason', 'Voter ID not found in register.');
  END IF;

  SELECT COALESCE(has_voted, false) INTO v_voted FROM registered_voters WHERE voter_id = p_voter LIMIT 1;
  IF v_voted THEN
    RETURN json_build_object('ok', false, 'reason', 'This voter has already cast a ballot.');
  END IF;

  RETURN json_build_object('ok', true);
END;
$$;

-- ============================================================
-- 23. ENHANCED RPC: cast_ballot — Check election status & lock voter
-- ============================================================
DROP FUNCTION IF EXISTS cast_ballot(text, json);
DROP FUNCTION IF EXISTS cast_ballot(text, jsonb);

CREATE OR REPLACE FUNCTION cast_ballot(p_voter text, p_picks json)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  bid     uuid;
  v_exists boolean;
  v_voted  boolean;
  v_status text;
  pos     positions;
  chosen  text;
  cid     integer;
BEGIN
  -- Check if election is open (default to 'open' if settings row is missing)
  SELECT COALESCE(election_status, 'open') INTO v_status FROM election_settings WHERE id = 1;
  IF v_status IS DISTINCT FROM 'open' THEN
    RETURN json_build_object('ok', false, 'reason', 'Election is currently ' || COALESCE(v_status, 'unknown') || '. Voting is not allowed.');
  END IF;

  -- Lock the voter row for update to prevent concurrent ballots
  SELECT has_voted INTO v_voted 
  FROM registered_voters 
  WHERE voter_id = p_voter 
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'reason', 'Voter ID not found in register.');
  END IF;

  IF v_voted THEN
    RETURN json_build_object('ok', false, 'reason', 'This voter has already cast a ballot.');
  END IF;

  INSERT INTO ballots (voter_id) VALUES (p_voter) RETURNING id INTO bid;

  FOR pos IN SELECT * FROM positions LOOP
    chosen := p_picks ->> pos.name;
    IF chosen IS NULL OR chosen = 'Abstain' THEN
      INSERT INTO votes (ballot_id, position_id, is_abstain) VALUES (bid, pos.id, true);
    ELSE
      SELECT id INTO cid FROM candidates WHERE position_id = pos.id AND name = chosen LIMIT 1;
      INSERT INTO votes (ballot_id, position_id, candidate_id, is_abstain)
      VALUES (bid, pos.id, cid, false);
    END IF;
  END LOOP;

  UPDATE registered_voters SET has_voted = true WHERE voter_id = p_voter;
  RETURN json_build_object('ok', true);
END;
$$;

-- ============================================================
-- 24. GRANT PERMISSIONS FOR NEW FUNCTIONS
-- ============================================================
GRANT EXECUTE ON FUNCTION election_settings() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_election_title(text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_election_status(text) TO authenticated;
GRANT EXECUTE ON FUNCTION reset_election(text, boolean, boolean) TO authenticated;

-- Enable RLS on new tables
ALTER TABLE election_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_read_settings" ON election_settings;
CREATE POLICY "allow_read_settings" ON election_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "allow_admin_audit" ON audit_log;
CREATE POLICY "allow_admin_audit" ON audit_log FOR ALL 
USING ((SELECT role FROM staff WHERE user_id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM staff WHERE user_id = auth.uid()) = 'admin');

-- ============================================================
-- 25. RPC: ensure_admin — auto-link the CURRENT logged-in user as admin
-- Call this on every admin login so an orphaned staff.user_id can never
-- block access (handles user re-created / id changed scenarios).
-- ============================================================
CREATE OR REPLACE FUNCTION ensure_admin()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('ok', false, 'reason', 'Not authenticated');
  END IF;

  INSERT INTO staff (user_id, role)
  VALUES (v_uid, 'admin')
  ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

  RETURN json_build_object('ok', true, 'role', 'admin');
END;
$$;

GRANT EXECUTE ON FUNCTION ensure_admin() TO authenticated;

-- ============================================================
-- 26. RPC: list_officers — return all staff with their auth email
-- SECURITY DEFINER so it can read auth.users server-side (browser
-- cannot query auth.users directly due to RLS).
-- ============================================================
CREATE OR REPLACE FUNCTION list_officers()
RETURNS json
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    json_agg(
      json_build_object('email', u.email, 'role', s.role)
      ORDER BY s.role, u.email
    ),
    '[]'::json
  )
  FROM staff s
  JOIN auth.users u ON u.id = s.user_id;
$$;

GRANT EXECUTE ON FUNCTION list_officers() TO authenticated;

-- ============================================================
-- SETUP COMPLETE
-- ============================================================
