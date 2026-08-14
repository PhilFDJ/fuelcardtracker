# Fuel Card Tracker

A single-page fuel card tracker. Logs the weekly card rate, works out whether to
fill up before Sunday or wait for Monday, and tracks fill-ups, savings against
the pump price, and what's owed on the weekly billing cycle.

Runs as one static HTML file on GitHub Pages, with accounts and storage in
Supabase.

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app. This is the only file that needs to be live. |
| `supabase-setup.sql` | Database tables and security policies. Run once. |
| `fuel-card-import.json` | Phil's data from FUEL_CARD_TRACKING.xlsx — 13 weekly rates, 25 fill-ups, 2 service charges. Import it from inside the app. Keep this off the public repo. |

## Setup

1. **Create a Supabase project** at supabase.com. London region.
2. **Run the SQL.** SQL Editor → New query → paste all of `supabase-setup.sql` → Run.
   The result table at the bottom must show `rls_enabled = true` on all four rows.
   That's what keeps one account's data away from another's. If any row says
   false, stop and fix it before going live.
3. **Get your keys.** Settings → API. Copy the *Project URL* and the *anon public* key.
   Never copy the `service_role` key — it bypasses all security and must not go
   anywhere near a public repo.
4. **Paste them into `index.html`**, near the top of the `<script>` block:
   ```js
   var SUPABASE_URL      = "https://xxxxx.supabase.co";
   var SUPABASE_ANON_KEY = "eyJhbGci...";
   ```
5. **Set the Site URL.** Supabase → Authentication → URL Configuration →
   `https://philfdj.github.io/fuelcardtracker/`. Without this, confirmation and
   password-reset emails point at the wrong place.
6. **Deploy.** Upload `index.html` to the repo root. GitHub → Settings → Pages →
   Deploy from a branch → `main` → `/ (root)`.
7. **Register**, confirm the email, sign in, then Balance tab → Import a backup →
   pick `fuel-card-import.json`.

## Before letting anyone else register

- Register a second account with a different email and confirm it shows an
  **empty** app, not your data. Two-minute check, proves the isolation works.
- Read the privacy notice on the sign-in screen and reword it to something you're
  happy to stand behind. It's your name on it.
- Delete `fuel-card-import.json` from the public repo once imported.

## How the numbers work

- Card rates are **£ per litre ex VAT**. VAT (default 20%, adjustable) is added
  on top to get what you actually pay.
- Rates run **Monday to Sunday**, but arrive on the Friday before — which is what
  the fill-now-or-wait panel is for.
- Billing is **weekly in arrears**: this week's payment covers last Mon–Sun.
- Saving per fill = pump price × litres − card cost inc VAT. Service charges are
  subtracted from the running total.

## Known limits

- Supabase's free tier pauses a project after about a week of no activity, and
  rate-limits outgoing email to a handful an hour. Fine at this scale.
- No shared/admin view — each account sees only its own data.
