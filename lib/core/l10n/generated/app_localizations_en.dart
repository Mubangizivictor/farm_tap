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
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'Free trial: $_temp0 left';
  }

  @override
  String trialDaysLeftShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'Free trial · $_temp0 left';
  }

  @override
  String get trialThenPrice => 'Then UGX 70,000 a month. Pay anytime with Mobile Money.';

  @override
  String get trialUpgradeLine => 'Upgrade · UGX 70,000/mo';

  @override
  String get offlineBannerTitle => 'You are offline';

  @override
  String get offlineBannerBody => 'Records are saved on this phone and will sync when you are online.';

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
  String get welcomeBody => 'Records for your farm and milk centre — even without network.';

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
  String get brandBody => 'Records for farms and milk centres in Western Uganda — offline, in Runyankore and English.';

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
  String get signUpSubtitle => 'You\'ll set up your farm next. 7 days free.';

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
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
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
  String get waitlistBody => 'Join the waitlist and we\'ll message you the day it\'s ready. No payment needed.';

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
  String get dairyTypeSubtitle => 'This decides your home screen. You can add the other later.';

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
  String get contactsSubtitle => 'Daily farm reports go to WhatsApp. Alerts and reminders go by SMS.';

  @override
  String get dailyReportTime => 'Daily report at 7:00 pm';

  @override
  String get smsSameAsWhatsapp => 'SMS number is the same as WhatsApp';

  @override
  String get smsNumberLabel => 'SMS number';

  @override
  String get sendDailyWhatsapp => 'Send me the daily report on WhatsApp';

  @override
  String get sendSmsAlerts => 'Send me SMS alerts (sick cows, low stock, trial)';

  @override
  String get roleTitle => 'What is your role?';

  @override
  String get roleOwnerSub => 'I own the farm and pay for FarmTap';

  @override
  String get roleManagerSub => 'I run the farm for the owner';

  @override
  String get firstStaffTitle => 'Add your first worker';

  @override
  String get firstStaffSubtitle => 'Workers use a card and a 4-digit PIN — no email needed.';

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
  String get nfcLaterBody => 'Tap \'Assign card\' on the worker\'s page when cards arrive.';

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
  String get phoneIncomplete => 'Check the number — it needs 9 digits after +256.';

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
  String get tapYourCardBody => 'Hold your FarmTap card on the back of the phone.';

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
  String get nfcOffBody => 'Turn on NFC in your phone settings to use cards, or type the card number.';

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
  String get syncStatusBody => 'Records are saved on this phone first, then sent to the cloud.';

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
  String get quickModeBody => 'Use this when you can\'t record each cow. Per-cow records give better alerts.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count buyers', one: '1 buyer');
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
  String get mobileMoneyBody => 'Each farmer receives an SMS when paid. Fees are shown before you confirm.';

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
  String get diffAboveBody => 'Check spillage and the cooler dipstick. The owner is notified.';

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
  String smsStatementText(String name, String period, String litres, String amount, String payDay) {
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
  String get cashSheetBody => 'Print the sheet. Each farmer signs when paid in cash.';

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
  String get blockMilkBody => 'FarmTap will block her milk and remind you when it\'s safe.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count bottles', one: '1 bottle');
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
  String get keepMilkSeparateBody => 'Do not sell or mix this milk until the date shown.';

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
  String get breedingTip => 'Check heat signs morning and evening. A missed heat costs about 21 days of milk.';

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
  String get signOutBody => 'Records on this phone stay saved. Sign in again to see them.';

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
  String get resetPinBody => 'They choose a new 4-digit PIN the next time they tap their card.';

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
  String get locationOff => 'Turn on location in your phone settings, or pick the district.';

  @override
  String get locationDenied => 'Location is not allowed. Pick the district from the list.';

  @override
  String get locationNotFound => 'Could not find your district. Pick it from the list.';

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
  String get jobHelper => 'Pick one or type your own, e.g. “Farmer\'s daughter”';

  @override
  String get accessLabel => 'What they can do in FarmTap';

  @override
  String get phoneOptional => 'Phone number (optional)';

  @override
  String get wageOptional => 'Monthly pay (optional)';

  @override
  String get cardForWorker => 'Their card';

  @override
  String get cardForWorkerHelp => 'Hold their FarmTap card to the back of the phone, or type the number printed on it.';

  @override
  String cardReadNumber(String number) {
    return 'Card $number';
  }

  @override
  String get changeCard => 'Change';

  @override
  String get noCardYet => 'No card yet: give one later from the worker\'s page.';

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
  String get farmCreateFailed => 'Could not create the farm. Check the internet and try again.';

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
  String get helpIntro => 'Stuck or have a question? Talk to the FarmTap team. We answer in English.';

  @override
  String get helpWhatsapp => 'Chat on WhatsApp';

  @override
  String get helpWhatsappSub => 'Fastest; send a screenshot if something looks wrong';

  @override
  String get helpCall => 'Call us';

  @override
  String get helpSms => 'Send an SMS';

  @override
  String get helpOpenFailed => 'Could not open that on this phone.';

  @override
  String get authNoInternet => 'No internet. Connect and try again.';

  @override
  String get authProviderOff => 'This sign-in method is not switched on for FarmTap yet. Use Google or email for now.';

  @override
  String get authOtherMethod => 'This email already uses another sign-in. Use Google or email.';

  @override
  String get authEmailInUse => 'An account with this email already exists. Sign in instead.';

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
  String get passwordWeak => 'Add a capital letter, a small letter and a number.';

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
  String get smsNumberHelp => 'Alerts go here. It can be a different line from WhatsApp.';

  @override
  String get signInPointOffline => 'Works with no network';

  @override
  String get signInPointCards => 'Tap cards for staff and farmers';

  @override
  String get signInPointAll => 'Milk, health and money in one place';

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
  String get newCardOnCollect => 'No farmer has this card yet. Add the farmer now and the card is theirs.';

  @override
  String get addFarmerWithCard => 'Add farmer with this card';

  @override
  String get newCardOnAttendance => 'No worker has this card yet. Give it to a worker, then tap again to clock in.';

  @override
  String get giveCardToWorker => 'Give it to a worker';

  @override
  String farmerCardOnAttendance(String name) {
    return 'This is $name\'s farmer card. Worker cards clock in here.';
  }

  @override
  String get typeCardNumberLink => 'Type the card number';
}
