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

  /// A07 opening the remembered (or only) farm by itself: after the splash
  /// and after signing in (decision 0015).
  static const farmPickerAuto = '/farms?auto=1';

  // B — onboarding
  static const setup = '/setup';
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
  static const homeAlerts = '/home/alerts';
  static const herd = '/herd';
  static const herdAdd = '/herd/add';
  static const herdScan = '/herd/scan';
  static const herdCount = '/herd/count';
  static const herdLabels = '/herd/labels';
  static String herdAnimal(String id) => '/herd/$id';
  static const milk = '/milk';
  static const milkRecord = '/milk/record';
  static const milkTotal = '/milk/herd-total';
  static const milkUse = '/milk/use';
  static const milkSales = '/milk/sales';
  static const milkTrends = '/milk/trends';
  static String milkCow(String cowId, {bool notForSale = false}) => '/milk/record/$cowId${notForSale ? '?nfs=1' : ''}';
  static const health = '/health';
  static const healthTreatment = '/health/treatment';
  static const healthDrugs = '/health/drugs';
  static const healthSchedule = '/health/schedule';
  static const healthWithdrawal = '/health/withdrawal';
  static const more = '/more';
  static const collect = '/collect';
  static const farmers = '/farmers';
  static const pay = '/pay';
  static const centreReconcile = '/home/reconcile';
  static String collectFarmer(String farmerId) => '/collect/$farmerId';
  static String collectSaved(String deliveryId) => '/collect?saved=$deliveryId';
  static String centreFarmer(String farmerId) => '/farmers/$farmerId';
  static const payFarmers = '/pay/sheet';
  static const paySms = '/pay/sms';
  static const feeding = '/feeding';
  static const feedingRecord = '/feeding/record';
  static const breeding = '/breeding';
  static const workers = '/workers';
  static const workersAttendance = '/workers/attendance';
  static const workersTasks = '/workers/tasks';
  static const workersWages = '/workers/wages';
  static const workersAdd = '/workers/add';
  static String worker(String staffId) => '/workers/$staffId';
  static String workerEdit(String staffId) => '/workers/$staffId/edit';
  static String workerCard(String staffId) => '/workers/$staffId/card';
  static const money = '/money';
  static const moneyExpense = '/money/expense';
  static const reports = '/reports';
  static const reportsWhatsapp = '/reports/whatsapp';
  static const settings = '/settings';
  static const settingsSubscription = '/settings/subscription';
  static const settingsHelp = '/settings/help';

  // Dev
  static const uiGallery = '/dev/gallery';

  /// Routes reachable without signing in.
  static bool isPublic(String location) =>
      location == splash || location.startsWith(signIn) || location.startsWith('/dev');
}
