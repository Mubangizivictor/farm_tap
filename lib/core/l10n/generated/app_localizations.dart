import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nyn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('nyn')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FarmTap'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @tapCard.
  ///
  /// In en, this message translates to:
  /// **'Tap card'**
  String get tapCard;

  /// No description provided for @herd.
  ///
  /// In en, this message translates to:
  /// **'Herd'**
  String get herd;

  /// No description provided for @milk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get milk;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @addAnimal.
  ///
  /// In en, this message translates to:
  /// **'Add Animal'**
  String get addAnimal;

  /// No description provided for @tagNumber.
  ///
  /// In en, this message translates to:
  /// **'Tag Number'**
  String get tagNumber;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @breed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breed;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct?'**
  String get correct;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search animals, farmers, records'**
  String get searchHint;

  /// No description provided for @allRecordsSynced.
  ///
  /// In en, this message translates to:
  /// **'All records synced'**
  String get allRecordsSynced;

  /// No description provided for @recordsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to sync'**
  String recordsWaiting(int count);

  /// No description provided for @syncFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailedShort;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @trialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Free trial: {days} days left'**
  String trialDaysLeft(int days);

  /// No description provided for @trialDaysLeftShort.
  ///
  /// In en, this message translates to:
  /// **'Free trial · {days} days left'**
  String trialDaysLeftShort(int days);

  /// No description provided for @trialThenPrice.
  ///
  /// In en, this message translates to:
  /// **'Then UGX 70,000 a month. Pay anytime with Mobile Money.'**
  String get trialThenPrice;

  /// No description provided for @trialUpgradeLine.
  ///
  /// In en, this message translates to:
  /// **'Upgrade · UGX 70,000/mo'**
  String get trialUpgradeLine;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Records are saved on this phone and will sync when you are online.'**
  String get offlineBannerBody;

  /// No description provided for @emptyDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyDefaultTitle;

  /// No description provided for @errorDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorDefaultTitle;

  /// No description provided for @errorDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Your data on this phone is safe.'**
  String get errorDefaultBody;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOfTotal(int step, int total);

  /// No description provided for @switchFarm.
  ///
  /// In en, this message translates to:
  /// **'Switch farm'**
  String get switchFarm;

  /// No description provided for @keypadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get keypadBackspace;

  /// No description provided for @keypadDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get keypadDecimal;

  /// No description provided for @uiGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'UI Gallery'**
  String get uiGalleryTitle;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @farmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmers;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @collectionCentre.
  ///
  /// In en, this message translates to:
  /// **'Collection centre'**
  String get collectionCentre;

  /// No description provided for @feeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get feeding;

  /// No description provided for @breeding.
  ///
  /// In en, this message translates to:
  /// **'Breeding'**
  String get breeding;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @isThisCorrect.
  ///
  /// In en, this message translates to:
  /// **'Is this correct?'**
  String get isThisCorrect;

  /// No description provided for @yesSave.
  ///
  /// In en, this message translates to:
  /// **'Yes, save'**
  String get yesSave;

  /// No description provided for @noChangeIt.
  ///
  /// In en, this message translates to:
  /// **'No, change it'**
  String get noChangeIt;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @farmRoleLine.
  ///
  /// In en, this message translates to:
  /// **'{place} · {role}'**
  String farmRoleLine(String place, String role);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Tap. Record. Grow.'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your farm…'**
  String get splashLoading;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FarmTap'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Records for your farm and milk centre — even without network.'**
  String get welcomeBody;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @continueEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueEmail;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRunyankore.
  ///
  /// In en, this message translates to:
  /// **'Runyankore'**
  String get languageRunyankore;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Tap the card, record the work.'**
  String get brandTagline;

  /// No description provided for @brandBody.
  ///
  /// In en, this message translates to:
  /// **'Records for farms and milk centres in Western Uganda — offline, in Runyankore and English.'**
  String get brandBody;

  /// No description provided for @emailSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailSignInTitle;

  /// No description provided for @emailSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the email you signed up with.'**
  String get emailSignInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newToFarmTap.
  ///
  /// In en, this message translates to:
  /// **'New to FarmTap? Create an account'**
  String get newToFarmTap;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong.'**
  String get signInFailed;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll set up your farm next. 14 days free.'**
  String get signUpSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get nameRequired;

  /// No description provided for @emailIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Check the email — it looks incomplete.'**
  String get emailIncomplete;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRule;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @agreeTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Tick the box to agree first.'**
  String get agreeTermsRequired;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to set a new password.'**
  String get resetSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String resetLinkSent(String email);

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. You can keep setting up your farm meanwhile.'**
  String checkEmailBody(String email);

  /// No description provided for @continueSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue setup'**
  String get continueSetup;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @emailSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Email sent again'**
  String get emailSentAgain;

  /// No description provided for @chooseFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a farm'**
  String get chooseFarmTitle;

  /// No description provided for @chooseFarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have access to {count} places.'**
  String chooseFarmSubtitle(int count);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleClerk.
  ///
  /// In en, this message translates to:
  /// **'Milk clerk'**
  String get roleClerk;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get roleWorker;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get statusTrial;

  /// No description provided for @statusReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get statusReadOnly;

  /// No description provided for @trialDaysShort.
  ///
  /// In en, this message translates to:
  /// **'Trial {days} days'**
  String trialDaysShort(int days);

  /// No description provided for @addAnotherFarm.
  ///
  /// In en, this message translates to:
  /// **'Add another farm'**
  String get addAnotherFarm;

  /// No description provided for @somethingWentWrongShort.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Try again.'**
  String get somethingWentWrongShort;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'nyn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nyn':
      return AppLocalizationsNyn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
