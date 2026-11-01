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
}
