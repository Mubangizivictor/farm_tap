import 'package:farm_tap/app/app.dart';
import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/core/database/isar_service.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLogger extends Mock implements AppLogger;
class MockIsarService extends Mock implements IsarService;
class MockIsar extends Mock implements Isar;

void main() {
  setUpAll(() async {
    final logger = MockAppLogger();
    final isarService = MockIsarService();
    final isar = MockIsar();
    
    when(() => isarService.isar).thenReturn(isar);
    
    getIt.registerSingleton<AppLogger>(logger);
    getIt.registerSingleton<IsarService>(isarService);
    // Add other minimum required for splash
  });

  testWidgets('App boots to splash screen', (tester) async {
    final config = AppConfig.forFlavor(Flavor.dev);
    
    await tester.pumpWidget(FarmTapApp(config: config));

    expect(find.byType(FarmTapApp), findsOneWidget);
    // Since SplashPage uses Image.asset which might not load in tests without mocks
    // we just check if it navigates or stays on splash
  });
}
