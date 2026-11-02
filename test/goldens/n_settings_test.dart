// Section N — settings (N01 so far), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/n_settings_test.dart
import 'package:farm_tap/core/settings/presentation/pages/more_page.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  screenGoldens(
    'N01_more_menu',
    (_) => inShell(
      MorePage(
        name: 'Muhwezi Robert',
        role: 'Owner',
        email: 'muhwezi.robert@gmail.com',
        trialDaysLeft: demoTrialDaysLeft(),
        onOpen: (_) {},
      ),
      current: '/more',
    ),
  );
}
