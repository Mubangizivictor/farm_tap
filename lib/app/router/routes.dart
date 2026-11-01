// Every route path (docs/design/ROUTES.md is the table of all 102 screens).
abstract final class AppRoutes {
  // A — launch and account
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const emailSignIn = '/sign-in/email';
  static const signUp = '/sign-in/email/sign-up';
  static const forgotPassword = '/sign-in/email/forgot';
  static const checkEmail = '/verify';
  static const farmPicker = '/farms';

  // B — onboarding
  static const setup = '/setup';
  static const setupLanguage = '/setup/language';
  static const setupSector = '/setup/sector';
  static const setupWaitlistDone = '/setup/waitlist-done';
  static const setupDairyType = '/setup/dairy-type';
  static const setupFarm = '/setup/farm';
  static const setupContacts = '/setup/contacts';
  static const setupRole = '/setup/role';
  static const setupStaff = '/setup/staff';
  static const setupDone = '/setup/done';

  // C — staff unlock
  static const unlock = '/unlock';
  static const unlockNumber = '/unlock/number';
  static const unlockPin = '/unlock/pin';

  // Shell branches (tabs / rail / sidebar sections)
  static const home = '/home';
  static const herd = '/herd';
  static const milk = '/milk';
  static const health = '/health';
  static const more = '/more';
  static const collect = '/collect';
  static const farmers = '/farmers';
  static const pay = '/pay';
  static const feeding = '/feeding';
  static const breeding = '/breeding';
  static const workers = '/workers';
  static const money = '/money';
  static const reports = '/reports';
  static const settings = '/settings';

  // Dev
  static const uiGallery = '/dev/gallery';

  /// Routes reachable without signing in.
  static bool isPublic(String location) =>
      location == splash || location.startsWith(signIn) || location.startsWith('/dev');
}
