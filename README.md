# UPS Events

## Adding events from the admin page

Go to **upsevents.in/admin**, sign in, and click **+ New event**. Fill in the details, add photos (they're resized in the browser) and films, then click **Save**. With **Show on the website** ticked, the event appears on the site straight away, next to the events built into `index.html`.

The events built into `index.html` are listed there too, under **Original events on the website**. Editing one saves your version as a database row with `builtin` set and the same slug. The site shows that row instead of the original, or hides the event when **Show on the website** is unticked. **Reset to original** deletes the row and brings the original back.

Events, photos and films are stored in a Supabase project. Setting one up from scratch:

1. Create a project at [supabase.com](https://supabase.com) (region: South Asia, Mumbai).
2. Open **SQL Editor**, paste [`admin/setup.sql`](admin/setup.sql) and click **Run**. This creates the `events` and `admins` tables, the public `media` bucket and the access rules.
3. Under **Authentication → Sign In / Providers**, turn off **Allow new users to sign up**.
4. Under **Authentication → Users**, click **Add user** and create the admin's email and password. Then add the same email as a row in the `admins` table (**Table Editor → admins**). Only emails in that table can change anything.
5. Copy the **Project URL** and the **publishable** (anon) key from **Project Settings → API Keys**. Paste them into `SITE.supabase` in `index.html` and `CONFIG` in `admin/index.html`. Never use the secret (`service_role`) key in either file.

To add another admin later, repeat step 4. To remove one, delete their row from `admins`.

The free plan pauses a project after about a week with no activity. Visits to the site normally keep it awake. If it does pause, the site still works and shows only the built-in events until you restore the project from the Supabase dashboard.

## Vendor registrations in a Google Sheet

The **Vendors** section (`#vendors`) has its own form, kept separate from the client enquiry form. To collect every vendor submission as a row in a Google Sheet:

1. Create a Google Sheet. Rename the first tab to `Vendors`.
2. In the sheet, open **Extensions → Apps Script**, replace the code with the script below, and save.
3. Click **Deploy → New deployment**, choose **Web app**, set *Execute as* to **Me** and *Who has access* to **Anyone**, then click **Deploy** and copy the web app URL.
4. In `index.html`, paste that URL into `SITE.vendorSheet`.

```js
const COLUMNS = ['submitted', 'name', 'business', 'phone', 'email', 'category', 'area',
  'stall', 'power', 'events', 'links', 'licence', 'products'];

function doPost(e) {
  const sheet = SpreadsheetApp.getActive().getSheetByName('Vendors');
  if (sheet.getLastRow() === 0) sheet.appendRow(COLUMNS);
  sheet.appendRow(COLUMNS.map(k => e.parameter[k] || ''));
  return ContentService.createTextOutput('ok');
}
```

If `SITE.vendorSheet` is empty, the vendor form sends through WhatsApp or email instead, using `SITE.contact`. Those messages are headed "Vendor registration" so they stand apart from event enquiries.
