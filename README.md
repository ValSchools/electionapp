# Youth Election 2025, complete Netlify bundle

## Deploy the website
1. Upload this whole folder to Netlify Drop: https://app.netlify.com/drop
2. Officers use: `https://YOUR-SITE.netlify.app/`
3. Admins use: `https://YOUR-SITE.netlify.app/admin.html`
4. Android users can use the in-app Install app button.

## Deploy the secure admin function
The Edge Function must be deployed in Supabase, not served by Netlify.

1. Supabase Dashboard → Edge Functions → New Function → `admin-create-users`.
2. Paste `supabase/functions/admin-create-users/index.ts` and deploy.
3. Add `SUPABASE_SERVICE_ROLE_KEY` as an Edge Function secret only.
4. The admin page calls:
   `https://jfumdivbeqqbvdzqkdrf.supabase.co/functions/v1/admin-create-users`

Never put the service role key in this folder, Netlify, GitHub, or the browser.

## Create the first admin
Create the account in Supabase Authentication → Users, then run:

```sql
insert into staff (user_id, role)
select id, 'admin'
from auth.users
where email = 'your-email@example.com'
on conflict (user_id) do update set role = 'admin';
```

## Officer CSV
```csv
email,password,role
officer1@example.com,TempPass123!,operator
officer2@example.com,TempPass456!,operator
```

The admin page supports manual creation, CSV import, operator/admin roles, and live statistics.
