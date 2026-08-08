# 🚀 Quick Start Guide - Youth Election App

## ⚡ 5-Minute Setup

### Step 1: Supabase Setup (2 minutes)

1. **Create Supabase Project** at https://supabase.com
   - Click "New Project"
   - Name it (e.g., "youth-election")
   - Wait for setup to complete

2. **Run SQL Setup**:
   - Open "SQL Editor" in Supabase
   - Copy all content from `SUPABASE_SETUP.sql`
   - Paste and click "Run"
   - ✅ Success!

3. **Create Admin Account**:
   - Go to "Authentication" → "Users"
   - Click "Add user" → "Create new user"
   - Enter your email + password
   - Toggle "Auto Confirm User" ON
   - Click "Create user"

4. **Make Yourself Admin**:
   - Go back to "SQL Editor"
   - Run this (replace email):
     ```sql
     INSERT INTO staff (user_id, role)
     SELECT id, 'admin'
     FROM auth.users
     WHERE email = 'YOUR-EMAIL@example.com'
     ON CONFLICT (user_id) DO UPDATE SET role = 'admin';
     ```

### Step 2: Configure App (1 minute)

1. **Get Credentials** from Supabase:
   - Go to "Settings" → "API"
   - Copy "Project URL"
   - Copy "anon public" key

2. **Update admin.html**:
   - Open in text editor
   - Find line ~201 (the `CFG` object)
   - Replace `url` and `key` with your values
   - Save

3. **Update index.html**:
   - Open in text editor
   - Find line ~102 (the `CFG` object)
   - Replace `url` and `key` (same values)
   - Save

### Step 3: Deploy (2 minutes)

**Option A: Drag & Drop (Easiest)**
1. Go to https://app.netlify.com
2. Drag your entire `voting-app` folder onto the page
3. ✅ Done! Note your URL

**Option B: Netlify CLI**
1. Install: `npm install -g netlify-cli`
2. Login: `netlify login`
3. Deploy: `netlify deploy --prod`
4. ✅ Done!

---

## 🎯 First Login

1. Go to `https://your-site.netlify.app/admin.html`
2. Sign in with your admin email + password
3. You should see the admin dashboard with 6 tabs

---

## ✅ What You Can Do Now

### As Admin:

#### 📊 Live Overview Tab
- See real-time ballot counts
- Monitor turnout percentage
- View live tally results

#### 🎟️ Voter Codes Tab
- Generate bulk voter codes
- Add individual voters
- Export unused codes
- Delete voters

#### ✏️ Contestants & Positions Tab
- Add positions (President, Secretary, etc.)
- Add candidates to each position
- Delete positions/candidates

#### 👥 Polling Officers Tab
- Create officer accounts one by one
- Bulk upload via CSV
- Officers can sign in at `index.html` to cast ballots

#### ⚡ Export & Tools Tab
- Download election results as JSON

#### ⚙️ Settings Tab (NEW!)
- **Change Application Title**
  - Enter new title
  - Click "Save Title"
  - Updates everywhere instantly

- **Control Election Status**
  - Draft: Setup mode (no voting)
  - Open: Enable voting
  - Closed: End election
  - Click "Update Status"

- **Reset Election (Danger Zone)**
  - Clear all ballots and votes
  - Optional: Delete voters
  - Optional: Delete structure
  - Type "RESET" to confirm
  - All actions are audit logged

---

## 🗳️ How Voting Works

### For Officers:
1. Go to `https://your-site.netlify.app/index.html`
2. Sign in with officer credentials
3. Voter arrives with paper ID
4. Enter Voter ID code
5. Click "Verify & Open Ballot"
6. Hand device to voter

### For Voters:
1. Select one candidate per position (or Abstain)
2. Click "Next" through all positions
3. Review ballot
4. Click "Cast Official Ballot"
5. Hand device back to officer

### For Next Voter:
1. Officer clicks "Next Voter"
2. Process repeats

---

## 🎓 New Features Guide

### Feature 1: Customizable Title

**What it does**: Change "Youth Election Terminal" to your custom name

**How to use**:
1. Admin → Settings tab
2. Type new title
3. Save
4. Appears on both admin and voting pages

**Example**: "2025 Student Council Election"

### Feature 2: Election Status

**What it does**: Control when voting is allowed

**Statuses**:
- **Draft**: Setup mode, no voting (use during setup)
- **Open**: Voting enabled (election day)
- **Closed**: Election ended, no voting

**How to use**:
1. Admin → Settings tab
2. Select status from dropdown
3. Click "Update Status"
4. Voting terminals respect this immediately

### Feature 3: Admin Reset

**What it does**: Start a fresh election without deleting your setup

**Options**:
1. **Reset ballots only** (default)
   - Clears all votes and ballots
   - Keeps voters (marks as unused)
   - Keeps positions and candidates
   - **Use for**: Testing, running same election again

2. **Reset + Delete Voters**
   - Clears votes, ballots, AND voters
   - Keeps structure
   - **Use for**: New voter list, same positions

3. **Reset + Delete Structure**
   - Clears everything
   - Full fresh start
   - **Use for**: Completely different election

**How to use**:
1. Admin → Settings tab
2. Scroll to "Danger Zone"
3. Check optional boxes if needed
4. Type "RESET" exactly
5. Click "Reset Election Data"
6. Confirm in popup

**Safety**: All resets are logged in audit trail

### Feature 4: Better Error Messages

**What it does**: Clear guidance instead of technical jargon

**Examples**:
- ❌ Before: "invalid_grant"
- ✅ After: "Sign-in failed. Check the email and password, make sure the account exists in Supabase Authentication, and confirm the email if confirmation is enabled."

---

## 🧪 Testing Before Election Day

### Test Scenario 1: Full Election Flow
1. Set status to "Open"
2. Create test voters: YTH-001, YTH-002, YTH-003
3. Add positions: President, Secretary
4. Add candidates to each
5. Create officer account
6. Sign in as officer
7. Cast 3 test ballots
8. Check Live Overview tab
9. Verify results are correct

### Test Scenario 2: Reset
1. (After test above)
2. Go to Settings → Reset
3. Leave both boxes unchecked
4. Type "RESET" and confirm
5. Verify:
   - Ballots cleared
   - Voters still exist (marked unused)
   - Positions still exist
6. Cast ballot again with same voter
7. ✅ Should work

### Test Scenario 3: Status Control
1. Set status to "Draft"
2. Try to cast ballot
3. ✅ Should be blocked
4. Set to "Open"
5. Cast ballot
6. ✅ Should work
7. Set to "Closed"
8. Try to cast ballot
9. ✅ Should be blocked

---

## 📋 Election Day Checklist

### One Day Before:
- [ ] All positions added
- [ ] All candidates added
- [ ] All voters generated/imported
- [ ] Test reset verified working
- [ ] Backup Supabase database
- [ ] Status set to "Draft"

### Morning Of:
- [ ] Test one ballot as officer
- [ ] Verify results appear correctly
- [ ] Reset election (ballots only)
- [ ] Verify audit log shows reset
- [ ] Change status to "Open"
- [ ] Test one real ballot
- [ ] Officers briefed on process

### During Election:
- [ ] Monitor Live Overview tab
- [ ] Check for issues in audit log
- [ ] Answer officer questions
- [ ] Keep backup admin access ready

### After Voting Ends:
- [ ] Change status to "Closed"
- [ ] Export results (JSON)
- [ ] Backup database again
- [ ] Review audit log
- [ ] Announce results

---

## 🆘 Common Issues & Fixes

| Problem | Fix |
|---------|-----|
| Can't sign in as admin | Check staff table has your user_id with role='admin' |
| 400 error on login | Account doesn't exist or isn't confirmed in Supabase Auth |
| Settings tab missing | Clear browser cache, ensure using updated admin.html |
| Reset button disabled | Must type "RESET" exactly (case-sensitive) |
| Title doesn't update | Check election_settings table exists, check browser console |
| Voting blocked | Check election status is "Open" in Settings tab |

---

## 📞 Quick Reference

### URLs:
- **Voting Terminal**: `https://your-site.netlify.app/index.html`
- **Admin Dashboard**: `https://your-site.netlify.app/admin.html`
- **Supabase Dashboard**: https://supabase.com/dashboard

### Default Sample Data:
- **Voters**: YTH-001, YTH-002, YTH-003, YTH-004
- **Positions**: President, Secretary General
- **Candidates**: A, B, C (President), D, E (Secretary)

### File Locations:
- **SQL Setup**: `SUPABASE_SETUP.sql`
- **Sample CSV**: `sample-officers.csv`
- **Full Guide**: `DEPLOYMENT_GUIDE.md`
- **Changes**: `CHANGES_SUMMARY.md`

---

## ✅ You're Ready!

Your election app is now:
- ✅ Secure (role-based access, audit logging)
- ✅ Customizable (title, status control)
- ✅ Resetable (admin can start fresh)
- ✅ User-friendly (clear error messages)
- ✅ Production-ready (tested and documented)

**Next Steps**:
1. Customize title for your election
2. Generate voter codes
3. Add your positions and candidates
4. Create officer accounts
5. Test everything
6. Set status to "Open" on election day
7. Monitor and manage from admin dashboard

Good luck with your election! 🎉
