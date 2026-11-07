// FarmTap → Google Sheets, version 2 (paste ALL of this into Code.gs, replacing what is there).
// The FarmTap control panel sends Farms, Payments, Users and the Audit log here.
// Each goes to its own styled tab; every send replaces all rows, so a farm removed
// in the panel disappears from the sheet on the next send. Only requests carrying
// the secret word below are accepted.

const SECRET = 'CHANGE-ME-to-a-long-random-word';

// FarmTap colours.
const GREEN = '#1F6B45';
const GREEN_DARK = '#123F29';
const GREEN_SOFT = '#EEF6F1';
const GOLD = '#C9921B';
const INK = '#1B1F1C';
const MUTED = '#5F6B64';
const TAB_COLOURS = { Farms: GREEN, Payments: GOLD, Users: '#2F6FB3', 'Audit log': '#79827D' };
const TAB_ORDER = ['About', 'Farms', 'Payments', 'Users', 'Audit log'];

const FORMATS = {
  number: '#,##0',
  ugx: '"UGX "#,##0',
  date: 'd mmm yyyy',
  datetime: 'd mmm yyyy, h:mm am/pm',
};

// Words in a Status column and their colours (background, text).
const STATUS = [
  ['Paid', '#DDF2E5', '#14532D'],
  ['Received', '#DDF2E5', '#14532D'],
  ['Active', '#DDF2E5', '#14532D'],
  ['Account', '#DDF2E5', '#14532D'],
  ['Trial ended', '#FBE0DE', '#8A1C14'], // before "Trial": the first matching colour wins
  ['Trial', '#DCEBFB', '#1E3A8A'],
  ['Due in', '#FDF0D5', '#7A4B00'],
  ['Lapsed', '#FBE0DE', '#8A1C14'],
  ['Suspended', '#FBE0DE', '#8A1C14'],
  ['Rejected', '#FBE0DE', '#8A1C14'],
  ['Disabled', '#FBE0DE', '#8A1C14'],
  ['Void', '#ECEDEC', '#49524D'],
];

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(30000); // two sends at once take turns
  try {
    const body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    if (body.secret !== SECRET) return reply({ ok: false, error: 'wrong secret' });
    const book = SpreadsheetApp.getActiveSpreadsheet();
    book.setSpreadsheetTimeZone('Africa/Kampala');
    const done = [];
    const counts = [];
    const tabs = body.tabs || {};
    Object.keys(tabs).forEach(function (name) {
      const t = tabs[name];
      if (!t || !Array.isArray(t.headers) || !Array.isArray(t.rows)) return;
      writeTab(book, name, t);
      done.push(name + ' (' + t.rows.length + ')');
      counts.push([name, t.rows.length]);
    });
    writeAbout(book, body, counts);
    tidy(book);
    return reply({ ok: true, tabs: done });
  } catch (err) {
    return reply({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

function writeTab(book, name, t) {
  const sheet = book.getSheetByName(name) || book.insertSheet(name);
  const width = t.headers.length;
  const types = t.types || [];
  // Start clean: values, formats, colours, filters and old banding.
  if (sheet.getFilter()) sheet.getFilter().remove();
  sheet.getBandings().forEach(function (b) { b.remove(); });
  sheet.clear();
  sheet.clearConditionalFormatRules();

  const rows = t.rows.map(function (r) {
    const row = r.slice(0, width);
    while (row.length < width) row.push('');
    return row.map(function (v, i) { return cell(v, types[i]); });
  });
  const all = [t.headers].concat(rows);
  sheet.getRange(1, 1, all.length, width).setValues(all);

  // Header: FarmTap green, white bold text, taller row.
  sheet.getRange(1, 1, 1, width)
    .setBackground(GREEN).setFontColor('#FFFFFF').setFontWeight('bold')
    .setVerticalAlignment('middle').setWrap(true);
  sheet.setRowHeight(1, 36);
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(1);
  sheet.getRange(1, 1, all.length, width).setFontFamily('Roboto').setFontSize(10).setVerticalAlignment('middle');

  if (rows.length) {
    const body = sheet.getRange(2, 1, rows.length, width);
    body.setFontColor(INK);
    // Soft green stripes.
    const band = sheet.getRange(1, 1, all.length, width).applyRowBanding(SpreadsheetApp.BandingTheme.LIGHT_GREY, true, false);
    band.setHeaderRowColor(GREEN).setFirstRowColor('#FFFFFF').setSecondRowColor(GREEN_SOFT);
    // Number, money and date formats, right-aligned.
    types.forEach(function (ty, i) {
      const col = sheet.getRange(2, i + 1, rows.length, 1);
      if (FORMATS[ty]) col.setNumberFormat(FORMATS[ty]).setHorizontalAlignment('right');
      if (ty === 'status') col.setHorizontalAlignment('center').setFontWeight('bold');
    });
    // First column bold (farm, person, date).
    sheet.getRange(2, 1, rows.length, 1).setFontWeight('bold');
    // Status colours.
    const rules = [];
    types.forEach(function (ty, i) {
      if (ty !== 'status') return;
      const col = sheet.getRange(2, i + 1, rows.length, 1);
      STATUS.forEach(function (s) {
        rules.push(SpreadsheetApp.newConditionalFormatRule().whenTextStartsWith(s[0]).setBackground(s[1]).setFontColor(s[2]).setRanges([col]).build());
      });
    });
    sheet.setConditionalFormatRules(rules);
    sheet.getRange(1, 1, all.length, width).createFilter();
  } else {
    sheet.getRange(2, 1).setValue('Nothing yet').setFontColor(MUTED).setFontStyle('italic');
  }

  // Column widths: fit the text, within limits.
  sheet.autoResizeColumns(1, width);
  for (let c = 1; c <= width; c++) {
    const w = sheet.getColumnWidth(c);
    sheet.setColumnWidth(c, Math.max(90, Math.min(w + 24, 320)));
  }
  // Remove empty columns and rows past the data so the tab looks finished.
  const extraCols = sheet.getMaxColumns() - width;
  if (extraCols > 0) sheet.deleteColumns(width + 1, extraCols);
  const keepRows = Math.max(all.length, 2) + 5;
  const extraRows = sheet.getMaxRows() - keepRows;
  if (extraRows > 0) sheet.deleteRows(keepRows + 1, extraRows);

  sheet.setTabColor(TAB_COLOURS[name] || GREEN);
}

function writeAbout(book, body, counts) {
  const sheet = book.getSheetByName('About') || book.insertSheet('About', 0);
  sheet.getBandings().forEach(function (b) { b.remove(); });
  sheet.clear();
  sheet.setHiddenGridlines(true);
  sheet.setColumnWidth(1, 24);
  sheet.setColumnWidth(2, 230);
  sheet.setColumnWidth(3, 200);
  sheet.setColumnWidth(4, 24);

  // Title band.
  sheet.getRange('B2:C2').merge().setValue('FarmTap data').setFontSize(22).setFontWeight('bold').setFontColor('#FFFFFF').setBackground(GREEN_DARK).setVerticalAlignment('middle');
  sheet.setRowHeight(2, 48);
  sheet.getRange('B3:C3').merge().setValue('Copied from the FarmTap control panel. Every send replaces the other tabs, so add notes in a tab of your own.')
    .setFontColor('#FFFFFF').setBackground(GREEN).setWrap(true).setFontSize(10);
  sheet.setRowHeight(3, 36);

  let r = 5;
  sheet.getRange(r, 2).setValue('Last updated').setFontColor(MUTED);
  sheet.getRange(r, 3).setValue(new Date()).setNumberFormat(FORMATS.datetime).setFontWeight('bold');
  r++;
  sheet.getRange(r, 2).setValue('Sent by').setFontColor(MUTED);
  sheet.getRange(r, 3).setValue(String(body.by || '')).setFontWeight('bold');
  r += 2;

  const summary = Array.isArray(body.summary) ? body.summary : [];
  if (summary.length) {
    sheet.getRange(r, 2, 1, 2).setValues([['At a glance', '']]).setFontWeight('bold').setFontColor(GREEN).setFontSize(13);
    r++;
    summary.forEach(function (s) {
      sheet.getRange(r, 2).setValue(String(s[0])).setFontColor(INK);
      const v = sheet.getRange(r, 3).setValue(Number(s[1]) || 0).setFontWeight('bold').setFontSize(13).setHorizontalAlignment('right');
      v.setNumberFormat(FORMATS[s[2]] || FORMATS.number);
      sheet.getRange(r, 2, 1, 2).setBorder(null, null, true, null, null, null, '#D7DED9', SpreadsheetApp.BorderStyle.SOLID);
      r++;
    });
    r++;
  }

  sheet.getRange(r, 2, 1, 2).setValues([['Tabs', 'Rows']]).setFontWeight('bold').setFontColor(GREEN).setFontSize(13);
  r++;
  counts.forEach(function (c) {
    sheet.getRange(r, 2).setValue(c[0]);
    sheet.getRange(r, 3).setValue(c[1]).setNumberFormat(FORMATS.number).setHorizontalAlignment('right').setFontWeight('bold');
    sheet.getRange(r, 2, 1, 2).setBorder(null, null, true, null, null, null, '#D7DED9', SpreadsheetApp.BorderStyle.SOLID);
    r++;
  });
  sheet.getRange(1, 1, r, 4).setFontFamily('Roboto');
  sheet.setTabColor(GREEN_DARK);
}

// Tab order, and the empty "Sheet1" Google adds to a new sheet is removed.
function tidy(book) {
  const first = book.getSheetByName('Sheet1');
  if (first && first.getLastRow() === 0 && book.getSheets().length > 1) book.deleteSheet(first);
  TAB_ORDER.forEach(function (name, i) {
    const s = book.getSheetByName(name);
    if (s) {
      book.setActiveSheet(s);
      book.moveActiveSheet(i + 1);
    }
  });
  const about = book.getSheetByName('About');
  if (about) book.setActiveSheet(about);
}

// Dates come as "2026-11-07" or full ISO times; turn them into real date cells.
function cell(v, type) {
  if ((type === 'date' || type === 'datetime') && typeof v === 'string' && v) {
    const d = new Date(type === 'date' && v.length === 10 ? v + 'T12:00:00+03:00' : v);
    return isNaN(d.getTime()) ? v : d;
  }
  if ((type === 'number' || type === 'ugx') && v !== '' && v != null) {
    const n = Number(v);
    return isNaN(n) ? v : n;
  }
  return v == null ? '' : v;
}

// Opening the web app link in a browser shows this, so you can check it is live.
function doGet() {
  return reply({ ok: true, app: 'FarmTap Sheets', version: 2, ready: true });
}

function reply(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
