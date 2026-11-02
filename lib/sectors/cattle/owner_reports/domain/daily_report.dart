// L04 daily WhatsApp report: every line is read from the same records the
// other screens use (milk, treatments, feed, attendance, money).
import 'package:farm_tap/core/error/result.dart';

class DailyReport {
  const new({
    required this.farmName,
    required this.day,
    required this.milkLitres,
    required this.milkTrendPercent,
    required this.notForSaleLitres,
    required this.notForSaleAnimals,
    required this.treatmentsToday,
    required this.dairyMealUsed,
    required this.workersIn,
    required this.workersTotal,
    required this.alerts,
    required this.moneyIn,
    required this.moneyOut,
  });

  final String farmName;
  final DateTime day;
  final double milkLitres;
  final int milkTrendPercent;
  final double notForSaleLitres;
  final String notForSaleAnimals;
  final int treatmentsToday;
  final double dairyMealUsed;
  final int workersIn;
  final int workersTotal;

  /// Low feed: (feed, bags left).
  final List<(String, int)> alerts;

  /// This month to date (only sent when Include money is on).
  final int moneyIn;
  final int moneyOut;
}

class DailyReportSettings {
  const new({required this.phone, required this.sendMinutes, required this.includeMoney, required this.smsFallback});

  /// The owner's WhatsApp number (from farm contacts).
  final String phone;

  /// Minutes after midnight (7:00 pm = 1140).
  final int sendMinutes;
  final bool includeMoney;
  final bool smsFallback;

  DailyReportSettings copyWith({int? sendMinutes, bool? includeMoney, bool? smsFallback}) => DailyReportSettings(
    phone: phone,
    sendMinutes: sendMinutes ?? this.sendMinutes,
    includeMoney: includeMoney ?? this.includeMoney,
    smsFallback: smsFallback ?? this.smsFallback,
  );
}

abstract interface class DailyReportRepository {
  Future<Result<DailyReport>> today();
  Future<Result<DailyReportSettings>> settings();
  Future<Result<void>> saveSettings(DailyReportSettings settings);
}
