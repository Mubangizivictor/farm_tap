// Audit (Step 1): the screens the first UI pass built, before the rebuild.
// A01 is left out: the stub's 2 s timer calls context.go without a router.
// Deleted when Step 2 rebuilds section A.
import 'package:farm_tap/presentation/auth/pages/sign_in_page.dart';

import '../helpers/screen_golden.dart';

void main() {
  screenGoldens('A02_sign_in', (_) => const SignInPage());
}
