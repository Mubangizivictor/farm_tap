// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nyankole (`nyn`).
class AppLocalizationsNyn extends AppLocalizations {
  AppLocalizationsNyn([String locale = 'nyn']) : super(locale);

  @override
  String get appName => '[nyn] FarmTap';

  @override
  String get signIn => '[nyn] Sign in';

  @override
  String get phone => '[nyn] Phone number';

  @override
  String get pin => '[nyn] PIN';

  @override
  String get tapCard => '[nyn] Tap card';

  @override
  String get herd => '[nyn] Herd';

  @override
  String get milk => '[nyn] Milk';

  @override
  String get health => '[nyn] Health';

  @override
  String get more => '[nyn] More';

  @override
  String get addAnimal => '[nyn] Add Animal';

  @override
  String get tagNumber => '[nyn] Tag Number';

  @override
  String get name => '[nyn] Name';

  @override
  String get sex => '[nyn] Sex';

  @override
  String get breed => '[nyn] Breed';

  @override
  String get dateOfBirth => '[nyn] Date of Birth';

  @override
  String get save => '[nyn] Save';

  @override
  String get cancel => '[nyn] Cancel';

  @override
  String get male => '[nyn] Male';

  @override
  String get female => '[nyn] Female';

  @override
  String get correct => '[nyn] Correct?';

  @override
  String get yes => '[nyn] Yes';

  @override
  String get no => '[nyn] No';

  @override
  String get searchHint => '[nyn] Search animals, farmers, records';

  @override
  String get allRecordsSynced => '[nyn] All records synced';

  @override
  String recordsWaiting(int count) {
    return '[nyn] $count waiting to sync';
  }

  @override
  String get syncFailedShort => '[nyn] Sync failed';

  @override
  String get notifications => '[nyn] Notifications';

  @override
  String get back => '[nyn] Back';

  @override
  String get close => '[nyn] Close';

  @override
  String get undo => '[nyn] Undo';

  @override
  String get tryAgain => '[nyn] Try again';

  @override
  String get payNow => '[nyn] Pay now';

  @override
  String trialDaysLeft(int days) {
    return '[nyn] Free trial: $days days left';
  }

  @override
  String trialDaysLeftShort(int days) {
    return '[nyn] Free trial · $days days left';
  }

  @override
  String get trialThenPrice => '[nyn] Then UGX 70,000 a month. Pay anytime with Mobile Money.';

  @override
  String get trialUpgradeLine => '[nyn] Upgrade · UGX 70,000/mo';

  @override
  String get offlineBannerTitle => '[nyn] You are offline';

  @override
  String get offlineBannerBody => '[nyn] Records are saved on this phone and will sync when you are online.';

  @override
  String get emptyDefaultTitle => '[nyn] Nothing here yet';

  @override
  String get errorDefaultTitle => '[nyn] Something went wrong';

  @override
  String get errorDefaultBody => '[nyn] Your data on this phone is safe.';

  @override
  String get continueLabel => '[nyn] Continue';

  @override
  String stepOfTotal(int step, int total) {
    return '[nyn] Step $step of $total';
  }

  @override
  String get switchFarm => '[nyn] Switch farm';

  @override
  String get keypadBackspace => '[nyn] Delete last digit';

  @override
  String get keypadDecimal => '[nyn] Decimal point';

  @override
  String get uiGalleryTitle => '[nyn] UI Gallery';

  @override
  String get all => '[nyn] All';

  @override
  String get home => '[nyn] Home';

  @override
  String get collect => '[nyn] Collect';

  @override
  String get farmers => '[nyn] Farmers';

  @override
  String get pay => '[nyn] Pay';

  @override
  String get collectionCentre => '[nyn] Collection centre';

  @override
  String get feeding => '[nyn] Feeding';

  @override
  String get breeding => '[nyn] Breeding';

  @override
  String get workers => '[nyn] Workers';

  @override
  String get money => '[nyn] Money';

  @override
  String get reports => '[nyn] Reports';

  @override
  String get settings => '[nyn] Settings';

  @override
  String get isThisCorrect => '[nyn] Is this correct?';

  @override
  String get yesSave => '[nyn] Yes, save';

  @override
  String get noChangeIt => '[nyn] No, change it';

  @override
  String get skip => '[nyn] Skip';

  @override
  String get menu => '[nyn] Menu';

  @override
  String get seeAll => '[nyn] See all';

  @override
  String get profile => '[nyn] Profile';

  @override
  String get comingSoon => '[nyn] Coming soon';

  @override
  String farmRoleLine(String place, String role) {
    return '[nyn] $place · $role';
  }
}
