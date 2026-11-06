// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FarmTap';

  @override
  String get signIn => 'Sign in';

  @override
  String get phone => 'Phone number';

  @override
  String get pin => 'PIN';

  @override
  String get tapCard => 'Tap card';

  @override
  String get herd => 'Herd';

  @override
  String get milk => 'Milk';

  @override
  String get health => 'Health';

  @override
  String get more => 'More';

  @override
  String get addAnimal => 'Add Animal';

  @override
  String get tagNumber => 'Tag Number';

  @override
  String get name => 'Name';

  @override
  String get sex => 'Sex';

  @override
  String get breed => 'Breed';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get correct => 'Correct?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get searchHint => 'Search animals, farmers, records';

  @override
  String get allRecordsSynced => 'All records synced';

  @override
  String recordsWaiting(int count) {
    return '$count waiting to sync';
  }

  @override
  String get syncFailedShort => 'Sync failed';

  @override
  String get notifications => 'Notifications';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get undo => 'Undo';

  @override
  String get tryAgain => 'Try again';

  @override
  String get payNow => 'Pay now';

  @override
  String trialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Free trial: $_temp0 left';
  }

  @override
  String trialDaysLeftShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Free trial · $_temp0 left';
  }

  @override
  String get trialThenPrice =>
      'Then UGX 70,000 a month. Pay anytime with Mobile Money.';

  @override
  String get trialUpgradeLine => 'Upgrade · UGX 70,000/mo';

  @override
  String get offlineBannerTitle => 'You are offline';

  @override
  String get offlineBannerBody =>
      'Records are saved on this phone and will sync when you are online.';

  @override
  String get emptyDefaultTitle => 'Nothing here yet';

  @override
  String get errorDefaultTitle => 'Something went wrong';

  @override
  String get errorDefaultBody => 'Your data on this phone is safe.';

  @override
  String get continueLabel => 'Continue';

  @override
  String stepOfTotal(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get switchFarm => 'Switch farm';

  @override
  String get keypadBackspace => 'Delete last digit';

  @override
  String get keypadDecimal => 'Decimal point';

  @override
  String get uiGalleryTitle => 'UI Gallery';

  @override
  String get all => 'All';

  @override
  String get home => 'Home';

  @override
  String get collect => 'Collect';

  @override
  String get farmers => 'Farmers';

  @override
  String get pay => 'Pay';

  @override
  String get collectionCentre => 'Collection centre';

  @override
  String get feeding => 'Feeding';

  @override
  String get breeding => 'Breeding';

  @override
  String get workers => 'Workers';

  @override
  String get money => 'Money';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get isThisCorrect => 'Is this correct?';

  @override
  String get yesSave => 'Yes, save';

  @override
  String get noChangeIt => 'No, change it';

  @override
  String get skip => 'Skip';

  @override
  String get menu => 'Menu';

  @override
  String get seeAll => 'See all';

  @override
  String get profile => 'Profile';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String farmRoleLine(String place, String role) {
    return '$place · $role';
  }

  @override
  String get splashTagline => 'Tap. Record. Grow.';

  @override
  String get splashLoading => 'Loading your farm…';

  @override
  String get welcomeTitle => 'Welcome to FarmTap';

  @override
  String get welcomeBody =>
      'Records for your farm and milk centre — even without network.';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get continueEmail => 'Continue with email';

  @override
  String get terms => 'Terms';

  @override
  String get privacy => 'Privacy';

  @override
  String get brandTagline => 'Tap the card, record the work.';

  @override
  String get brandBody =>
      'Records for farms and milk centres in Western Uganda — offline, in Runyankore and English.';

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get emailSignInSubtitle => 'Use the email you signed up with.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newToFarmTap => 'New to FarmTap? Create an account';

  @override
  String get signInFailed => 'Email or password is wrong.';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpSubtitle => 'You\'ll set up your farm next. 14 days free.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get nameRequired => 'Enter your name.';

  @override
  String get emailIncomplete => 'Check the email — it looks incomplete.';

  @override
  String get passwordRule => 'At least 8 characters';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get agreeTerms => 'I agree to the Terms and Privacy Policy';

  @override
  String get agreeTermsRequired => 'Tick the box to agree first.';

  @override
  String get createAccount => 'Create account';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetSubtitle => 'We\'ll email you a link to set a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String resetLinkSent(String email) {
    return 'Reset link sent to $email';
  }

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailBody(String email) {
    return 'We sent a link to $email. You can keep setting up your farm meanwhile.';
  }

  @override
  String get continueSetup => 'Continue setup';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get emailSentAgain => 'Email sent again';

  @override
  String get chooseFarmTitle => 'Choose a farm';

  @override
  String chooseFarmSubtitle(int count) {
    return 'You have access to $count places.';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleClerk => 'Milk clerk';

  @override
  String get roleWorker => 'Worker';

  @override
  String get statusActive => 'Active';

  @override
  String get statusTrial => 'Trial';

  @override
  String get statusReadOnly => 'Read-only';

  @override
  String trialDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Trial $_temp0';
  }

  @override
  String get addAnotherFarm => 'Add another farm';

  @override
  String get somethingWentWrongShort => 'That did not work. Try again.';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'What you typed on this screen will be lost.';

  @override
  String get discardConfirm => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get sectorTitle => 'What do you do?';

  @override
  String get sectorSubtitle => 'Pick your main work. Dairy is ready now.';

  @override
  String get sectorDairy => 'Dairy (cattle)';

  @override
  String get sectorDairySub => 'Farms and milk collection centres';

  @override
  String get sectorPoultry => 'Poultry';

  @override
  String get sectorPoultrySub => 'Layers, broilers, eggs';

  @override
  String get sectorPiggery => 'Piggery';

  @override
  String get sectorPiggerySub => 'Sows, piglets, sales';

  @override
  String get sectorGoats => 'Goats & sheep';

  @override
  String get sectorCrops => 'Crops & produce buying';

  @override
  String get sectorCropsSub => 'Coffee, matooke, maize';

  @override
  String get sectorFish => 'Fish farming';

  @override
  String waitlistTitle(String sector) {
    return '$sector is coming soon';
  }

  @override
  String get waitlistBody =>
      'Join the waitlist and we\'ll message you the day it\'s ready. No payment needed.';

  @override
  String get yourNameLabel => 'Your name';

  @override
  String get whatsappLabel => 'WhatsApp number';

  @override
  String get joinWaitlist => 'Join the waitlist';

  @override
  String get waitlistDoneTitle => 'You\'re on the list!';

  @override
  String waitlistDoneBody(String sector, String name) {
    return 'We\'ll WhatsApp you when $sector opens in FarmTap. Thank you, $name.';
  }

  @override
  String get done => 'Done';

  @override
  String get dairyTypeTitle => 'What kind of dairy?';

  @override
  String get dairyTypeSubtitle =>
      'This decides your home screen. You can add the other later.';

  @override
  String get dairyFarm => 'Dairy farm';

  @override
  String get dairyFarmSub => 'I keep cows and record milk, health, feeding';

  @override
  String get centreOption => 'Milk collection centre';

  @override
  String get centreOptionSub => 'Farmers bring milk to me';

  @override
  String get bothOption => 'Both';

  @override
  String get bothOptionSub => 'Farm and collection centre';

  @override
  String get farmDetailsTitle => 'About your farm';

  @override
  String get farmNameLabel => 'Farm name';

  @override
  String get districtLabel => 'District';

  @override
  String get villageLabel => 'Village / parish';

  @override
  String get herdSizeLabel => 'How many cows?';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get contactsTitle => 'Where should we send reports?';

  @override
  String get contactsSubtitle =>
      'Daily farm reports go to WhatsApp. Alerts and reminders go by SMS.';

  @override
  String get dailyReportTime => 'Daily report at 7:00 pm';

  @override
  String get smsSameAsWhatsapp => 'SMS number is the same as WhatsApp';

  @override
  String get smsNumberLabel => 'SMS number';

  @override
  String get sendDailyWhatsapp => 'Send me the daily report on WhatsApp';

  @override
  String get sendSmsAlerts =>
      'Send me SMS alerts (sick cows, low stock, trial)';

  @override
  String get roleTitle => 'What is your role?';

  @override
  String get roleOwnerSub => 'I own the farm and pay for FarmTap';

  @override
  String get roleManagerSub => 'I run the farm for the owner';

  @override
  String get firstStaffTitle => 'Add your first worker';

  @override
  String get firstStaffSubtitle =>
      'Workers use a card and a 4-digit PIN — no email needed.';

  @override
  String get nameLabel => 'Name';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleHerdsman => 'Herdsman';

  @override
  String get roleVet => 'Vet';

  @override
  String get choosePin => 'Choose a 4-digit PIN';

  @override
  String get choosePinHint => 'Tap to choose the PIN';

  @override
  String get nfcLaterTitle => 'Add an NFC card later';

  @override
  String get nfcLaterBody =>
      'Tap \'Assign card\' on the worker\'s page when cards arrive.';

  @override
  String get saveWorker => 'Save worker';

  @override
  String get farmReadyTitle => 'Your farm is ready!';

  @override
  String farmReadyBody(String date) {
    return 'Your 7 free days start today and end on $date. After that FarmTap is UGX 70,000 a month.';
  }

  @override
  String get summaryFarm => 'Farm';

  @override
  String get summaryPlan => 'Plan';

  @override
  String get summaryFreeUntil => 'Free until';

  @override
  String get planDairy => 'FarmTap Dairy';

  @override
  String get startUsingFarmTap => 'Start using FarmTap';

  @override
  String get choose => 'Choose';

  @override
  String get phoneIncomplete =>
      'Check the number — it needs 9 digits after +256.';

  @override
  String get farmNameRequired => 'Enter the farm name.';

  @override
  String get pinRequired => 'Choose a 4-digit PIN.';

  @override
  String get herd1to10 => '1–10';

  @override
  String get herd11to30 => '11–30';

  @override
  String get herd31to100 => '31–100';

  @override
  String get herdOver100 => '100+';

  @override
  String get phonePrefix => '+256 ';

  @override
  String get pinChosen => 'PIN chosen';

  @override
  String get roleMilkClerk => 'Milk clerk';

  @override
  String get tapYourCard => 'Tap your card';

  @override
  String get tapYourCardBody =>
      'Hold your FarmTap card on the back of the phone.';

  @override
  String get enterCardInstead => 'Enter card number instead';

  @override
  String get ownerSignIn => 'Owner sign-in';

  @override
  String get switchFarm2 => 'Switch farm';

  @override
  String get simulateTap => 'Simulate tap (debug)';

  @override
  String get cardNumberTitle => 'Enter your card number';

  @override
  String get cardNumberSubtitle => 'It\'s printed on the front of your card.';

  @override
  String get next => 'Next';

  @override
  String get cardNotFound => 'No worker has this card. Check the number.';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get enterPin => 'Enter your 4-digit PIN';

  @override
  String wrongPinTries(int count) {
    return 'Wrong PIN. $count tries left.';
  }

  @override
  String get cardLocked => 'Too many tries. This card is locked for 5 minutes.';

  @override
  String notYou(String name) {
    return 'Not $name? Tap a different card';
  }

  @override
  String get forgotPin => 'Forgot PIN? Ask the farm manager to reset it.';

  @override
  String get nfcOffTitle => 'NFC is turned off';

  @override
  String get nfcOffBody =>
      'Turn on NFC in your phone settings to use cards, or type the card number.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get typeCardNumber => 'Type card number';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String farmAndDate(String farm, String date) {
    return '$farm · $date';
  }

  @override
  String get milkToday => 'Milk today';

  @override
  String get cows => 'Cows';

  @override
  String milkingDry(int milking, int dry) {
    return '$milking milking · $dry dry';
  }

  @override
  String get underTreatment => 'Under treatment';

  @override
  String notForSaleCount(int count) {
    return '$count not for sale';
  }

  @override
  String get workersIn => 'Workers in';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get recordMilk => 'Record milk';

  @override
  String get treatment => 'Treatment';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get milkThisWeek => 'Milk this week';

  @override
  String get litreUnit => 'L';

  @override
  String helloStaff(String name) {
    return 'Hello, $name';
  }

  @override
  String clockedIn(String time, String role) {
    return 'Clocked in at $time · $role';
  }

  @override
  String get lock => 'Lock';

  @override
  String get whatAreYouDoing => 'What are you doing?';

  @override
  String get morningSession => 'Morning session';

  @override
  String get eveningSession => 'Evening session';

  @override
  String groupsLeft(int count) {
    return '$count groups left';
  }

  @override
  String get giveTreatment => 'Give treatment';

  @override
  String dueNow(int count) {
    return '$count due now';
  }

  @override
  String get dipping => 'Dipping';

  @override
  String dueOn(String day) {
    return 'Due $day';
  }

  @override
  String get heatService => 'Heat / service';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get photoNote => 'Photo + note';

  @override
  String get myTasksToday => 'My tasks today';

  @override
  String get alerts => 'Alerts';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get filterAll => 'All';

  @override
  String get filterHealth => 'Health';

  @override
  String get filterMilk => 'Milk';

  @override
  String get filterStock => 'Stock';

  @override
  String get filterMoney => 'Money';

  @override
  String get urgent => 'Urgent';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get syncStatusBody =>
      'Records are saved on this phone first, then sent to the cloud.';

  @override
  String get syncedLabel => 'Synced';

  @override
  String recordsCount(String count) {
    return '$count records';
  }

  @override
  String get waitingToSend => 'Waiting to send';

  @override
  String milkRecordsCount(int count) {
    return '$count milk records';
  }

  @override
  String get failedLabel => 'Failed';

  @override
  String get now => 'Now';

  @override
  String get syncNow => 'Sync now';

  @override
  String get youreOffline => 'You\'re offline';

  @override
  String get offlineKeepRecording =>
      'Keep recording — everything is saved on this phone and will sync when network returns.';

  @override
  String get getReminders => 'Get reminders?';

  @override
  String get getRemindersBody =>
      'FarmTap reminds you about calvings, vaccinations and when treated milk is safe again.';

  @override
  String get allowReminders => 'Allow reminders';

  @override
  String get notNow => 'Not now';

  @override
  String get syncStatusOpen => 'Sync status';

  @override
  String attnNotForSale(String name) {
    return '$name — milk not for sale';
  }

  @override
  String attnSafeFrom(String drug, String date) {
    return '$drug · safe from $date';
  }

  @override
  String attnMilkDrop(int percent, String name) {
    return 'Milk dropped $percent% — $name';
  }

  @override
  String attnMilkDropSub(String today, String average) {
    return '$today L today vs $average L average';
  }

  @override
  String attnCalving(String name) {
    return 'Calving due: $name';
  }

  @override
  String attnInDays(int days, String date) {
    return 'In $days days · $date';
  }

  @override
  String attnStockLow(String item) {
    return '$item is running low';
  }

  @override
  String attnBagsLeft(int bags, int days) {
    return '$bags bags left · about $days days';
  }

  @override
  String get attnEdited => 'Record edited after closing';

  @override
  String attnEditedSub(String person, String session, String time) {
    return '$person · $session session · $time';
  }

  @override
  String attnTrialEnds(int days) {
    return 'Trial ends in $days days';
  }

  @override
  String get attnTrialPay => 'Pay UGX 70,000 to keep recording';

  @override
  String get sessionAm => 'AM';

  @override
  String get sessionPm => 'PM';

  @override
  String taskBefore(String time) {
    return 'Before $time';
  }

  @override
  String get taskAfterEveningMilking => 'After evening milking';

  @override
  String get dairyMeal => 'Dairy meal';

  @override
  String animalsCount(int count) {
    return '$count animals';
  }

  @override
  String get scanTag => 'Scan ear tag';

  @override
  String get filter => 'Filter';

  @override
  String get searchAnimals => 'Search by name or tag number';

  @override
  String get statusMilking => 'Milking';

  @override
  String get statusDry => 'Dry';

  @override
  String get statusTreated => 'Treated';

  @override
  String get statusPregnant => 'Pregnant';

  @override
  String get statusHeifer => 'Heifer';

  @override
  String get statusCalf => 'Calf';

  @override
  String get statusBull => 'Bull';

  @override
  String get filterCalves => 'Calves';

  @override
  String tagAndBreedAge(String tag, String breed, int age) {
    return '$tag · $breed · $age yrs';
  }

  @override
  String breedAge(String breed, int age) {
    return '$breed · $age yrs';
  }

  @override
  String get colAnimal => 'Animal';

  @override
  String get colTag => 'Tag';

  @override
  String get colBreedAge => 'Breed & age';

  @override
  String get colStatus => 'Status';

  @override
  String get colMilkToday => 'Milk today';

  @override
  String get notForSale => 'Not for sale';

  @override
  String get addAnimal2 => 'Add animal';

  @override
  String get filterAnimals => 'Filter animals';

  @override
  String get statusLabel => 'Status';

  @override
  String get groupLabel => 'Group';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortName => 'Name';

  @override
  String get sortTag => 'Tag';

  @override
  String get sortMilk => 'Milk';

  @override
  String get clear => 'Clear';

  @override
  String showAnimals(int count) {
    return 'Show $count animals';
  }

  @override
  String get calfPen => 'Calf pen';

  @override
  String get animalTitle => 'Animal';

  @override
  String get printLabels => 'Print ear-tag labels';

  @override
  String get edit => 'Edit';

  @override
  String animalHeaderLine(String tag, String breed, String kind, int age) {
    return '$tag · $breed · $kind · $age yrs';
  }

  @override
  String get kindCow => 'Cow';

  @override
  String get kindHeifer => 'Heifer';

  @override
  String get kindBull => 'Bull';

  @override
  String get kindCalf => 'Calf';

  @override
  String get treatedNotForSale => 'Treated — milk not for sale';

  @override
  String notForSaleUntil(String date) {
    return 'Milk not for sale until $date';
  }

  @override
  String withdrawalBody(String drug, int days) {
    return '$drug withdrawal: $days days left. Milk is recorded as \'not for sale\'.';
  }

  @override
  String get avgMilkDay => 'Avg milk / day';

  @override
  String get daysInMilk => 'Days in milk';

  @override
  String get pregnancy => 'Pregnancy';

  @override
  String get pregnancyCheck => 'Check';

  @override
  String dueDate(String date) {
    return 'Due $date';
  }

  @override
  String get tabTimeline => 'Timeline';

  @override
  String get tabMilk => 'Milk';

  @override
  String get tabHealth => 'Health';

  @override
  String get tabBreeding => 'Breeding';

  @override
  String get record => 'Record';

  @override
  String evTreatment(String drug) {
    return '$drug treatment';
  }

  @override
  String evTreatmentSub(String reason, String vet, String date) {
    return '$reason · $vet · safe from $date';
  }

  @override
  String evMilk(String litres) {
    return 'Milk $litres L';
  }

  @override
  String evMilkSub(String am, String pm) {
    return 'AM $am · PM $pm';
  }

  @override
  String evServed(String method) {
    return 'Served — $method';
  }

  @override
  String evServedSub(String straw, String by) {
    return 'Straw: $straw · $by';
  }

  @override
  String evVaccination(String name) {
    return '$name vaccination';
  }

  @override
  String evBatch(String batch) {
    return 'Batch $batch';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noEventsYet => 'Nothing recorded here yet';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get tagNumberLabel => 'Tag number';

  @override
  String get breedLabel => 'Breed';

  @override
  String get dobLabel => 'Date of birth';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexCowHeifer => 'Cow / heifer';

  @override
  String get nationalTagLabel => 'National livestock tag number';

  @override
  String get motherOptional => 'Mother (optional)';

  @override
  String get saveAnimal => 'Save animal';

  @override
  String animalSaved(String name) {
    return '$name added to the herd';
  }

  @override
  String get tagRequired => 'Enter the tag number.';

  @override
  String get pointAtQr => 'Point at the QR code on the ear tag';

  @override
  String get torch => 'Torch';

  @override
  String get typeTagInstead => 'Type tag number instead';

  @override
  String recordFor(String name) {
    return 'Record for $name';
  }

  @override
  String get whatHappened => 'What happened?';

  @override
  String get evKindMilk => 'Milk';

  @override
  String get evKindTreatment => 'Treatment';

  @override
  String get evKindHeat => 'Heat / service';

  @override
  String get evKindCalving => 'Calving';

  @override
  String get evKindSold => 'Sold';

  @override
  String get evKindDied => 'Died';

  @override
  String get welcomeLittleOne => 'Welcome, little one!';

  @override
  String calfBornBody(String mother, String tag) {
    return '$mother had a heifer calf. We added her to your herd as $tag.';
  }

  @override
  String get mother => 'Mother';

  @override
  String get born => 'Born';

  @override
  String get calf => 'Calf';

  @override
  String todayAt(String time) {
    return 'Today $time';
  }

  @override
  String heiferTag(String tag) {
    return 'Heifer · $tag';
  }

  @override
  String get nameTheCalf => 'Name the calf';

  @override
  String recordDeathTitle(String name) {
    return 'Record $name as dead?';
  }

  @override
  String get recordDeathBody =>
      'She will move to \'Past animals\'. Her records are kept. This is sent to the owner\'s daily report.';

  @override
  String get causeHint => 'e.g. East Coast Fever';

  @override
  String get causeLabel => 'Cause (optional)';

  @override
  String get yesRecordDeath => 'Yes, record death';

  @override
  String get headCount => 'Head count';

  @override
  String get totalAnimals => 'Total animals';

  @override
  String get milkingCows => 'Milking cows';

  @override
  String get dryCows => 'Dry cows';

  @override
  String get heifers => 'Heifers';

  @override
  String get calves => 'Calves';

  @override
  String get bulls => 'Bulls';

  @override
  String get thisMonth => 'This month';

  @override
  String get bornCount => 'Born';

  @override
  String get bought => 'Bought';

  @override
  String get sold => 'Sold';

  @override
  String get died => 'Died';

  @override
  String labelsSelected(int count) {
    return '$count labels selected';
  }

  @override
  String get labelsHint => 'Print on sticker paper and fix to the ear tags.';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get print => 'Print';

  @override
  String get emptyHerdTitle => 'No cows yet';

  @override
  String get emptyHerdBody => 'Add your first cow to start recording milk.';

  @override
  String get noMatches => 'No animals match this filter.';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String get dayTotal => 'Day total';

  @override
  String get pickDay => 'Pick a day';

  @override
  String sessionLabel(String session) {
    return '$session session';
  }

  @override
  String fromCows(int done, int total) {
    return 'from $done of $total cows';
  }

  @override
  String get cowsRecorded => 'Cows recorded';

  @override
  String countOf(int done, int total) {
    return '$done / $total';
  }

  @override
  String get justRecorded => 'Just recorded';

  @override
  String get checkThese => 'Check these';

  @override
  String notForSaleUntilShort(String date) {
    return 'Not for sale until $date';
  }

  @override
  String get notRecordedYet => 'Not recorded yet';

  @override
  String get milkTools => 'Milk tools';

  @override
  String get quickTotal => 'Quick total';

  @override
  String get milkUse => 'Milk use';

  @override
  String get milkSales => 'Milk sales';

  @override
  String get milkTrends => 'Milk trends';

  @override
  String get searchCow => 'Search cow or scan tag';

  @override
  String notRecordedCount(int count) {
    return 'Not recorded $count';
  }

  @override
  String allCount(int count) {
    return 'All $count';
  }

  @override
  String get scan => 'Scan';

  @override
  String get recorded => 'Recorded';

  @override
  String get howManyLitres => 'How many litres?';

  @override
  String lastTime(String litres) {
    return 'Last time: $litres L';
  }

  @override
  String litresValue(String litres) {
    return '$litres litres';
  }

  @override
  String recordedBy(String session, String name) {
    return '$session · recorded by $name';
  }

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String bigMilkBody(String litres) {
    return '$litres L is more than usual for one cow.';
  }

  @override
  String get yesCorrect => 'Yes, it is correct';

  @override
  String savedMilk(String litres, String name) {
    return 'Saved! $litres L from $name';
  }

  @override
  String cowsDoneThisSession(int done, int total, String session) {
    return '$done of $total cows done this $session. Keep going!';
  }

  @override
  String nextCow(String name) {
    return 'Next cow: $name';
  }

  @override
  String get finishSession => 'Finish session';

  @override
  String get allCowsDone => 'All cows recorded';

  @override
  String underTreatmentTitle(String name) {
    return '$name is under treatment';
  }

  @override
  String underTreatmentBody(String drug, String given, String until) {
    return '$drug given $given. Her milk must not be sold until $until. You can still record it as \'not for sale\'.';
  }

  @override
  String get recordNotForSale => 'Record as not for sale';

  @override
  String wholeHerdSession(String session) {
    return 'Whole herd · $session';
  }

  @override
  String get quickMode => 'Quick mode';

  @override
  String get quickModeBody =>
      'Use this when you can\'t record each cow. Per-cow records give better alerts.';

  @override
  String totalFromAllCows(String session) {
    return 'Total litres from all cows this $session';
  }

  @override
  String get saveTotal => 'Save total';

  @override
  String totalSaved(String litres) {
    return 'Saved $litres L for the whole herd';
  }

  @override
  String get wholeHerd => 'Whole herd';

  @override
  String todayLitres(String litres) {
    return 'Today · $litres L';
  }

  @override
  String get accountedFor => 'Accounted for';

  @override
  String get useSold => 'Sold';

  @override
  String get useHome => 'Home use';

  @override
  String get useCalves => 'Fed to calves';

  @override
  String get useNotForSale => 'Not for sale (treated)';

  @override
  String get useSpoiled => 'Spoiled';

  @override
  String get useSaved => 'Milk use saved';

  @override
  String get download => 'Download';

  @override
  String get soldThisWeek => 'Sold this week';

  @override
  String get owedToYou => 'Owed to you';

  @override
  String buyersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buyers',
      one: '1 buyer',
    );
    return '$_temp0';
  }

  @override
  String litresTimesPrice(String litres, String price) {
    return '$litres L × $price';
  }

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get colBuyer => 'Buyer';

  @override
  String get colLitres => 'Litres';

  @override
  String get colPricePerL => 'Price / L';

  @override
  String get colAmount => 'Amount';

  @override
  String get addSale => 'Add sale';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get totalThisMonth => 'Total this month';

  @override
  String get totalThisWeek => 'Total this week';

  @override
  String get totalThisYear => 'Total this year';

  @override
  String vsPrevious(String change, String period) {
    return '$change vs $period';
  }

  @override
  String get topCows => 'Top cows';

  @override
  String averagePerDay(String litres) {
    return 'Average $litres L / day';
  }

  @override
  String get droppingCheckHealth => 'Dropping — check health';

  @override
  String todayVsAvg(String today, String avg) {
    return '$today L today vs $avg L avg';
  }

  @override
  String sessionOpenSince(String session, String time) {
    return '$session session · open since $time';
  }

  @override
  String collectedThisSession(String session) {
    return 'Collected this $session';
  }

  @override
  String fromFarmersRejected(int farmers, int rejected) {
    return 'from $farmers farmers · $rejected rejected';
  }

  @override
  String get tapFarmerCard => 'Tap farmer card';

  @override
  String get cardNumber => 'Card number';

  @override
  String get qualityTest => 'Quality test';

  @override
  String get dispatch => 'Dispatch';

  @override
  String get closeSession => 'Close session';

  @override
  String get latestDeliveries => 'Latest deliveries';

  @override
  String timeAndCard(String time, String card) {
    return '$time · Card $card';
  }

  @override
  String get litresByHour => 'Litres by hour';

  @override
  String get receiveMilk => 'Receive milk';

  @override
  String get tapFarmersCard => 'Tap the farmer\'s card';

  @override
  String get holdCardBack => 'Hold the card on the back of the phone.';

  @override
  String get enterCardNumber => 'Enter card number';

  @override
  String get searchFarmerByName => 'Search farmer by name';

  @override
  String cardAndVillage(String card, String village) {
    return 'Card $card · $village';
  }

  @override
  String get cardOk => 'Card OK';

  @override
  String usuallyBrings(int low, int high) {
    return 'Usually brings $low–$high L';
  }

  @override
  String deliveryDetail(String session, String card, String test) {
    return '$session · Card $card · Test: $test';
  }

  @override
  String get testPassed => 'passed';

  @override
  String get testNotDone => 'not done';

  @override
  String get tapNextCard => 'Tap the next card';

  @override
  String get readyNextFarmer => 'Ready for the next farmer.';

  @override
  String get lastSaved => 'Last saved';

  @override
  String get smsQueuedPrintSlip => 'SMS receipt queued';

  @override
  String savedForFarmer(String litres, String name) {
    return 'Saved $litres L for $name';
  }

  @override
  String get deliveryUndone => 'Delivery removed';

  @override
  String suppliersCount(int count) {
    return '$count suppliers';
  }

  @override
  String get searchFarmers => 'Search name or card number';

  @override
  String deliveredToday(int count) {
    return 'Delivered today $count';
  }

  @override
  String notToday(int count) {
    return 'Not today $count';
  }

  @override
  String noCard(int count) {
    return 'No card $count';
  }

  @override
  String cardThisPeriod(String card, String litres) {
    return 'Card $card · this period $litres L';
  }

  @override
  String get colFarmer => 'Farmer';

  @override
  String get colCard => 'Card';

  @override
  String get colToday => 'Today';

  @override
  String get colThisPeriod => 'This period';

  @override
  String get colOwed => 'Owed';

  @override
  String get addFarmer => 'Add farmer';

  @override
  String get farmerTitle => 'Farmer';

  @override
  String get call => 'Call';

  @override
  String cardAndPhone(String card, String phone) {
    return 'Card $card · $phone';
  }

  @override
  String get smsReceiptsOn => 'SMS receipts on';

  @override
  String get thisPeriod => 'This period';

  @override
  String get toBePaid => 'To be paid';

  @override
  String payDay(String date) {
    return 'Pay day: $date';
  }

  @override
  String get rejected => 'Rejected';

  @override
  String statementPeriod(String period) {
    return 'Statement $period';
  }

  @override
  String get share => 'Share';

  @override
  String get litresDelivered => 'Litres delivered';

  @override
  String get pricePerLitre => 'Price per litre';

  @override
  String get gross => 'Gross';

  @override
  String advanceOn(String date) {
    return 'Advance ($date)';
  }

  @override
  String get feedsOnCredit => 'Feeds on credit';

  @override
  String get toPay => 'To pay';

  @override
  String closeSessionTitle(String session) {
    return 'Close the $session session?';
  }

  @override
  String closeSessionBody(String litres, int farmers) {
    return '$litres L from $farmers farmers. After closing, changes need a manager PIN and are reported to the owner.';
  }

  @override
  String get keepOpen => 'Keep open';

  @override
  String get managerPin => 'Manager PIN';

  @override
  String get sessionClosed => 'Session closed';

  @override
  String get payments => 'Payments';

  @override
  String periodLabel(String period) {
    return 'Period $period';
  }

  @override
  String toPayOn(String date) {
    return 'To pay on $date';
  }

  @override
  String payHeroSub(int farmers, String litres, String price) {
    return '$farmers farmers · $litres L · $price / L';
  }

  @override
  String get sendSmsStatements => 'Send SMS statements';

  @override
  String get paymentSheet => 'Payment sheet';

  @override
  String litresAndCard(String litres, String card) {
    return '$litres L · Card $card';
  }

  @override
  String get colGross => 'Gross';

  @override
  String get colDeductions => 'Deductions';

  @override
  String get colNet => 'Net';

  @override
  String get ready => 'Ready';

  @override
  String get payFarmers => 'Pay farmers';

  @override
  String farmersAndAmount(int farmers, String amount) {
    return '$farmers farmers · $amount';
  }

  @override
  String get mobileMoney => 'Mobile Money';

  @override
  String get cashSheet => 'Cash sheet';

  @override
  String get mobileMoneyPayouts => 'Mobile Money payouts';

  @override
  String get mobileMoneyBody =>
      'Each farmer receives an SMS when paid. Fees are shown before you confirm.';

  @override
  String get sent => 'Sent';

  @override
  String get sending => 'Sending…';

  @override
  String get failedRetry => 'Failed — retry';

  @override
  String get farmersLabel => 'Farmers';

  @override
  String get amount => 'Amount';

  @override
  String get estimatedFees => 'Estimated fees';

  @override
  String get total => 'Total';

  @override
  String get confirmAndPay => 'Confirm and pay';

  @override
  String get payoutStarted => 'Payouts started';

  @override
  String get smsStatements => 'SMS statements';

  @override
  String get previewWhatFarmersGet => 'Preview of what each farmer receives:';

  @override
  String get messages => 'Messages';

  @override
  String get smsLeftThisMonth => 'SMS left this month';

  @override
  String get extraSmsNeeded => 'Extra SMS needed';

  @override
  String countOfTotal(int count, int total) {
    return '$count of $total';
  }

  @override
  String sendToFarmers(int count) {
    return 'Send to $count farmers';
  }

  @override
  String get smsSent => 'Statements sent';

  @override
  String farmerAndLitres(String name, String litres) {
    return '$name · $litres L';
  }

  @override
  String get alcoholTest => 'Alcohol test';

  @override
  String get passed => 'Passed';

  @override
  String get failed => 'Failed';

  @override
  String get reason => 'Reason';

  @override
  String get reasonSour => 'Sour';

  @override
  String get reasonWater => 'Added water';

  @override
  String get reasonDirty => 'Dirty';

  @override
  String get reasonTreated => 'Treated cow';

  @override
  String get reasonOther => 'Other';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String willBeRejected(String litres) {
    return '$litres L will be rejected';
  }

  @override
  String get rejectedBody => 'Not paid. The farmer gets an SMS explaining why.';

  @override
  String get rejectMilk => 'Reject milk';

  @override
  String get acceptMilk => 'Accept milk';

  @override
  String get reconcile => 'Reconcile';

  @override
  String get receivedFromFarmers => 'Received from farmers';

  @override
  String get dispatchedToDairy => 'Dispatched to dairy';

  @override
  String get difference => 'Difference';

  @override
  String diffPercent(String percent, int limit) {
    return '$percent% · above $limit% limit';
  }

  @override
  String diffPercentOk(String percent, int limit) {
    return '$percent% · within $limit% limit';
  }

  @override
  String diffAboveLimit(int limit) {
    return 'Difference is above the $limit% limit';
  }

  @override
  String get diffAboveBody =>
      'Check spillage and the cooler dipstick. The owner is notified.';

  @override
  String get truck => 'Truck';

  @override
  String get driver => 'Driver';

  @override
  String get leftAt => 'Left at';

  @override
  String get temperature => 'Temperature';

  @override
  String get explainDifference => 'Explain the difference';

  @override
  String get saveReconciliation => 'Save reconciliation';

  @override
  String get reconciliationSaved => 'Reconciliation saved';

  @override
  String smsStatementText(
    String name,
    String period,
    String litres,
    String amount,
    String payDay,
  ) {
    return 'FarmTap: $name, $period you delivered $litres L. Amount so far $amount. Pay day $payDay. Thank you!';
  }

  @override
  String smsReceiptText(String litres, String time, String card) {
    return 'FarmTap: Today $litres L received at $time. Card $card.';
  }

  @override
  String dateAt(String date, String time) {
    return '$date, $time';
  }

  @override
  String networkPhone(String network, String phone) {
    return '$network · $phone';
  }

  @override
  String get networkMtn => 'MTN';

  @override
  String get networkAirtel => 'Airtel';

  @override
  String get ugxUnit => 'UGX';

  @override
  String get farmerCardNotFound => 'No farmer has this card. Check the number.';

  @override
  String get findFarmer => 'Find farmer';

  @override
  String pricePerLitreValue(String price) {
    return '$price / L';
  }

  @override
  String get cashSheetInfo => 'Cash sheet';

  @override
  String get cashSheetBody =>
      'Print the sheet. Each farmer signs when paid in cash.';

  @override
  String get printCashSheet => 'Print cash sheet';

  @override
  String get retryPayout => 'Retry payout';

  @override
  String get wrongManagerPin => 'Wrong PIN. Try again.';

  @override
  String get dispatchTitle => 'Dispatch';

  @override
  String get reasonRequired => 'Pick a reason';

  @override
  String get farmerName => 'Farmer name';

  @override
  String get farmerPhone => 'Phone (Mobile Money)';

  @override
  String get cardOptional => 'Card number (optional)';

  @override
  String get saveFarmer => 'Save farmer';

  @override
  String farmerSaved(String name) {
    return '$name added';
  }

  @override
  String smsTodayAt(String time) {
    return 'Today, $time';
  }

  @override
  String get healthCalendar => 'Health calendar';

  @override
  String milkNotForSaleCount(int count) {
    return '$count milk not for sale';
  }

  @override
  String get dueThisWeek => 'Due this week';

  @override
  String get drugsLow => 'Drugs low';

  @override
  String get sickList => 'Sick list';

  @override
  String courseDay(int day, int total) {
    return 'day $day of $total';
  }

  @override
  String daysWithdrawal(int count) {
    return '$count days';
  }

  @override
  String get withdrawalLabel => 'withdrawal';

  @override
  String get newTreatment => 'New treatment';

  @override
  String tagTapToChange(String tag) {
    return '$tag · tap to change';
  }

  @override
  String get whatIsTheProblem => 'What is the problem?';

  @override
  String get condMastitis => 'Mastitis';

  @override
  String get condLame => 'Lame';

  @override
  String get condFever => 'Fever';

  @override
  String get condWound => 'Wound';

  @override
  String get condEye => 'Eye';

  @override
  String get condDiarrhoea => 'Diarrhoea';

  @override
  String get condOther => 'Other';

  @override
  String get drugLabel => 'Drug';

  @override
  String get doseLabel => 'Dose';

  @override
  String get routeLabel => 'Route';

  @override
  String get givenBy => 'Given by';

  @override
  String get routeInjection => 'Injection (IM)';

  @override
  String get routeOral => 'By mouth';

  @override
  String get routeSpray => 'Spray';

  @override
  String get routePourOn => 'Pour-on';

  @override
  String drugStockLine(String stock, int days) {
    return 'Stock: $stock · withdrawal $days days (milk)';
  }

  @override
  String get noWithdrawal => 'No milk withdrawal';

  @override
  String get blockMilkBody =>
      'FarmTap will block her milk and remind you when it\'s safe.';

  @override
  String get treatmentSaved => 'Treatment saved';

  @override
  String treatmentSavedBody(String name, String weekday) {
    return '$name\'s milk is marked \'not for sale\' until $weekday. We\'ll remind you on day 3 to check her.';
  }

  @override
  String treatmentSavedNoWithdrawal(String name) {
    return '$name\'s treatment is saved. We\'ll remind you on day 3 to check her.';
  }

  @override
  String get addAnotherTreatment => 'Add another treatment';

  @override
  String get pickAnimal => 'Pick animal';

  @override
  String get drugStock => 'Drug stock';

  @override
  String get addDrug => 'Add drug';

  @override
  String drugIsLow(String drug) {
    return '$drug is low';
  }

  @override
  String drugLowBody(String count) {
    return '$count bottle left. Usage this month is higher than recorded treatments.';
  }

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderNoted => 'Added to the shopping list';

  @override
  String bottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bottles',
      one: '1 bottle',
    );
    return '$_temp0';
  }

  @override
  String litresCount(String count) {
    return '$count litres';
  }

  @override
  String withdrawalDaysLine(int days) {
    return 'withdrawal $days days';
  }

  @override
  String reorderAt(String count) {
    return 'reorder at $count';
  }

  @override
  String get lowBadge => 'Low';

  @override
  String get drugName => 'Drug name';

  @override
  String get stockLabel => 'Stock';

  @override
  String get withdrawalDaysLabel => 'Withdrawal days (milk)';

  @override
  String get saveDrug => 'Save drug';

  @override
  String drugSaved(String name) {
    return '$name added';
  }

  @override
  String get listView => 'List';

  @override
  String get monthView => 'Month';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get taskTitle => 'What needs doing?';

  @override
  String get taskDate => 'Date';

  @override
  String get saveTask => 'Save';

  @override
  String get taskAdded => 'Added to the calendar';

  @override
  String get milkNotForSale => 'Milk not for sale';

  @override
  String keepMilkSeparate(int count) {
    return '$count cows — keep their milk separate';
  }

  @override
  String get keepMilkSeparateBody =>
      'Do not sell or mix this milk until the date shown.';

  @override
  String drugSince(String drug, String date) {
    return '$drug · since $date';
  }

  @override
  String get safeFrom => 'safe from';

  @override
  String get whyThisMatters => 'Why this matters';

  @override
  String get whyThisMattersBody =>
      'Collection centres test for drug residues and reject the whole can. One treated cow can spoil a full delivery.';

  @override
  String get noWithdrawalsTitle => 'All milk can be sold';

  @override
  String get noWithdrawalsBody => 'No cow is under drug withdrawal.';

  @override
  String treatmentReadBack(String condition, String drug) {
    return '$condition · $drug';
  }

  @override
  String treatmentReadBackDetail(String date) {
    return 'Milk not for sale until $date';
  }

  @override
  String get kindVaccination => 'Vaccination';

  @override
  String get kindDipping => 'Dipping';

  @override
  String get kindDeworming => 'Deworming';

  @override
  String get recordFeeding => 'Record feeding';

  @override
  String get feedCostThisMonth => 'Feed cost this month';

  @override
  String perLitreOfMilk(String amount) {
    return '$amount per litre of milk';
  }

  @override
  String get okBadge => 'OK';

  @override
  String get buyFeed => 'Buy feed';

  @override
  String get buyFeedSub => 'Adds stock and records an expense.';

  @override
  String get whichGroup => 'Which group?';

  @override
  String get whichFeed => 'Which feed?';

  @override
  String get groupMilkingCows => 'Milking cows';

  @override
  String get groupDryCows => 'Dry cows';

  @override
  String get groupHeifers => 'Heifers';

  @override
  String get groupCalves => 'Calves';

  @override
  String get feedDairyMeal => 'Dairy meal';

  @override
  String get feedMaizeBran => 'Maize bran';

  @override
  String get feedMineralLick => 'Mineral lick';

  @override
  String get feedSilage => 'Silage';

  @override
  String feedBags(String n) {
    return '$n bags';
  }

  @override
  String feedBlocks(String n) {
    return '$n blocks';
  }

  @override
  String feedTonnes(String n) {
    return 'about $n tonnes';
  }

  @override
  String feedLeftDays(String stock, int days) {
    return '$stock left · about $days days';
  }

  @override
  String feedLowTitle(String feed, String stock) {
    return '$feed: $stock left';
  }

  @override
  String feedLowBody(int days) {
    return 'About $days days at the current rate.';
  }

  @override
  String get unitBags => 'bags';

  @override
  String get unitBlocks => 'blocks';

  @override
  String get unitKg => 'kg';

  @override
  String get unitTonnes => 'Tonnes';

  @override
  String get unitBagsLabel => 'Bags';

  @override
  String get unitBlocksLabel => 'Blocks';

  @override
  String get pricePerBag => 'Price per bag';

  @override
  String get pricePerBlock => 'Price per block';

  @override
  String get pricePerTonne => 'Price per tonne';

  @override
  String feedAmountCaption(String unit, String feed) {
    return '$unit of $feed';
  }

  @override
  String get colFeed => 'Feed';

  @override
  String get colInStock => 'In stock';

  @override
  String get colUsedPerDay => 'Used / day';

  @override
  String get colDaysLeft => 'Days left';

  @override
  String get supplier => 'Supplier';

  @override
  String get savePurchase => 'Save purchase';

  @override
  String get saveFeeding => 'Save feeding';

  @override
  String feedingSaved(String amount) {
    return 'Feeding saved: $amount';
  }

  @override
  String purchaseSaved(String amount) {
    return 'Purchase saved: $amount';
  }

  @override
  String moreThanInStock(String stock) {
    return 'Only $stock in stock';
  }

  @override
  String get pregnantLabel => 'Pregnant';

  @override
  String calvingInDays(int days) {
    return 'Calving in $days days';
  }

  @override
  String get checkPregnancy => 'Check pregnancy';

  @override
  String get expectedCalvings => 'Expected calvings';

  @override
  String get toDo => 'To do';

  @override
  String inDaysCount(int days) {
    return 'in $days days';
  }

  @override
  String daysShortValue(int days) {
    return '$days d';
  }

  @override
  String servedCheckFrom(String served, String from) {
    return 'Served $served · check from $from';
  }

  @override
  String get heatSeenYesterday => 'Heat seen yesterday';

  @override
  String get heatSeenToday => 'Heat seen today';

  @override
  String get checkAction => 'Check';

  @override
  String get serveAction => 'Serve';

  @override
  String get tipLabel => 'Tip';

  @override
  String get breedingTip =>
      'Check heat signs morning and evening. A missed heat costs about 21 days of milk.';

  @override
  String get recordHeat => 'Record heat';

  @override
  String heatAndService(String name) {
    return 'Heat & service — $name';
  }

  @override
  String get heiferWord => 'heifer';

  @override
  String get cowWord => 'cow';

  @override
  String get heatSeen => 'Heat seen';

  @override
  String get servedNatural => 'Served';

  @override
  String get aiLabel => 'AI';

  @override
  String get semenStraw => 'Semen / straw';

  @override
  String get bullLabel => 'Bull';

  @override
  String get technician => 'Technician';

  @override
  String get dateLabel => 'Date';

  @override
  String get costLabel => 'Cost';

  @override
  String checkReminder(String date) {
    return 'Pregnancy check reminder: $date';
  }

  @override
  String calvingIfPregnant(String date) {
    return 'Expected calving if pregnant: $date';
  }

  @override
  String serviceSaved(String name) {
    return 'Saved for $name';
  }

  @override
  String get whichAnimal => 'Which animal?';

  @override
  String isSheP(String name) {
    return 'Is $name pregnant?';
  }

  @override
  String checkBody(String date) {
    return 'Served $date. Record what the vet found.';
  }

  @override
  String get yesPregnant => 'Yes, pregnant';

  @override
  String get notPregnant => 'Not pregnant';

  @override
  String notPregnantSaved(String name) {
    return '$name: not pregnant. Watch for heat.';
  }

  @override
  String isPregnantTitle(String name) {
    return '$name is pregnant!';
  }

  @override
  String pregnantBody(String date) {
    return 'Expected calving: $date. We\'ll remind you 30 days and 7 days before.';
  }

  @override
  String get servedLabel => 'Served';

  @override
  String get checkedBy => 'Checked by';

  @override
  String get dryOffFrom => 'Dry off from';

  @override
  String get checkedByLabel => 'Vet';

  @override
  String get cardsLabel => 'Cards';

  @override
  String get subscriptionLabel => 'Subscription';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get lockPhone => 'Lock phone';

  @override
  String get lockPhoneSub => 'Next person taps their card';

  @override
  String get signOutLabel => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Records on this phone stay saved. Sign in again to see them.';

  @override
  String get comingSoonBody => 'This part of FarmTap is being built.';

  @override
  String peopleCount(int n) {
    return '$n people';
  }

  @override
  String get filterInNow => 'In now';

  @override
  String get filterNotIn => 'Not in';

  @override
  String get inLabel => 'In';

  @override
  String get outLabel => 'Out';

  @override
  String get notInLabel => 'Not in';

  @override
  String inAt(String time) {
    return 'In $time';
  }

  @override
  String outAt(String time) {
    return 'Out $time';
  }

  @override
  String get cardBadge => 'Card';

  @override
  String get noCardBadge => 'No card';

  @override
  String cardNumberBadge(String number) {
    return 'Card $number';
  }

  @override
  String get addWorker => 'Add worker';

  @override
  String get workerTitle => 'Worker';

  @override
  String roleSince(String role, String date) {
    return '$role · since $date';
  }

  @override
  String get daysThisMonth => 'Days this month';

  @override
  String get milkRecords => 'Milk records';

  @override
  String get balanceOwed => 'Balance owed';

  @override
  String get resetPin => 'Reset PIN';

  @override
  String get replaceLostCard => 'Replace lost card';

  @override
  String get assignCardRow => 'Assign card';

  @override
  String whatCanDo(String name) {
    return 'What $name can do';
  }

  @override
  String get canDoManager => 'Everything except money settings';

  @override
  String get canDoHerdsman => 'Milk, feeding, treatments';

  @override
  String get canDoClerk => 'Milk, collection, payments';

  @override
  String get canDoWorker => 'Milk, feeding';

  @override
  String get canDoVet => 'Treatments, breeding';

  @override
  String get activityLog => 'Activity log';

  @override
  String resetPinTitle(String name) {
    return 'Reset $name\'s PIN?';
  }

  @override
  String get resetPinBody =>
      'They choose a new 4-digit PIN the next time they tap their card.';

  @override
  String resetPinDone(String name) {
    return '$name will choose a new PIN';
  }

  @override
  String get assignCard => 'Assign card';

  @override
  String get tapNewCardNow => 'Tap the new card now';

  @override
  String holdBlankCard(String name) {
    return 'Hold $name\'s blank card on the back of the phone.';
  }

  @override
  String cardAssigned(String number, String name) {
    return 'Card $number is now $name\'s';
  }

  @override
  String cardTaken(String number, String name) {
    return 'Card $number belongs to $name';
  }

  @override
  String get typeTheCardNumber => 'Type the number printed on the card';

  @override
  String get useCard => 'Use this card';

  @override
  String get attendance => 'Attendance';

  @override
  String ofInCount(int n, int total) {
    return '$n of $total in';
  }

  @override
  String get tapToClock => 'Tap your card to clock in or out';

  @override
  String get clockInOut => 'Clock in / out — tap card';

  @override
  String clockedInToast(String name, String time) {
    return '$name clocked in $time';
  }

  @override
  String clockedOutToast(String name, String time) {
    return '$name clocked out $time';
  }

  @override
  String get tasks => 'Tasks';

  @override
  String get tabToday => 'Today';

  @override
  String get tabThisWeek => 'This week';

  @override
  String get tabDone => 'Done';

  @override
  String doneAt(String time) {
    return 'Done $time';
  }

  @override
  String get photoNeeded => 'Photo needed';

  @override
  String get overdueBadge => 'Overdue';

  @override
  String get newTask => 'New task';

  @override
  String get whoDoesIt => 'Who does it?';

  @override
  String get whenLabel => 'When';

  @override
  String get taskSaved => 'Task saved';

  @override
  String get noTasks => 'Nothing here';

  @override
  String get wagesAdvances => 'Wages & advances';

  @override
  String get wagesThisMonth => 'Wages this month';

  @override
  String get advancesGiven => 'Advances given';

  @override
  String wageLine(String wage, String advance) {
    return 'Wage $wage · advance $advance';
  }

  @override
  String get toPayLabel => 'to pay';

  @override
  String get paidBadge => 'Paid';

  @override
  String get recordAdvance => 'Record advance';

  @override
  String get amountLabel => 'Amount';

  @override
  String payWage(String name) {
    return 'Pay $name';
  }

  @override
  String wagePaid(String name, String amount) {
    return 'Paid $name $amount';
  }

  @override
  String advanceSaved(String amount, String name) {
    return 'Advance $amount to $name';
  }

  @override
  String get advanceKind => 'Advance';

  @override
  String get wageKind => 'Wage';

  @override
  String get visitingVet => 'Visits';

  @override
  String get colName => 'Name';

  @override
  String get colRole => 'Role';

  @override
  String get colThisMonth => 'This month';

  @override
  String daysCount(int n) {
    return '$n days';
  }

  @override
  String noOneHasCard(String number) {
    return 'No one has card $number';
  }

  @override
  String get managerPinNeeded => 'Manager PIN needed';

  @override
  String typedCardNeedsManager(String number) {
    return 'Card $number was typed, not tapped. A manager must confirm clocking in or out.';
  }

  @override
  String get wagesShort => 'Wages';

  @override
  String get editWorker => 'Edit worker';

  @override
  String workerSaved(String name) {
    return '$name saved';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get profitLabel => 'Profit';

  @override
  String get lossLabel => 'Loss';

  @override
  String get costPerLitre => 'Cost per litre';

  @override
  String milkIncomeCaption(String amount) {
    return 'Milk $amount';
  }

  @override
  String expenseShare(String group, int percent) {
    return '$group $percent%';
  }

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get latestLabel => 'Latest';

  @override
  String get addExpense => 'Add expense';

  @override
  String get exportLabel => 'Export';

  @override
  String get categoryLabel => 'Category';

  @override
  String get groupFeed => 'Feed';

  @override
  String get groupDrugsVet => 'Drugs & vet';

  @override
  String get groupWages => 'Wages';

  @override
  String get groupTransport => 'Transport';

  @override
  String get groupFuel => 'Fuel & power';

  @override
  String get groupOther => 'Other';

  @override
  String get groupDrugsShort => 'Drugs';

  @override
  String get noteLabel => 'Note';

  @override
  String get receiptPhoto => 'Receipt photo';

  @override
  String expenseSaved(String amount) {
    return 'Expense saved: $amount';
  }

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get monthlyFarmReport => 'Monthly farm report';

  @override
  String get monthlyFarmReportSub => 'Milk, herd, health, money · PDF';

  @override
  String get milkRecordsReport => 'Milk records';

  @override
  String get milkRecordsReportSub => 'Per cow, per day · Excel / CSV';

  @override
  String get farmerStatements => 'Farmer statements';

  @override
  String get farmerStatementsSub => 'Collection centre · PDF';

  @override
  String get treatmentsReport => 'Treatments & withdrawals';

  @override
  String get treatmentsReportSub => 'For buyers and inspections · PDF';

  @override
  String get exportAll => 'Export all my data';

  @override
  String get exportAllSub => 'Everything you have recorded';

  @override
  String get dailyWhatsapp => 'Daily WhatsApp report';

  @override
  String dailyWhatsappSub(String time) {
    return 'Every day at $time';
  }

  @override
  String previewReport(String month) {
    return 'Preview · $month report';
  }

  @override
  String get shareLabel => 'Share';

  @override
  String reportTitle(String farm, String month) {
    return '$farm — $month';
  }

  @override
  String get milkProduced => 'Milk produced';

  @override
  String get milkSold => 'Milk sold';

  @override
  String sentToEveryDay(String phone, String time) {
    return 'Sent to $phone every day at $time';
  }

  @override
  String get sendTime => 'Send time';

  @override
  String get includeMoney => 'Include money';

  @override
  String get includeMoneySub => 'Income and expenses';

  @override
  String get smsIfWhatsappFails => 'SMS if WhatsApp fails';

  @override
  String rpMilk(String litres, String trend) {
    return 'Milk: $litres L ($trend)';
  }

  @override
  String rpNotForSale(String litres, String who) {
    return 'Not for sale: $litres L ($who, treated)';
  }

  @override
  String rpTreatmentsFeed(int n, String bags) {
    return 'Treatments: $n · Feed used: $bags bags';
  }

  @override
  String rpWorkers(int n, int total) {
    return 'Workers in: $n of $total';
  }

  @override
  String rpAlert(String item, int n) {
    return 'Alert: $item: $n bags left';
  }

  @override
  String rpMoney(String income, String expenses) {
    return 'Money this month: in $income, out $expenses';
  }

  @override
  String get searchList => 'Search';

  @override
  String useTyped(String text) {
    return 'Use “$text”';
  }

  @override
  String get nothingFound => 'Nothing found. Type the full name to use it.';

  @override
  String get locationOff =>
      'Turn on location in your phone settings, or pick the district.';

  @override
  String get locationDenied =>
      'Location is not allowed. Pick the district from the list.';

  @override
  String get locationNotFound =>
      'Could not find your district. Pick it from the list.';

  @override
  String get findingLocation => 'Finding your location…';

  @override
  String get cowsCountLabel => 'How many cows?';

  @override
  String get cowsCountHelper => 'All cattle on the farm today';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleMilker => 'Milker';

  @override
  String get roleSecretary => 'Secretary';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleGuard => 'Security guard';

  @override
  String get roleCook => 'Cook';

  @override
  String get roleFamily => 'Family member';

  @override
  String get roleCoOwner => 'Co-owner';

  @override
  String get roleFarmManager => 'Farm manager';

  @override
  String get jobLabel => 'Job';

  @override
  String get jobHelper =>
      'Pick one or type your own, e.g. “Farmer\'s daughter”';

  @override
  String get accessLabel => 'What they can do in FarmTap';

  @override
  String get phoneOptional => 'Phone number (optional)';

  @override
  String get wageOptional => 'Monthly pay (optional)';

  @override
  String get cardForWorker => 'Their card';

  @override
  String get cardForWorkerHelp =>
      'Hold their FarmTap card to the back of the phone, or type the number printed on it.';

  @override
  String cardReadNumber(String number) {
    return 'Card $number';
  }

  @override
  String get changeCard => 'Change';

  @override
  String get noCardYet =>
      'No card yet: give one later from the worker\'s page.';

  @override
  String get yourRoleLabel => 'Your role';

  @override
  String get ownerAccess => 'Full access: I own the farm and pay for FarmTap';

  @override
  String get managerAccess => 'Manager: I run the farm for the owner';

  @override
  String get accessTitle => 'What can you do?';

  @override
  String get cowsInvalid => 'Type the number of cows, e.g. 25';

  @override
  String firstWorkerSaved(String name) {
    return '$name added';
  }

  @override
  String get farmCreateFailed =>
      'Could not create the farm. Check the internet and try again.';

  @override
  String get creatingFarm => 'Creating your farm…';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeSystem => 'Phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeHelp => 'Phone follows your phone\'s light or dark setting.';

  @override
  String get soundsLabel => 'Sounds';

  @override
  String get soundsSub => 'Clicks and chimes when you save';

  @override
  String get accountTitle => 'Account';

  @override
  String get farmTitle => 'Farm';

  @override
  String get helpIntro =>
      'Stuck or have a question? Talk to the FarmTap team. We answer in English.';

  @override
  String get helpWhatsapp => 'Chat on WhatsApp';

  @override
  String get helpWhatsappSub =>
      'Fastest; send a screenshot if something looks wrong';

  @override
  String get helpCall => 'Call us';

  @override
  String get helpSms => 'Send an SMS';

  @override
  String get helpOpenFailed => 'Could not open that on this phone.';

  @override
  String get authNoInternet => 'No internet. Connect and try again.';

  @override
  String get authProviderOff =>
      'This sign-in method is not switched on for FarmTap yet. Use Google or email for now.';

  @override
  String get authOtherMethod =>
      'This email already uses another sign-in. Use Google or email.';

  @override
  String get authEmailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String authFailedCode(String code) {
    return 'That did not work ($code). Try again.';
  }

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDontMatch => 'The passwords do not match.';

  @override
  String get passwordRuleStrong => '8+ characters with A-Z, a-z and 0-9';

  @override
  String get passwordWeak =>
      'Add a capital letter, a small letter and a number.';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get suggestPassword => 'Suggest a strong password';

  @override
  String suggestedPasswordNote(String password) {
    return 'Suggested: $password. Save it somewhere safe.';
  }

  @override
  String get copyWhatsappNumber => 'Same as WhatsApp';

  @override
  String get smsNumberHelp =>
      'Alerts go here. It can be a different line from WhatsApp.';

  @override
  String get signInTagline =>
      'Simple records for your business.\nWorks even without network.';

  @override
  String get signInCardOffline => 'Works offline';

  @override
  String get signInCardTap => 'Tap cards';

  @override
  String get signInCardBackup => 'Safe backup';

  @override
  String get orLabel => 'or';

  @override
  String get scanCard => 'Scan card';

  @override
  String workerCardTitle(String name) {
    return '$name\'s worker card';
  }

  @override
  String get workerCardOnCollect =>
      'This card is for clocking in and out. Farmers bringing milk need their own farmer card.';

  @override
  String get openAttendance => 'Clock in or out';

  @override
  String newCardTitle(String number) {
    return 'New card $number';
  }

  @override
  String get newCardOnCollect =>
      'No farmer has this card yet. Add the farmer now and the card is theirs.';

  @override
  String get addFarmerWithCard => 'Add farmer with this card';

  @override
  String get newCardOnAttendance =>
      'No worker has this card yet. Give it to a worker, then tap again to clock in.';

  @override
  String get giveCardToWorker => 'Give it to a worker';

  @override
  String farmerCardOnAttendance(String name) {
    return 'This is $name\'s farmer card. Worker cards clock in here.';
  }

  @override
  String get typeCardNumberLink => 'Type the card number';

  @override
  String gettingFarmReady(String farm) {
    return 'Getting $farm ready…';
  }

  @override
  String get gettingFarmReadySub =>
      'Bringing back your animals, workers and records.';

  @override
  String welcomeBackName(String name) {
    return 'Welcome back, $name';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeBackPlain => 'Welcome back';

  @override
  String openingFarmTitle(String farm) {
    return 'Opening $farm';
  }

  @override
  String get farmPickerOneSub =>
      'Your farm is ready on this phone. Tap it to open.';

  @override
  String farmPickerManySub(int count) {
    return 'You can open $count farms. Pick the one to work on.';
  }

  @override
  String get openFarmButton => 'Open farm';

  @override
  String get placeDairyFarm => 'Dairy farm';

  @override
  String get placeCentre => 'Milk collection centre';

  @override
  String get placeDairyAndCentre => 'Dairy farm and milk centre';

  @override
  String herdCows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cows',
      one: '1 cow',
    );
    return '$_temp0';
  }

  @override
  String herdBirds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count birds',
      one: '1 bird',
    );
    return '$_temp0';
  }

  @override
  String herdPigs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pigs',
      one: '1 pig',
    );
    return '$_temp0';
  }

  @override
  String herdAnimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animals',
      one: '1 animal',
    );
    return '$_temp0';
  }

  @override
  String youAreRole(String role) {
    return 'You: $role';
  }

  @override
  String get freeTrialLabel => 'Free trial';

  @override
  String trialDaysLeftOf(int left, int total) {
    return '$left of $total days left';
  }

  @override
  String paidUntilDate(String date) {
    return 'Paid until $date';
  }

  @override
  String graceDaysToPay(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Payment due · $_temp0 to pay';
  }

  @override
  String get readOnlyPickerHint =>
      'Trial ended. You can look at records but not add new ones until you pay.';

  @override
  String signedInAsEmail(String email) {
    return 'Signed in as $email';
  }

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get noFarmTitle => 'Let\'s set up your farm';

  @override
  String noFarmBody(int days) {
    return 'It takes about 2 minutes. Your first $days days are free.';
  }

  @override
  String get setUpMyFarm => 'Set up my farm';

  @override
  String get joinFarmHint =>
      'Joining someone else\'s farm? Ask the owner to add your email, then tap Check again.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get placesOfflineTitle => 'Can\'t load your farm';

  @override
  String get placesOfflineBody =>
      'This phone needs the internet once to download your farm. After that it works offline.';

  @override
  String get farmLimitReachedBody =>
      'This account already has a farm. To run more than one farm, ask us about the multi-farm plan.';

  @override
  String get talkToUsWhatsApp => 'Talk to us on WhatsApp';

  @override
  String get multiFarmWhatsAppMessage =>
      'Hello FarmTap, I want to run more than one farm. Please tell me about the multi-farm plan.';

  @override
  String get multiFarmQuestion => 'Running more than one farm?';

  @override
  String get multiFarmAnswer =>
      'One account runs one farm. Ask us about the multi-farm plan.';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportPdfSub => 'To print, or send on WhatsApp or email';

  @override
  String get exportSheet => 'Spreadsheet (Excel)';

  @override
  String get exportSheetSub => 'Opens in Excel or Google Sheets';

  @override
  String get nothingToExport => 'Nothing to export yet';

  @override
  String get exportFailed => 'Could not make the file. Try again.';

  @override
  String viewingDay(String day) {
    return 'Viewing $day';
  }

  @override
  String get backToToday => 'Back to today';

  @override
  String get noMilkRecordedToday =>
      'No milk recorded today yet. Record milk first, then split it here.';

  @override
  String useMoreThanMilked(String litres) {
    return '$litres more than was milked today';
  }

  @override
  String get buyerCentre => 'Centre';

  @override
  String get buyerShop => 'Shop';

  @override
  String get buyerNeighbours => 'Neighbours';

  @override
  String get saleSaved => 'Sale saved';

  @override
  String get salePaidSaved => 'Marked as paid';

  @override
  String get saleUnpaidSaved => 'Marked as not paid';

  @override
  String paidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get markPaid => 'Mark as paid';

  @override
  String get markUnpaid => 'Mark as not paid';

  @override
  String get colDate => 'Date';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String get noSalesYetBody =>
      'Add each sale of milk, to the centre, a shop or neighbours. Unpaid sales show what buyers owe you.';

  @override
  String get enterBuyer => 'Enter who bought the milk';

  @override
  String get enterLitres => 'Enter the litres';

  @override
  String get enterPrice => 'Enter the price';

  @override
  String get notPaidYet => 'Not paid yet';

  @override
  String get paidNow => 'Paid now';

  @override
  String get saveSale => 'Save sale';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose from phone';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get photoFailed => 'Could not save the photo. Try again.';

  @override
  String get cameraPermissionNeeded =>
      'FarmTap needs the camera to scan. Allow it in your phone settings.';

  @override
  String get cameraNotAvailable =>
      'The camera is not available. Type the number instead.';

  @override
  String noAnimalWithTag(String tag) {
    return 'No animal with tag $tag on this farm';
  }

  @override
  String tagTaken(String tag) {
    return 'Another animal already has tag $tag';
  }

  @override
  String get editAnimal => 'Edit animal';

  @override
  String get statusNow => 'What is she doing now?';

  @override
  String animalSoldSaved(String name) {
    return '$name recorded as sold';
  }

  @override
  String sellAnimalTitle(String name) {
    return 'Sell $name';
  }

  @override
  String get sellAnimalBody =>
      'She moves to past animals. The price is added to this month\'s income.';

  @override
  String get salePrice => 'Price';

  @override
  String get boughtByOptional => 'Bought by (optional)';

  @override
  String get recordSale => 'Record sale';

  @override
  String get conditionLabel => 'Problem';

  @override
  String get givenByLabel => 'Given by';

  @override
  String get milkSafeFrom => 'Milk safe from';

  @override
  String get averagePerDayLabel => 'Average a day';

  @override
  String get cardLabel => 'Card';

  @override
  String get grossLabel => 'Gross (UGX)';

  @override
  String get deductionsLabel => 'Deductions (UGX)';

  @override
  String get netLabel => 'To pay (UGX)';

  @override
  String get incomeAnimalSale => 'Animal sold';

  @override
  String get incomeCalfSale => 'Calf sold';

  @override
  String get incomeManure => 'Manure';

  @override
  String get incomeHire => 'Bull service / hire';

  @override
  String get addIncome => 'Add income';

  @override
  String incomeSaved(String amount) {
    return '$amount income saved';
  }

  @override
  String get sourceLabel => 'From';

  @override
  String otherIncomeCaption(String amount) {
    return 'Other $amount';
  }

  @override
  String get deleteExpense => 'Remove this expense';

  @override
  String get deleteExpenseBody =>
      'Only remove an expense entered by mistake. It stays in the audit trail.';

  @override
  String get expenseDeleted => 'Expense removed';

  @override
  String get fromFeedPurchase =>
      'Made by a feed purchase. Change it in Feeding.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get noExpensesYet => 'No money recorded this month';

  @override
  String get noExpensesYetBody =>
      'Add expenses as you spend, and milk sales as you sell. Profit and cost per litre are worked out for you.';

  @override
  String get makingReport => 'Making the report…';

  @override
  String get saved => 'Saved';

  @override
  String get notSetYet => 'Not set yet';

  @override
  String get whatsappNumber => 'WhatsApp number';

  @override
  String get setWhatsappNumber =>
      'Set the WhatsApp number that gets this report.';

  @override
  String get sendNowWhatsapp => 'Send today\'s report on WhatsApp';

  @override
  String get addAnimalsFirst =>
      'Add your animals in Herd first, then record treatments here.';

  @override
  String get diseaseName => 'Name of the disease';

  @override
  String get whatYouSee => 'What you see (optional)';

  @override
  String get boughtMore => 'Bought more';

  @override
  String get countStock => 'Count';

  @override
  String get howManyNow => 'How many are on the shelf now';

  @override
  String get howManyBought => 'How many did you buy';

  @override
  String get pricePaidOptional => 'Price paid (optional)';

  @override
  String get enterAmount => 'Enter a number';

  @override
  String get stockSaved => 'Stock saved';

  @override
  String markJobDone(String job) {
    return 'Is “$job” done?';
  }

  @override
  String get markDone => 'Yes, it is done';

  @override
  String get jobDone => 'Marked as done';

  @override
  String get noHealthJobs => 'No health jobs planned';

  @override
  String get noHealthJobsBody =>
      'Add dipping, deworming and vaccinations so nobody forgets them.';

  @override
  String get overdue => 'Overdue';

  @override
  String get feedNapier => 'Napier grass';

  @override
  String get feedHay => 'Hay';

  @override
  String get feedCottonCake => 'Cotton seed cake';

  @override
  String get feedBrewersWaste => 'Brewers\' waste';

  @override
  String get countFeedStock => 'Count stock';

  @override
  String get countFeedStockSub =>
      'What is in the store now. Do this when you start, and whenever the numbers look wrong.';

  @override
  String get addFemalesFirst =>
      'Add your cows and heifers in Herd first, then record heats and services here.';

  @override
  String get editFarmer => 'Edit farmer';

  @override
  String get sendSmsReceipts => 'Send SMS receipts';

  @override
  String get sendSmsReceiptsHint => 'A text after every delivery';

  @override
  String priceSaved(String price) {
    return 'Price saved: $price per litre';
  }

  @override
  String get pricePerLitreHint =>
      'What the centre pays farmers for each litre. Amounts owed update straight away.';

  @override
  String get phoneCopied => 'Phone number copied';

  @override
  String get absentWord => 'Absent';

  @override
  String get presentWord => 'Present';

  @override
  String broughtToday(String litres) {
    return 'Brought $litres today';
  }

  @override
  String get notDeliveredToday => 'No milk today';

  @override
  String get cardNotUsable => 'Card cannot be used';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get photoSheetTitle => 'Photo for the ID card';

  @override
  String get photoSheetBody => 'Face the camera, in good light.';

  @override
  String get photoSaved => 'Photo saved';

  @override
  String get photoSavedLocal =>
      'Photo saved. The full photo uploads when cloud storage is on.';

  @override
  String get photoNotSaved => 'Photo not saved. Try again.';

  @override
  String get clockInOutShort => 'Clock in/out';

  @override
  String get lookUpShort => 'Look up';

  @override
  String get departmentLabel => 'Department';

  @override
  String get emergencyLabel => 'Emergency';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get ninLabel => 'NIN';

  @override
  String get memberSinceLabel => 'Since';

  @override
  String get issuedLabel => 'Issued';

  @override
  String get idNumberLabel => 'ID';

  @override
  String get downloadCardPdf => 'Download PDF';

  @override
  String get printCard => 'Print card';

  @override
  String get printOnA4 => 'Print on A4 paper';

  @override
  String get giveCardToSomeone => 'Give this card';

  @override
  String get holdQrToCamera => 'Hold the card\'s QR code to the camera';

  @override
  String get idCardBack => 'Back';

  @override
  String get idCardFront => 'Front';

  @override
  String idCardFrontLabel(String name) {
    return 'ID card of $name, front';
  }

  @override
  String idCardBackLabel(String name) {
    return 'ID card of $name, back';
  }

  @override
  String get idCardIfFound => 'If found, please return to the farm';

  @override
  String get idCardNoCardTitle => 'No card yet';

  @override
  String get idCardNoCardBody =>
      'Give a card first. Its number and QR code go on the print.';

  @override
  String get idCardPrintHelp =>
      'Card printer: print the 2 pages on a blank PVC card. Normal printer: print on A4, cut along the marks and laminate.';

  @override
  String get idCardScanMe => 'Scan me';

  @override
  String get idCardStaff => 'Staff';

  @override
  String get idCardSupplier => 'Milk supplier';

  @override
  String get idCardTitle => 'ID card';

  @override
  String get idCardValidNote => 'Valid until revoked. Tap or scan at the farm.';

  @override
  String lastPaidLine(String amount, String date) {
    return 'Last paid $amount on $date';
  }

  @override
  String payrollLine(String wage, String advances, String paid) {
    return 'Wage $wage · advances $advances · paid $paid';
  }

  @override
  String lostCardTitle(String number) {
    return 'Card $number was reported lost';
  }

  @override
  String lostCardBody(String name, String date) {
    return 'It belonged to $name ($date). Keep the card and tell the manager.';
  }

  @override
  String returnedCardTitle(String number) {
    return 'Card $number was returned';
  }

  @override
  String returnedCardBody(String name) {
    return 'It belonged to $name. Give it to someone new from their page.';
  }

  @override
  String get unknownCardBody => 'No one has this card yet.';

  @override
  String get otherFarmCardTitle => 'Card from another farm';

  @override
  String get otherFarmCardBody =>
      'This card belongs to another farm and does not work here.';

  @override
  String get moneyOwedLabel => 'Money owed';

  @override
  String get thisPeriodLabel => 'This period';

  @override
  String payDayLine(String date, String price) {
    return 'Pay day $date · $price a litre';
  }

  @override
  String get rejectedWord => 'rejected';

  @override
  String get nextCard => 'Next card';

  @override
  String get openDetails => 'Details';

  @override
  String get scanModeAttendance => 'Each card clocks in or out';

  @override
  String get scanModeLookUp => 'Each card shows who it is';

  @override
  String get scanQrInstead => 'Scan QR with camera';

  @override
  String get useNfcInstead => 'Tap cards instead';

  @override
  String get scanStationTitle => 'Scan cards';

  @override
  String get scanStationBody =>
      'Tap one card after another. Each person shows for a few seconds.';

  @override
  String scannedTodayTitle(int n) {
    return 'Scanned ($n)';
  }

  @override
  String statusClockedIn(String time) {
    return 'Clocked in $time';
  }

  @override
  String statusClockedOut(String time) {
    return 'Clocked out $time';
  }

  @override
  String statusLeftAt(String time) {
    return 'Left at $time';
  }

  @override
  String statusPresentSince(String time) {
    return 'Present since $time';
  }

  @override
  String get statusNotInToday => 'Not in today';

  @override
  String get advanceWord => 'Advance';

  @override
  String get advancesLabel => 'Advances';

  @override
  String get alreadyHasCard =>
      'This person already has a card. Replace it instead.';

  @override
  String get cardActive => 'Working';

  @override
  String get cardHistoryTitle => 'Card history';

  @override
  String get cardLost => 'Lost';

  @override
  String get cardNotGivenTitle => 'Card not given';

  @override
  String get cardRegisterTitle => 'All cards';

  @override
  String get cardReturned => 'Given back';

  @override
  String get changeMyPin => 'Change my PIN';

  @override
  String get changeNumber => 'Change number';

  @override
  String get chooseOwnPinBody =>
      'Pick 4 numbers only you know. Not 1234, not 0000.';

  @override
  String get chooseOwnPinTitle => 'Choose your own PIN';

  @override
  String get confirmPinBody => 'Type the same 4 numbers again.';

  @override
  String get confirmPinTitle => 'Type it again';

  @override
  String get departmentOptional => 'Department (optional)';

  @override
  String get deptAnimalHealth => 'Animal health';

  @override
  String get deptCollection => 'Milk collection';

  @override
  String get deptFeeding => 'Feeding';

  @override
  String get deptField => 'Field and pasture';

  @override
  String get deptHerd => 'Herd';

  @override
  String get deptKitchen => 'Kitchen';

  @override
  String get deptManagement => 'Management';

  @override
  String get deptMilking => 'Milking';

  @override
  String get deptOffice => 'Office';

  @override
  String get deptSecurity => 'Security';

  @override
  String get deptTransport => 'Transport';

  @override
  String get detailsTitle => 'Details';

  @override
  String get emergencyNameOptional => 'Next of kin (optional)';

  @override
  String get emergencyPhoneOptional => 'Next of kin phone (optional)';

  @override
  String get idCardRowBody => 'See, print or download the ID card';

  @override
  String get myAttendanceTitle => 'My days';

  @override
  String get myPageShort => 'Me';

  @override
  String get myPageTitle => 'My page';

  @override
  String get myTasksTitle => 'My tasks';

  @override
  String get nfcChipWord => 'NFC chip';

  @override
  String get ninOptional => 'National ID number (optional)';

  @override
  String get noCardsToPrint => 'No one has a card yet. Give cards first.';

  @override
  String get noCardsYetBody =>
      'Cards you give to workers and milk suppliers show here.';

  @override
  String get noCardsYetTitle => 'No cards yet';

  @override
  String get noTasksForYou => 'No tasks for you today';

  @override
  String get openMyCard => 'Open my card';

  @override
  String get paidInFull => 'Paid in full';

  @override
  String get paidLabel => 'Paid';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneSignInBadge => 'Phone sign-in';

  @override
  String get pinChangedToast => 'Your new PIN is saved';

  @override
  String get pinTooEasy => 'Too easy to guess. Pick other numbers.';

  @override
  String get pinWhatFor =>
      'Your card says who you are. Your PIN proves it is you, so nobody can clock in or record milk with your card. On your own phone it is your password.';

  @override
  String get pinsDoNotMatch => 'The two PINs are not the same. Try again.';

  @override
  String get printAllCards => 'Print all cards';

  @override
  String get printedCardNoChip => 'Printed card, no chip (QR and number only)';

  @override
  String get revokeCardRow => 'Take back or report lost';

  @override
  String get revokeCardRowBody => 'The card stops working at once';

  @override
  String get revokeLost => 'Lost or stolen: never use again';

  @override
  String get revokeReturned => 'Given back: can go to someone new';

  @override
  String get setUpPhoneSignIn => 'Set up phone sign-in';

  @override
  String get setUpPhoneSignInBody =>
      'They sign in on their own phone with phone number and PIN';

  @override
  String get staffLoginNotMade =>
      'Phone sign-in was not set up. Check the internet and try again.';

  @override
  String get staffLoginOtherFarm =>
      'This phone number already signs in to another farm.';

  @override
  String get staffPhoneInvalid =>
      'Type a Ugandan phone number, like 0701 220 318.';

  @override
  String get staffSignInBody =>
      'Type the phone number your farm saved for you.';

  @override
  String get staffSignInEntry => 'I work on a farm: sign in with phone and PIN';

  @override
  String get staffSignInHelpBody =>
      'Ask your farm manager. They add your phone number and give you a PIN to start. The first time, you choose your own PIN.';

  @override
  String get staffSignInHelpTitle => 'No PIN yet?';

  @override
  String get staffSignInOffline =>
      'No internet. Sign-in needs internet the first time.';

  @override
  String get staffSignInTitle => 'Sign in as a worker';

  @override
  String get staffSignInTooMany =>
      'Too many tries. Wait a few minutes and try again.';

  @override
  String get staffSignInWrong => 'Phone number or PIN is wrong.';

  @override
  String get temporaryPinTitle => 'Starting PIN';

  @override
  String get todayLabel => 'Today';

  @override
  String get villageOptional => 'Village (optional)';

  @override
  String get wageLabel => 'Wage';

  @override
  String get wageWord => 'Wage';

  @override
  String cardLostCannotReuse(String card) {
    return 'Card $card was reported lost. It can never be given again.';
  }

  @override
  String cardRevokedToast(String card) {
    return 'Card $card no longer works';
  }

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count working cards',
      one: '1 working card',
    );
    return '$_temp0';
  }

  @override
  String endedOn(String date) {
    return 'Ended $date';
  }

  @override
  String issuedOn(String date) {
    return 'Given $date';
  }

  @override
  String myPayTitle(String month) {
    return 'My pay for $month';
  }

  @override
  String opensSections(String sections) {
    return 'Opens: $sections';
  }

  @override
  String replaceCardBody(String name, String card) {
    return '$name\'s card $card will be marked lost and stop working. Then tap the new card.';
  }

  @override
  String replaceCardTitle(String card) {
    return 'Replace card $card?';
  }

  @override
  String resetPinBodyTemp(String name) {
    return 'Give $name a starting PIN. They must choose their own the next time they sign in.';
  }

  @override
  String resetPinDoneTemp(String name) {
    return '$name must choose a new PIN at next sign-in';
  }

  @override
  String revokeCardBody(String name) {
    return 'What happened to $name\'s card?';
  }

  @override
  String revokeCardTitle(String card) {
    return 'Card $card';
  }

  @override
  String staffLoginMade(String name, String phone) {
    return '$name can now sign in on their phone with $phone and the starting PIN';
  }

  @override
  String staffSignInPinBody(String phone) {
    return 'Enter the PIN for $phone';
  }

  @override
  String temporaryPinBody(String name) {
    return 'Tell $name this PIN. They choose their own the first time.';
  }

  @override
  String get sendOnWhatsapp => 'WhatsApp';

  @override
  String get sendBySms => 'SMS';

  @override
  String get smsAppOpenFailed => 'Couldn\'t open the SMS app on this phone.';

  @override
  String get whatsappOpenFailed =>
      'Couldn\'t open WhatsApp. Is it installed? Try SMS.';

  @override
  String get messagesToSend => 'Messages to send';

  @override
  String get messagesFreeNote =>
      'Messages go out from this phone\'s WhatsApp or SMS app with the words already typed. Tap Send there. FarmTap charges nothing; SMS uses your own airtime or bundle.';

  @override
  String get noMessagesWaiting => 'No messages waiting';

  @override
  String get noMessagesWaitingSub =>
      'Milk receipts and weekly statements appear here, ready to send.';

  @override
  String messagesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages waiting',
      one: '1 message waiting',
    );
    return '$_temp0';
  }

  @override
  String sendNextTo(String name) {
    return 'Next: $name';
  }

  @override
  String get sendNextOnWhatsapp => 'Send next · WhatsApp';

  @override
  String get sendNextBySms => 'Send next · SMS';

  @override
  String get recentlySent => 'Recently sent';

  @override
  String get sentFromThisPhone => 'Sent from this phone';

  @override
  String get msgSentAutomatically => 'Sent automatically';

  @override
  String get msgKindReceipt => 'Receipt';

  @override
  String get msgKindStatement => 'Statement';

  @override
  String get removeMessage => 'Don\'t send';

  @override
  String statementsQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statements are ready to send.',
      one: '1 statement is ready to send.',
      zero: 'No farmer delivered this week, so there is nothing to send.',
    );
    return '$_temp0';
  }

  @override
  String get statementsReady => 'Statements ready';

  @override
  String get sendNow => 'Send now';

  @override
  String get statementsFreeNote =>
      'Sent one by one from this phone\'s WhatsApp or SMS. FarmTap charges nothing.';

  @override
  String readyEveryDay(String phone, String time) {
    return 'Ready every day at $time. Tap a button to send it to $phone.';
  }

  @override
  String get receiptWaiting => 'Receipt ready to send';

  @override
  String get opsContacts => 'Contacts';

  @override
  String get opsAddContact => 'Add contact';

  @override
  String get opsEditContact => 'Edit contact';

  @override
  String get opsContactKind => 'Who is this';

  @override
  String get opsContactNeeds =>
      'Add a name and a phone number of at least 9 digits.';

  @override
  String get opsContactOrg => 'Business or clinic (optional)';

  @override
  String get opsContactPlace => 'Where they are (optional)';

  @override
  String get opsShowWorkers => 'Workers can see this contact';

  @override
  String get opsSearchContacts => 'Search contacts';

  @override
  String get opsNoContacts => 'No contacts yet';

  @override
  String get opsNoContactsBody =>
      'Keep your vet, AI technician, feed suppliers and buyers here so anyone on the farm can call them.';

  @override
  String get opsWhatsapp => 'WhatsApp';

  @override
  String get opsKindVet => 'Vets';

  @override
  String get opsKindAi => 'AI technicians';

  @override
  String get opsKindFeed => 'Feed suppliers';

  @override
  String get opsKindAgrovet => 'Agrovet shops';

  @override
  String get opsKindBuyer => 'Buyers';

  @override
  String get opsKindTransport => 'Transport';

  @override
  String get opsKindEmergency => 'Emergency';

  @override
  String get opsKindOther => 'Other';

  @override
  String get opsRoster => 'Duty roster';

  @override
  String get opsAddDuty => 'Add duty';

  @override
  String get opsEditDuty => 'Edit duty';

  @override
  String get opsDutyNeeds => 'Pick who does it and on which days.';

  @override
  String get opsNoDuties => 'No duties yet';

  @override
  String get opsNoDutiesBody =>
      'Give each job a person and the days they do it. Stand-ins cover when someone is away.';

  @override
  String get opsNothingThatDay => 'No duties on this day.';

  @override
  String get opsTomorrow => 'Tomorrow';

  @override
  String get opsYou => 'You';

  @override
  String opsNobodyOn(String name) {
    return '$name is away and nobody stands in';
  }

  @override
  String opsStandsIn(String who, String colleague) {
    return '$who stands in for $colleague';
  }

  @override
  String get opsAway => 'Away';

  @override
  String get opsAddAway => 'Add';

  @override
  String get opsNobodyAway => 'Nobody is away.';

  @override
  String get opsAddWorkersFirst => 'Add workers first, then give them duties.';

  @override
  String get opsJob => 'Job';

  @override
  String get opsJobName => 'Name of the job';

  @override
  String get opsWho => 'Who does it';

  @override
  String get opsStandIn => 'Stand-in when away';

  @override
  String get opsNoStandIn => 'No stand-in';

  @override
  String get opsShift => 'When';

  @override
  String get opsEveryDay => 'Every day';

  @override
  String get opsSomeDays => 'Some days';

  @override
  String get opsWhichDays => 'Which days';

  @override
  String get opsFrom => 'From';

  @override
  String get opsTo => 'To';

  @override
  String get opsReason => 'Reason (optional)';

  @override
  String get opsDutyMilking => 'Milking';

  @override
  String get opsDutyFeeding => 'Feeding';

  @override
  String get opsDutyHealth => 'Health checks';

  @override
  String get opsDutyCleaning => 'Cleaning';

  @override
  String get opsDutyGrazing => 'Grazing';

  @override
  String get opsDutySecurity => 'Security';

  @override
  String get opsDutyCollection => 'Milk collection';

  @override
  String get opsDutyManager => 'Manager on duty';

  @override
  String get opsDutyOther => 'Other job';

  @override
  String get opsShiftMorning => 'Morning';

  @override
  String get opsShiftAfternoon => 'Afternoon';

  @override
  String get opsShiftEvening => 'Evening';

  @override
  String get opsShiftNight => 'Night';

  @override
  String get opsShiftAllDay => 'All day';

  @override
  String get opsFeedStore => 'Feeds store';

  @override
  String get opsAddFeed => 'Add feed';

  @override
  String get opsEditFeed => 'Edit feed';

  @override
  String get opsBuyOrFeed => 'Record buying or feeding';

  @override
  String get opsInStore => 'In the store';

  @override
  String get opsNoFeeds => 'No feeds yet';

  @override
  String get opsNoFeedsBody =>
      'Add the feeds you use. FarmTap works out how long each one lasts.';

  @override
  String get opsNoUseYet => 'No feeding recorded yet';

  @override
  String get opsLow => 'Low';

  @override
  String opsLastsDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Lasts about $days days',
      one: 'Lasts about 1 day',
      zero: 'Runs out today',
    );
    return '$_temp0';
  }

  @override
  String opsRunningLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds running low',
      one: '1 feed running low',
    );
    return '$_temp0';
  }

  @override
  String get opsCountStore => 'Count the store';

  @override
  String get opsCountStoreSub => 'Set what is really left';

  @override
  String opsHowMuchLeft(String unit) {
    return 'How much is left ($unit)';
  }

  @override
  String get opsFeedName => 'Feed name';

  @override
  String get opsFeedNameHint => 'For example dairy meal';

  @override
  String get opsUnit => 'Unit';

  @override
  String get opsUnitHint => 'kg, bags or bales';

  @override
  String get opsLowAt => 'Warn me when below (optional)';

  @override
  String get opsVaccinations => 'Vaccinations';

  @override
  String get opsRecordVaccination => 'Record vaccination';

  @override
  String get opsNoVaccinations => 'No vaccinations yet';

  @override
  String get opsNoVaccinationsBody =>
      'Record each vaccination and FarmTap reminds you when the next dose is due.';

  @override
  String get opsNextDoses => 'Next doses';

  @override
  String get opsGiven => 'Given';

  @override
  String get opsOverdue => 'Overdue';

  @override
  String get opsSoon => 'Soon';

  @override
  String get opsVaccine => 'Vaccine';

  @override
  String get opsWholeHerd => 'Whole herd';

  @override
  String get opsWholeHerdNote =>
      'Leave animals empty to record it for the whole herd.';

  @override
  String get opsGivenOn => 'Given on';

  @override
  String get opsNextDue => 'Next dose due (optional)';

  @override
  String get opsCostUgx => 'Cost in UGX (optional)';

  @override
  String get opsVet => 'Vet (optional)';

  @override
  String get opsNoVet => 'No vet';

  @override
  String get opsRemoveVaccination => 'Remove this vaccination?';

  @override
  String get opsRemoveVaccinationBody =>
      'Its cost is removed from your spending too.';

  @override
  String opsUgx(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'UGX $amountString';
  }

  @override
  String opsAnimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animals',
      one: '1 animal',
    );
    return '$_temp0';
  }

  @override
  String get opsNoDate => 'No date';

  @override
  String get opsClear => 'Clear';

  @override
  String get opsRemove => 'Remove';

  @override
  String get opsViewOnly => 'Only owners and managers can change this.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersSub => 'Duties, vaccinations, calving and your plan';

  @override
  String get remindersToday => 'Today';

  @override
  String get remindersNone => 'Nothing to remind you of today';

  @override
  String get remindersNoneBody =>
      'Duties, vaccinations, calving and plan reminders show here on the day.';

  @override
  String get remindersWhat => 'Remind about';

  @override
  String get remindersDuties => 'Duties for each worker';

  @override
  String get remindersVaccinations => 'Vaccinations due';

  @override
  String get remindersCalving => 'Calving, pregnancy checks and heat';

  @override
  String get remindersPlan => 'Free trial and plan ending';

  @override
  String get remindersHow => 'How';

  @override
  String get remindersPush => 'Notifications on this phone';

  @override
  String get remindersPushSub => 'Shown once each day';

  @override
  String get remindersWhatsapp => 'WhatsApp to workers';

  @override
  String get remindersWhatsappSub => 'Ready to send from this phone, free';

  @override
  String get remindersSms => 'SMS to workers';

  @override
  String get remindersSmsSub => 'Sent from this phone at your normal SMS rate';

  @override
  String get remindersHour => 'Remind at';

  @override
  String get remindersFreeNote =>
      'Messages go from your own phone, so FarmTap charges nothing for them.';

  @override
  String get subscriptionTitle => 'Plan and payment';

  @override
  String get payChoosePlan => 'Choose a plan';

  @override
  String payPerMonth(String amount) {
    return '$amount a month';
  }

  @override
  String get payHow => 'How to pay';

  @override
  String get payPhone => 'Mobile Money number';

  @override
  String get payPhoneNeeded =>
      'Enter an MTN or Airtel number, like 0772 123 456.';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payMobileNote =>
      'A prompt comes to that phone. Enter your Mobile Money PIN to pay.';

  @override
  String get payCardNote =>
      'A secure card page opens. Come back here when you have paid.';

  @override
  String get payByHand => 'Pay, then send us the transaction ID';

  @override
  String payByHandAmount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String get payAccountName => 'Account name';

  @override
  String get payCode => 'Account or pay code';

  @override
  String get payReference => 'Transaction ID';

  @override
  String get payReferenceHint => 'From your payment message';

  @override
  String get payReferenceNeeded =>
      'Enter the transaction ID from your payment message.';

  @override
  String get paySendDetails => 'Send payment details';

  @override
  String get payWaiting => 'Waiting for your payment';

  @override
  String get payWaitingPhone =>
      'Check your phone and enter your Mobile Money PIN. This page updates by itself.';

  @override
  String get payWaitingCard =>
      'Finish paying on the card page. This page updates by itself.';

  @override
  String get payCheckNow => 'Check now';

  @override
  String get payDone => 'Payment received';

  @override
  String get payDoneBody =>
      'Thank you. Your farm is open and your receipt is below.';

  @override
  String get payClaimSent => 'Payment details sent';

  @override
  String get payClaimSentBody =>
      'FarmTap checks your payment and opens your farm, usually within a few hours.';

  @override
  String get payFailed => 'Payment not finished';

  @override
  String get payFailedBody =>
      'Nothing was taken. Try again, or pay another way.';

  @override
  String get payTryAgain => 'Try again';

  @override
  String get payNotStarted =>
      'The payment could not start. Check your internet and try again.';

  @override
  String get paySoon => 'Paying in the app is coming soon';

  @override
  String paySoonBody(String phone) {
    return 'For now, WhatsApp or call FarmTap on $phone to pay.';
  }

  @override
  String get payAskOwner => 'Only the owner or a manager pays';

  @override
  String get payAskOwnerBody =>
      'Ask them to pay for FarmTap. Recording starts again as soon as the payment is confirmed.';

  @override
  String get payActive => 'Your plan is active';

  @override
  String payPaidUntil(String date) {
    return 'Paid until $date';
  }

  @override
  String payTrialEnds(String date) {
    return 'Your free trial ends on $date';
  }

  @override
  String get payLockedBody =>
      'Choose a plan and pay to record again. Your records are safe.';

  @override
  String get payReceipts => 'Receipts and invoices';

  @override
  String get payNoReceipts => 'Your receipts show here after each payment.';

  @override
  String get payReceipt => 'Receipt (PDF)';

  @override
  String get payInvoice => 'Invoice (PDF)';

  @override
  String get payRefundNote => 'Refund note (PDF)';

  @override
  String get payReceiptFailed => 'The PDF could not be made. Try again.';

  @override
  String get payHelp => 'Need help paying?';

  @override
  String payHelpMessage(String farm) {
    return 'Hello FarmTap, I want to pay for $farm.';
  }

  @override
  String get lockedTrialTitle => 'Your free trial has ended';

  @override
  String get lockedPlanTitle => 'Your FarmTap plan has ended';

  @override
  String lockedBody(String farm) {
    return 'Nothing can be added or changed on $farm until it is paid for. Your records are safe and nothing is deleted.';
  }

  @override
  String get lockedPay => 'Choose a plan and pay';

  @override
  String get lockedView => 'Look at my records';

  @override
  String get lockedOtherFarm => 'Open another farm';

  @override
  String get readOnlyBannerTitle => 'Read only';

  @override
  String get readOnlyBannerBody =>
      'Your plan has ended. Pay to record again; anything saved now will not be kept.';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoBody =>
      'Shown on your account on this phone and the web.';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get legalTitle => 'Legal';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get deleteTitle => 'Delete my account';

  @override
  String get deleteSub => 'Kept 90 days, then erased';

  @override
  String get deleteWarnTitle => 'This closes your account';

  @override
  String get deleteWarnBody => 'Read what happens before you go on.';

  @override
  String get deleteWhatHappens => 'What happens';

  @override
  String get deleteWhat1 =>
      'You are signed out on every phone and computer, and cannot sign in again.';

  @override
  String get deleteWhat2 =>
      'Every farm you own closes with it: nobody can open or record on it.';

  @override
  String get deleteWhat3 =>
      'Your workers and managers lose access to those farms.';

  @override
  String get deleteWhat4 => 'Any time left on your plan is not refunded.';

  @override
  String get deleteWhat5 =>
      'For 90 days FarmTap keeps everything, so support can bring it back if you change your mind.';

  @override
  String get deleteWhat6 =>
      'After 90 days your account, farms and records are erased for good.';

  @override
  String get deleteInstead =>
      'Only want to stop paying? You do not need to delete anything: the farm turns read-only and your records stay safe.';

  @override
  String get deleteContinue => 'I still want to delete';

  @override
  String get deleteUnderstand =>
      'I understand my farms close and are erased after 90 days';

  @override
  String get deleteTypeLabel => 'Type DELETE to confirm';

  @override
  String get deleteTypeNeeded => 'Type the word DELETE.';

  @override
  String get deleteReason => 'Why are you leaving? (optional)';

  @override
  String get deleteNow => 'Delete my account';

  @override
  String get deleteKeep => 'Keep my account';

  @override
  String get deleteLastTitle => 'Delete your account now?';

  @override
  String get deleteLastBody =>
      'You are signed out straight away. Support can restore it within 90 days.';

  @override
  String get deleteFailed =>
      'Your account was not deleted. Check your internet and try again.';

  @override
  String get closedTitle => 'This account is closed';

  @override
  String closedBody(String date) {
    return 'It can be brought back until $date. After that it is erased for good.';
  }

  @override
  String get closedBodySoon =>
      'It can be brought back for 90 days. After that it is erased for good.';

  @override
  String get closedRestore => 'Ask FarmTap to bring it back';

  @override
  String get closedRestoreMessage =>
      'Hello FarmTap, I closed my account and want it back.';

  @override
  String get aiTitle => 'AI Intelligence';

  @override
  String get aiIntro =>
      'Your farm records, read for you. Every answer says how it was made.';

  @override
  String get aiTodaysInsights => 'Today\'s insights';

  @override
  String get aiTools => 'AI tools';

  @override
  String get aiNothing => 'Nothing needs attention';

  @override
  String get aiNothingBody =>
      'FarmTap found nothing to warn you about from your records today.';

  @override
  String get aiSeen => 'Seen';

  @override
  String get aiMarkSeen => 'Mark as seen';

  @override
  String get aiMarkFixed => 'Mark as fixed';

  @override
  String get aiFindings => 'Findings';

  @override
  String get aiToday => 'Today';

  @override
  String get aiYesterday => 'Yesterday';

  @override
  String get aiAvg7 => '7-day average';

  @override
  String get aiNotRecorded => 'Not recorded';

  @override
  String get aiBalanceTitle => 'Where the milk went';

  @override
  String get aiProduced => 'Produced';

  @override
  String get aiSold => 'Sold';

  @override
  String get aiHomeUse => 'Used at home';

  @override
  String get aiThrownAway => 'Thrown away';

  @override
  String get aiNotAccounted => 'Not accounted for';

  @override
  String get aiNoSalesYet => 'No sales recorded yet';

  @override
  String get aiCowsDropping => 'Cows giving less milk';

  @override
  String get aiNoForecast => 'No forecast yet';

  @override
  String get aiForecastNeeds =>
      'A forecast needs about two weeks of milk records.';

  @override
  String get aiNext7 => 'Next 7 days';

  @override
  String get aiNext30 => 'Next 30 days';

  @override
  String get aiNextDays => 'Coming days';

  @override
  String get aiPerCow => 'Per cow';

  @override
  String get aiForecastNote =>
      'A forecast is an estimate from your past records. Disease, weather and feed can change it.';

  @override
  String get aiNoUseYet => 'No use recorded yet';

  @override
  String get aiNoFeed => 'No feeds yet';

  @override
  String get aiNoFeedBody =>
      'Add feeds and record what you use, and FarmTap will tell you when they run out.';

  @override
  String get aiFeedInStore => 'Feed in the store';

  @override
  String get aiCostPerLitre => 'Cost per litre';

  @override
  String get aiLitresPer1000 => 'Litres per 1,000 of feed spend';

  @override
  String get aiDrugStock => 'Drugs and supplies';

  @override
  String get aiNotCounted => 'Not counted yet';

  @override
  String get aiInCalf => 'In calf';

  @override
  String get aiOpenCows => 'Open cows';

  @override
  String get aiCalvingInterval => 'Calving interval';

  @override
  String get aiServedOrInCalf => 'Served or in calf';

  @override
  String get aiConfirmed => 'Confirmed';

  @override
  String get aiNotConfirmed => 'Not confirmed';

  @override
  String get aiNoHeatRecorded => 'No heat recorded';

  @override
  String get aiBreedingNote =>
      'Dates come from your breeding records. A vet check confirms pregnancy.';

  @override
  String get aiNeedAttention => 'Need attention';

  @override
  String get aiInWithdrawal => 'In withdrawal';

  @override
  String get aiVaccinesDue => 'Vaccines due';

  @override
  String get aiLastMonths => 'Last months';

  @override
  String get aiIncomeShort => 'Income';

  @override
  String get aiSpentShort => 'Spent';

  @override
  String get aiNet => 'Net';

  @override
  String get aiLargeExpenses => 'Unusually large expenses';

  @override
  String get aiNoRisks => 'No risks found';

  @override
  String get aiFilterAll => 'All';

  @override
  String get aiFilterNew => 'New';

  @override
  String get aiUseByNote =>
      'Use-by times follow the farm rule below. Your buyer decides what they accept.';

  @override
  String get aiAddBatch => 'Add a batch';

  @override
  String get aiNoBatches => 'No batches yet';

  @override
  String get aiNoBatchesBody =>
      'Add the milk you keep on the farm to watch how long it stays good.';

  @override
  String get aiInStorage => 'In storage';

  @override
  String get aiClosedBatches => 'Finished batches';

  @override
  String get aiExpired => 'Past use-by';

  @override
  String get aiUseSoon => 'Use soon';

  @override
  String get aiFresh => 'Fresh';

  @override
  String get aiNoReading => 'No temperature yet';

  @override
  String get aiRecordTemp => 'Record temperature';

  @override
  String get aiMarkSold => 'Mark as sold';

  @override
  String get aiMarkUsed => 'Mark as used';

  @override
  String get aiMarkDiscarded => 'Mark as thrown away';

  @override
  String get aiLitresNeeded => 'Enter the litres';

  @override
  String get aiLitres => 'Litres';

  @override
  String get aiPlaceOptional => 'Where it is kept (optional)';

  @override
  String get aiPlaceHint => 'Cooler 1, Can A';

  @override
  String get aiCooledQuestion => 'Is it in a cooler or cooling tank?';

  @override
  String get aiTempNeeded => 'Enter the temperature';

  @override
  String get aiTempC => 'Temperature (°C)';

  @override
  String get aiRuleInvalid => 'Check the numbers in the rule';

  @override
  String get aiRuleNote =>
      'These are starting rules. Check them with your buyer or the Dairy Development Authority.';

  @override
  String get aiCooledHours => 'Hours it keeps when cooled';

  @override
  String get aiWarmHours => 'Hours it keeps when warm';

  @override
  String get aiMaxTemp => 'Warmest safe temperature (°C)';

  @override
  String get aiAssistantNote =>
      'Answers come from your own records and are worked out on your phone.';

  @override
  String get aiAskLabel => 'Ask about your farm';

  @override
  String get aiAskHint => 'How much milk did we get this week?';

  @override
  String get aiAskButton => 'Ask';

  @override
  String get aiTryAsking => 'Try asking';

  @override
  String get aiWhichAnimal => 'Which animal?';

  @override
  String get aiChooseAnimal => 'Choose an animal';

  @override
  String get aiTempOptional => 'Temperature (optional)';

  @override
  String get aiTempHelp => 'Normal for a cow is about 38 to 39.';

  @override
  String get aiDaysSeen => 'Days she has been unwell';

  @override
  String get aiCheckNow => 'Check now';

  @override
  String get aiNoteOptional => 'Note (optional)';

  @override
  String get aiSavedToHistory => 'Saved to her health history';

  @override
  String get aiChooseAnimalToSave => 'Choose an animal to save this check';

  @override
  String get aiSaveToHistory => 'Save to health history';

  @override
  String get aiCallVetNow => 'Call the vet now';

  @override
  String get aiCallVetToday => 'Call the vet today';

  @override
  String get aiCallVetSoon => 'Call the vet soon';

  @override
  String get aiWarningSigns => 'Warning signs';

  @override
  String get aiPossibleCauses => 'Possible causes';

  @override
  String get aiMustReport => 'Report this to the authorities';

  @override
  String get aiWhatToDoNow => 'What to do now';

  @override
  String get aiScreeningNote =>
      'Disease screening from photos is experimental and cannot replace a vet.';

  @override
  String get aiPhotoCheckTitle => 'Check a photo';

  @override
  String get aiPhotoCheckBody =>
      'Check that a photo is clear enough before you send it to a vet.';

  @override
  String get aiPhotoFailed => 'This photo is not clear enough';

  @override
  String get aiPhotoGood => 'This photo is clear enough';

  @override
  String get aiPhotoRetake => 'Take it again in good light, closer and steady.';

  @override
  String get aiScreeningTargets => 'What screening will look for';

  @override
  String get aiNoModel => 'No model yet';

  @override
  String get aiScreeningPromise =>
      'FarmTap will not guess from a photo until a tested model is added.';

  @override
  String get aiReportAsk => 'Ask for a report';

  @override
  String get aiReportAskHint => 'Milk report for last month';

  @override
  String get aiReportNotFound =>
      'FarmTap could not tell which report you want. Choose one below.';

  @override
  String get aiReportKind => 'Report';

  @override
  String get aiReportPeriod => 'Period';

  @override
  String get aiShowReport => 'Show report';

  @override
  String get aiReportEmpty => 'Nothing to show for this period';

  @override
  String get aiExportReport => 'Export report';

  @override
  String get aiPeriodLastMonth => 'Last month';

  @override
  String get aiPeriod7 => 'Last 7 days';

  @override
  String get aiPeriod30 => 'Last 30 days';

  @override
  String get aiPeriodThisMonth => 'This month';

  @override
  String aiSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String aiConfidence(String level) {
    return '$level confidence';
  }

  @override
  String aiMadeFromDays(int count) {
    return 'Made from $count days of records';
  }

  @override
  String aiDaysAtRate(int days, String perDay, String unit) {
    return '$days days left at $perDay $unit a day';
  }

  @override
  String aiReorderAt(String level) {
    return 'Reorder at $level';
  }

  @override
  String aiDaysShort(int count) {
    return '$count days';
  }

  @override
  String aiDueAbout(String date) {
    return 'Due about $date';
  }

  @override
  String aiNextHeatAbout(String date) {
    return 'Next heat about $date';
  }

  @override
  String aiSafeFrom(String date) {
    return 'Safe from $date';
  }

  @override
  String aiOverdueDays(int count) {
    return '$count days overdue';
  }

  @override
  String aiDueOn(String date) {
    return 'Due $date';
  }

  @override
  String aiNextMonth(String month) {
    return 'Estimate for $month';
  }

  @override
  String aiUsually(String amount) {
    return 'usually $amount';
  }

  @override
  String aiShelfRule(String cooledHours, String maxTemp, String warmHours) {
    return 'Keeps $cooledHours hours at $maxTemp °C or colder, $warmHours hours when warm';
  }

  @override
  String aiUseBy(String time) {
    return 'Use by $time';
  }

  @override
  String aiPhotoNumbers(int brightness, int contrast, int sharpness) {
    return 'Light $brightness, contrast $contrast, sharpness $sharpness';
  }
}
