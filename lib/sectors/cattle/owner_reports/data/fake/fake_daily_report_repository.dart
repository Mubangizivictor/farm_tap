import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/domain/daily_report.dart';

/// Builds L04 from the shared repositories; only the settings are its own.
class FakeDailyReportRepository implements DailyReportRepository {
  new({
    required this.clock,
    required this.farmName,
    required this.home,
    required this.milk,
    required this.treatments,
    required this.feed,
    required this.money,
    this.journal,
    this.defaultPhone,
    bool withSamples = true,
  }) : _settings = DailyReportSettings(
         phone: withSamples ? '+256 772 451 908' : '',
         sendMinutes: 19 * 60,
         includeMoney: false,
         smsFallback: true,
       );

  final Clock clock;
  final String Function() farmName;
  final HomeRepository home;
  final MilkRepository milk;
  final TreatmentRepository treatments;
  final FeedRepository feed;
  final FarmMoneyRepository money;

  /// Keeps the settings with the farm's records (they sync to its phones).
  final RecordJournal? journal;

  /// The farm's WhatsApp number from onboarding, until one is set here.
  final String Function()? defaultPhone;
  DailyReportSettings _settings;

  static const _collection = 'settings';
  static const _id = 'dailyReport';

  @override
  Future<Result<DailyReport>> today() async {
    final now = clock.now();
    final day = DateTime(now.year, now.month, now.day);
    final summary = (await home.summary()).data;
    final notForSale = ((await milk.use()).data ?? const <MilkUseLine>[])
        .where((l) => l.kind == MilkUseKind.notForSale)
        .firstOrNull;
    final given = ((await treatments.treatments()).data ?? const [])
        .where((t) => !t.given.isBefore(day) && t.given.isBefore(day.add(const Duration(days: 1))))
        .length;
    final alerts = [
      for (final a in (await home.attention()).data ?? const <Attention>[])
        if (a is StockLow) (a.item, a.bagsLeft),
    ];
    final month = (await money.month()).data;
    return Result.success(
      DailyReport(
        farmName: farmName(),
        day: day,
        milkLitres: summary?.milkToday ?? 0,
        milkTrendPercent: summary?.milkTrendPercent ?? 0,
        notForSaleLitres: notForSale?.litres ?? 0,
        notForSaleAnimals: notForSale?.detail ?? '',
        treatmentsToday: given,
        dairyMealUsed: (await feed.usedOn(day, FeedKind.dairyMeal)).data ?? 0,
        workersIn: summary?.workersIn ?? 0,
        workersTotal: summary?.workersTotal ?? 0,
        alerts: alerts,
        moneyIn: month?.income ?? 0,
        moneyOut: month?.totalExpenses ?? 0,
      ),
    );
  }

  @override
  Future<Result<DailyReportSettings>> settings() async {
    var base = _settings;
    final fallbackPhone = defaultPhone?.call() ?? '';
    if (base.phone.isEmpty && fallbackPhone.isNotEmpty) base = base.copyWith(phone: fallbackPhone);
    final saved = await journal?.store.get(_collection, _id);
    if (saved == null || saved.isDeleted) return Result.success(base);
    return Result.success(DailyReportSettings.fromJson(saved.body, base));
  }

  @override
  Future<Result<void>> saveSettings(DailyReportSettings settings) async {
    _settings = settings;
    await journal?.put(_collection, _id, settings.toJson());
    return const Result.success(null);
  }
}
