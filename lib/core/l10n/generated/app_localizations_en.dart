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
    return 'Free trial: $days days left';
  }

  @override
  String trialDaysLeftShort(int days) {
    return 'Free trial · $days days left';
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
  String get languageEnglish => 'English';

  @override
  String get languageRunyankore => 'Runyankore';

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
    return 'Trial $days days';
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
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageSubtitle =>
      'Hitamu orurimi. You can change it later.';

  @override
  String get runyankoreSubtitle => 'Orurimi rw\'Ankole';

  @override
  String get englishSubtitle => 'Use the app in English';

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
    return 'Your 14 free days start today and end on $date. After that FarmTap is UGX 70,000 a month.';
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
}
