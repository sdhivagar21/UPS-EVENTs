# UPS Events

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
