// The app's display formats (AGENTS.md section 4): money "UGX 70,000",
// litres "42.5 L", dates "Thu 12 Nov", times "6:52 am".
import 'package:intl/intl.dart';

class FarmTapFormat {
  new(this.locale);

  /// BCP-47 tag, e.g. Localizations.localeOf(context).toLanguageTag().
  final String locale;

  // Runyankore has no CLDR data yet: fall back to English patterns.
  String get _l => DateFormat.localeExists(locale) ? locale : 'en';

  String money(num ugx) => 'UGX ${NumberFormat.decimalPattern(_l).format(ugx.round())}';

  /// "UGX 18.4M" for big totals on cards.
  String moneyShort(num ugx) => 'UGX ${NumberFormat.compact(locale: _l).format(ugx)}';

  /// "42.5" (one decimal, none for whole numbers when [trim]).
  String litresValue(num litres, {bool trim = true}) {
    if (trim && litres == litres.roundToDouble()) return NumberFormat.decimalPattern(_l).format(litres);
    return NumberFormat('#,##0.0', _l).format(litres);
  }

  /// "42.5 L".
  String litres(num litres) => '${litresValue(litres, trim: false)} L';

  /// "561k" (no currency) for tight list columns.
  String compact(num n) => NumberFormat.compact(locale: _l).format(n).toLowerCase();

  /// "1–15 Nov" (same month) or "28 Oct – 3 Nov".
  String period(DateTime a, DateTime b) => a.month == b.month && a.year == b.year
      ? '${a.day}–${DateFormat('d MMM', _l).format(b)}'
      : '${dayMonth(a)} – ${dayMonth(b)}';

  String count(num n) => NumberFormat.decimalPattern(_l).format(n);

  /// "Thu 12 Nov".
  String day(DateTime d) => DateFormat('EEE d MMM', _l).format(d);

  /// "Saturday 7 Nov".
  String longDay(DateTime d) => DateFormat('EEEE d MMM', _l).format(d);

  /// "13 Nov".
  String dayMonth(DateTime d) => DateFormat('d MMM', _l).format(d);

  /// "Oct".
  String monthShort(DateTime d) => DateFormat('MMM', _l).format(d);

  /// "Friday".
  String weekday(DateTime d) => DateFormat('EEEE', _l).format(d);

  /// "Sun".
  String weekdayShort(DateTime d) => DateFormat('EEE', _l).format(d);

  /// "6:52 am".
  String time(DateTime d) => DateFormat('h:mm a', _l).format(d).toLowerCase();

  /// "7:42" (24 h, used in audit lines).
  String clock24(DateTime d) => DateFormat('H:mm', _l).format(d);
}
