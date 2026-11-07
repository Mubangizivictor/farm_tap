// FarmTap → Google Sheets (paste ALL of this into Code.gs, replacing what is there).
// The FarmTap control panel sends Farms, Payments, Users and the Audit log here.
// Each one goes to its own tab. Old rows are replaced, so the sheet always shows
// the latest copy. Only requests that carry the secret word below are accepted.

const SECRET = 'CHANGE-ME-to-a-long-random-word';

function doPost(e) {
  try {
    const body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    if (body.secret !== SECRET) return reply({ ok: false, error: 'wrong secret' });
    const book = SpreadsheetApp.getActiveSpreadsheet();
    const done = [];
    const tabs = body.tabs || {};
    Object.keys(tabs).forEach(function (name) {
      const t = tabs[name];
      if (!t || !Array.isArray(t.headers) || !Array.isArray(t.rows)) return;
      const sheet = book.getSheetByName(name) || book.insertSheet(name);
      sheet.clearContents();
      const width = t.headers.length;
      const rows = [t.headers].concat(t.rows.map(function (r) {
        const row = r.slice(0, width);
        while (row.length < width) row.push('');
        return row;
      }));
      sheet.getRange(1, 1, rows.length, width).setValues(rows);
      sheet.getRange(1, 1, 1, width).setFontWeight('bold').setBackground('#E3F1E8');
      sheet.setFrozenRows(1);
      done.push(name + ' (' + t.rows.length + ')');
    });
    const info = book.getSheetByName('About') || book.insertSheet('About', 0);
    info.getRange('A1:B3').setValues([
      ['FarmTap data', 'Filled by the FarmTap control panel. Do not type in the other tabs: they are replaced on every send.'],
      ['Last updated', new Date()],
      ['Sent by', String(body.by || '')],
    ]);
    info.getRange('A1:A3').setFontWeight('bold');
    return reply({ ok: true, tabs: done });
  } catch (err) {
    return reply({ ok: false, error: String(err) });
  }
}

// Opening the web app link in a browser shows this, so you can check it is live.
function doGet() {
  return reply({ ok: true, app: 'FarmTap Sheets', ready: true });
}

function reply(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
