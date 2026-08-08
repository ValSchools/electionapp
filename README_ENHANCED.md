# 🗳️ Youth Election App - Enhanced Version

> A production-ready, secure voting application with admin reset, customizable branding, and comprehensive audit logging.

## 🎯 What's Inside

This is a **complete youth election management system** with:
- 🖥️ **Voting Terminal** - Clean interface for voters to cast ballots
- 👨‍💼 **Admin Dashboard** - Full control panel for election management
- 🔐 **Role-Based Access** - Admin, operator, and voter roles
- 📊 **Live Results** - Real-time tally updates
- 🎨 **Customizable** - Change title, control status, manage everything
- 🔄 **Reset Capability** - Start fresh elections with one click
- 📝 **Audit Trail** - Track all admin actions

---

## ✨ New Features (Enhanced Version)

### 1. Admin Reset Functionality
- **Database-level reset** enforced through secure functions
- Choose what to reset:
  - Ballots only (keep voters and structure)
  - Ballots + voters
  - Complete reset (start from scratch)
- Requires confirmation to prevent accidents
- **All resets logged in audit trail**

### 2. Customizable Application Title
- Change "Youth Election Terminal" to your custom name
- Updates everywhere instantly
- Perfect for: "2025 Student Council Election", "Youth Parliament", etc.

### 3. Election Status Control
- **Three modes**:
  - **Draft**: Setup phase (voting disabled)
  - **Open**: Election active (voting enabled)
  - **Closed**: Election ended (voting disabled)
- Prevents votes before/after election period

### 4. Better Error Messages
- No more cryptic "400" or "invalid_grant" errors
- Clear guidance: "Check email, verify account exists, confirm email"
- User-friendly explanations

### 5. Enhanced Security
- Row-level locking prevents concurrent ballot casting
- Audit logging for accountability
- Role-based access control (no email allowlists)
- Transaction safety with proper constraints

---

## 🚀 Quick Start

### Prerequisites
- Supabase account (free tier works!)
- Netlify account (free tier works!)
- 10 minutes

### 3-Step Setup

**Step 1**: Run `SUPABASE_SETUP.sql` in your Supabase SQL Editor

**Step 2**: Your credentials are already configured! ✅
- URL: `https://jfumdivbeqqbvdzqkdrf.supabase.co`
- Already set in both `index.html` and `admin.html`

**Step 3**: Deploy to Netlify (drag & drop your folder)

📖 **Detailed Instructions**: See `READY_TO_DEPLOY.md`

---

## 📁 Project Structure

```
voting-app/
├── index.html              # Voting terminal (officers & voters)
├── admin.html              # Admin dashboard (6 tabs)
├── SUPABASE_SETUP.sql      # Complete database setup
├── sw.js                   # Service worker (PWA)
├── manifest.webmanifest    # PWA manifest
├── icon-192.png            # App icon (small)
├── icon-512.png            # App icon (large)
├── netlify.toml            # Netlify config
├── sample-officers.csv     # Example CSV format
│
├── READY_TO_DEPLOY.md      # ⚡ Start here!
├── QUICK_START.md          # Fast setup guide
├── DEPLOYMENT_GUIDE.md     # Complete instructions
├── CHANGES_SUMMARY.md      # What's new
└── README_ENHANCED.md      # This file
```

---

## 🎮 How to Use

### For Administrators

**Access**: `https://your-site.netlify.app/admin.html`

**Features**:
1. **📊 Live Overview** - Monitor turnout and results in real-time
2. **🎟️ Voter Codes** - Generate and manage voter IDs
3. **✏️ Contestants** - Add positions and candidates
4. **👥 Officers** - Create polling officer accounts
5. **⚡ Export** - Download results as JSON
6. **⚙️ Settings** (NEW!)
   - Change application title
   - Control election status (Draft/Open/Closed)
   - Reset election data with options

### For Polling Officers

**Access**: `https://your-site.netlify.app/index.html`

**Process**:
1. Sign in with officer credentials
2. Voter arrives with voter ID code
3. Enter code and verify
4. Hand device to voter
5. Voter selects candidates
6. Voter reviews and casts ballot
7. Click "Next Voter" to continue

### For Voters

**Process**:
1. Officer verifies your ID
2. Select one candidate per position (or Abstain)
3. Click "Next" through all positions
4. Review your ballot carefully
5. Click "Cast Official Ballot"
6. Hand device back to officer

---

## 🔧 Configuration

### Already Configured ✅
Your Supabase credentials are already in place:
- `index.html` line 149
- `admin.html` line 471

### What You Still Need to Do

1. **Create Admin Account**:
   - Supabase → Authentication → Users → Add user
   - Enter email + password
   - Toggle "Auto Confirm User" ON

2. **Make User Admin**:
   - Update email in `SUPABASE_SETUP.sql` (section 13)
   - Or run this SQL:
     ```sql
     INSERT INTO staff (user_id, role)
     SELECT id, 'admin'
     FROM auth.users
     WHERE email = 'your-email@example.com'
     ON CONFLICT (user_id) DO UPDATE SET role = 'admin';
     ```

3. **Customize**:
   - Admin → Settings → Change title to your election name
   - Set status to "Draft" during setup

---

## 📊 Database Schema

### Tables
- `staff` - Admin and officer accounts with roles
- `registered_voters` - Voter IDs and voting status
- `positions` - Contest positions (President, Secretary, etc.)
- `candidates` - Candidates per position
- `ballots` - Cast ballots (linked to voters)
- `votes` - Individual votes per position
- `election_settings` ⭐ NEW - Title and status
- `audit_log` ⭐ NEW - Admin action history

### RPC Functions
- `my_role()` - Get current user's role
- `election_ballot()` - Get positions and candidates
- `verify_voter()` - Check voter eligibility (checks status)
- `cast_ballot()` - Record votes (locks voter, checks status)
- `election_results()` - Live tally
- `election_settings()` ⭐ NEW - Get title and status
- `update_election_title()` ⭐ NEW - Admin only
- `update_election_status()` ⭐ NEW - Admin only
- `reset_election()` ⭐ NEW - Admin only, audit logged

---

## 🔒 Security Features

1. **Role-Based Access Control**
   - Admin: Full access
   - Operator: Can cast ballots only
   - Anon: Can view results only

2. **Row-Level Security**
   - Enabled on all tables
   - Policies enforce permissions

3. **Transaction Safety**
   - FOR UPDATE locks prevent race conditions
   - Can't cast two ballots with same voter ID

4. **Audit Logging**
   - All admin actions logged
   - Includes user email, action, details, timestamp
   - Stored in `audit_log` table

5. **SECURITY DEFINER Functions**
   - All RPC functions check roles
   - No client-side security decisions

---

## 🧪 Testing Guide

### Test 1: Full Election Flow
```
1. Set status to "Open"
2. Create test voter: YTH-TEST
3. Add position: "Test President"
4. Add candidates: "Candidate A", "Candidate B"
5. Sign in as officer
6. Cast ballot with YTH-TEST
7. Check results in Live Overview
✅ Results should show votes
```

### Test 2: Reset Functionality
```
1. (After test above)
2. Admin → Settings → Reset
3. Leave checkboxes unchecked
4. Type "RESET" and confirm
✅ Ballots cleared, voter/structure preserved
5. Cast ballot again with YTH-TEST
✅ Should work (voter marked unused)
```

### Test 3: Status Control
```
1. Admin → Settings → Status = "Draft"
2. Try to cast ballot
✅ Should be blocked
3. Change status to "Open"
4. Try again
✅ Should work
```

### Test 4: Title Customization
```
1. Admin → Settings
2. Change title to "Test Election 2025"
3. Save
✅ Check admin header
✅ Check voting terminal header
✅ Check browser tab title
```

---

## 📋 Election Day Checklist

### Pre-Election
- [ ] All positions added
- [ ] All candidates added
- [ ] Voter codes generated/distributed
- [ ] Officer accounts created
- [ ] Test election run and reset
- [ ] Database backed up
- [ ] Status set to "Draft"

### Election Morning
- [ ] Change status to "Open"
- [ ] Test one ballot
- [ ] Verify results appear
- [ ] Brief officers
- [ ] Have admin credentials ready

### During Election
- [ ] Monitor Live Overview
- [ ] Support officers
- [ ] Check audit log periodically

### Post-Election
- [ ] Change status to "Closed"
- [ ] Export results
- [ ] Backup database
- [ ] Review audit log
- [ ] Announce results

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **400 on login** | Account doesn't exist or isn't confirmed |
| **"Admin role required"** | Run SQL to set role='admin' for your user |
| **Settings tab missing** | Clear cache, ensure using updated admin.html |
| **Reset disabled** | Must type "RESET" exactly (caps) |
| **"Election is draft"** | Admin → Settings → Set to "Open" |
| **Title won't change** | Check browser console, verify table exists |

---

## 📖 Documentation

- **⚡ Quick Start**: `QUICK_START.md` - 5-minute setup
- **📘 Full Guide**: `DEPLOYMENT_GUIDE.md` - Complete instructions
- **📝 Changes**: `CHANGES_SUMMARY.md` - What's new
- **✅ Deployment**: `READY_TO_DEPLOY.md` - Launch checklist

---

## 🎓 Advanced Topics

### Audit Log Query
View all admin actions:
```sql
SELECT * FROM audit_log ORDER BY created_at DESC;
```

### Add More Admins
```sql
INSERT INTO staff (user_id, role)
SELECT id, 'admin'
FROM auth.users
WHERE email = 'second-admin@example.com'
ON CONFLICT (user_id) DO UPDATE SET role = 'admin';
```

### Check Election Settings
```sql
SELECT * FROM election_settings;
```

### Reset Election Audit
See what was deleted in last reset:
```sql
SELECT * FROM audit_log 
WHERE action = 'reset_election' 
ORDER BY created_at DESC 
LIMIT 1;
```

---

## 🚀 Deployment Options

### Netlify (Recommended)
- Drag & drop deployment
- Free SSL certificate
- CDN included
- Custom domain support

### Other Options
- GitHub Pages
- Vercel
- Any static hosting
- Just upload all files

---

## 💡 Future Enhancements

Ideas for extending the app:
- Email notifications on admin actions
- QR code voter check-in
- Multi-language support
- Advanced analytics dashboard
- Scheduled status changes
- Multi-election support
- Voter registration form
- Results embeds for websites

---

## 📜 License & Credits

This is an enhanced version of the Youth Election app with:
- Admin reset functionality
- Customizable title
- Election status control
- Audit logging
- Security enhancements

Built with:
- Supabase (backend & auth)
- Vanilla JavaScript (no frameworks!)
- Modern CSS (gradients, glass effects)
- PWA capabilities

---

## 🆘 Support

**Your Supabase Project**: `jfumdivbeqqbvdzqkdrf`

**Quick Links**:
- Supabase Dashboard: https://supabase.com/dashboard/project/jfumdivbeqqbvdzqkdrf
- Supabase Docs: https://supabase.com/docs
- Netlify: https://app.netlify.com

**Common Commands**:
```bash
# Deploy with Netlify CLI
netlify deploy --prod

# Check Supabase logs
# (Use dashboard: Logs section)

# View audit trail
# (Supabase: Table Editor → audit_log)
```

---

## ✅ Ready to Launch?

1. ✅ Your Supabase credentials are configured
2. ✅ Enhanced features are built-in
3. ✅ Security is production-ready
4. ✅ Documentation is complete

**Next Step**: Open `READY_TO_DEPLOY.md` and follow the checklist!

---

**Questions?** Check the documentation files or review the audit_log table for troubleshooting.

**Good luck with your election!** 🗳️✨
