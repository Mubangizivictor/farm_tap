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

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'What you typed on this screen will be lost.'**
  String get discardBody;

  /// No description provided for @discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardConfirm;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hitamu orurimi. You can change it later.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @runyankoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orurimi rw\'Ankole'**
  String get runyankoreSubtitle;

  /// No description provided for @englishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the app in English'**
  String get englishSubtitle;

  /// No description provided for @sectorTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you do?'**
  String get sectorTitle;

  /// No description provided for @sectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your main work. Dairy is ready now.'**
  String get sectorSubtitle;

  /// No description provided for @sectorDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy (cattle)'**
  String get sectorDairy;

  /// No description provided for @sectorDairySub.
  ///
  /// In en, this message translates to:
  /// **'Farms and milk collection centres'**
  String get sectorDairySub;

  /// No description provided for @sectorPoultry.
  ///
  /// In en, this message translates to:
  /// **'Poultry'**
  String get sectorPoultry;

  /// No description provided for @sectorPoultrySub.
  ///
  /// In en, this message translates to:
  /// **'Layers, broilers, eggs'**
  String get sectorPoultrySub;

  /// No description provided for @sectorPiggery.
  ///
  /// In en, this message translates to:
  /// **'Piggery'**
  String get sectorPiggery;

  /// No description provided for @sectorPiggerySub.
  ///
  /// In en, this message translates to:
  /// **'Sows, piglets, sales'**
  String get sectorPiggerySub;

  /// No description provided for @sectorGoats.
  ///
  /// In en, this message translates to:
  /// **'Goats & sheep'**
  String get sectorGoats;

  /// No description provided for @sectorCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops & produce buying'**
  String get sectorCrops;

  /// No description provided for @sectorCropsSub.
  ///
  /// In en, this message translates to:
  /// **'Coffee, matooke, maize'**
  String get sectorCropsSub;

  /// No description provided for @sectorFish.
  ///
  /// In en, this message translates to:
  /// **'Fish farming'**
  String get sectorFish;

  /// No description provided for @waitlistTitle.
  ///
  /// In en, this message translates to:
  /// **'{sector} is coming soon'**
  String waitlistTitle(String sector);

  /// No description provided for @waitlistBody.
  ///
  /// In en, this message translates to:
  /// **'Join the waitlist and we\'ll message you the day it\'s ready. No payment needed.'**
  String get waitlistBody;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get whatsappLabel;

  /// No description provided for @joinWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Join the waitlist'**
  String get joinWaitlist;

  /// No description provided for @waitlistDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the list!'**
  String get waitlistDoneTitle;

  /// No description provided for @waitlistDoneBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll WhatsApp you when {sector} opens in FarmTap. Thank you, {name}.'**
  String waitlistDoneBody(String sector, String name);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dairyTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of dairy?'**
  String get dairyTypeTitle;

  /// No description provided for @dairyTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This decides your home screen. You can add the other later.'**
  String get dairyTypeSubtitle;

  /// No description provided for @dairyFarm.
  ///
  /// In en, this message translates to:
  /// **'Dairy farm'**
  String get dairyFarm;

  /// No description provided for @dairyFarmSub.
  ///
  /// In en, this message translates to:
  /// **'I keep cows and record milk, health, feeding'**
  String get dairyFarmSub;

  /// No description provided for @centreOption.
  ///
  /// In en, this message translates to:
  /// **'Milk collection centre'**
  String get centreOption;

  /// No description provided for @centreOptionSub.
  ///
  /// In en, this message translates to:
  /// **'Farmers bring milk to me'**
  String get centreOptionSub;

  /// No description provided for @bothOption.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get bothOption;

  /// No description provided for @bothOptionSub.
  ///
  /// In en, this message translates to:
  /// **'Farm and collection centre'**
  String get bothOptionSub;

  /// No description provided for @farmDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'About your farm'**
  String get farmDetailsTitle;

  /// No description provided for @farmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmNameLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village / parish'**
  String get villageLabel;

  /// No description provided for @herdSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'How many cows?'**
  String get herdSizeLabel;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we send reports?'**
  String get contactsTitle;

  /// No description provided for @contactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily farm reports go to WhatsApp. Alerts and reminders go by SMS.'**
  String get contactsSubtitle;

  /// No description provided for @dailyReportTime.
  ///
  /// In en, this message translates to:
  /// **'Daily report at 7:00 pm'**
  String get dailyReportTime;

  /// No description provided for @smsSameAsWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'SMS number is the same as WhatsApp'**
  String get smsSameAsWhatsapp;

  /// No description provided for @smsNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS number'**
  String get smsNumberLabel;

  /// No description provided for @sendDailyWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send me the daily report on WhatsApp'**
  String get sendDailyWhatsapp;

  /// No description provided for @sendSmsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Send me SMS alerts (sick cows, low stock, trial)'**
  String get sendSmsAlerts;

  /// No description provided for @roleTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your role?'**
  String get roleTitle;

  /// No description provided for @roleOwnerSub.
  ///
  /// In en, this message translates to:
  /// **'I own the farm and pay for FarmTap'**
  String get roleOwnerSub;

  /// No description provided for @roleManagerSub.
  ///
  /// In en, this message translates to:
  /// **'I run the farm for the owner'**
  String get roleManagerSub;

  /// No description provided for @firstStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first worker'**
  String get firstStaffTitle;

  /// No description provided for @firstStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workers use a card and a 4-digit PIN — no email needed.'**
  String get firstStaffSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleHerdsman.
  ///
  /// In en, this message translates to:
  /// **'Herdsman'**
  String get roleHerdsman;

  /// No description provided for @roleVet.
  ///
  /// In en, this message translates to:
  /// **'Vet'**
  String get roleVet;

  /// No description provided for @choosePin.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get choosePin;

  /// No description provided for @choosePinHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose the PIN'**
  String get choosePinHint;

  /// No description provided for @nfcLaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Add an NFC card later'**
  String get nfcLaterTitle;

  /// No description provided for @nfcLaterBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Assign card\' on the worker\'s page when cards arrive.'**
  String get nfcLaterBody;

  /// No description provided for @saveWorker.
  ///
  /// In en, this message translates to:
  /// **'Save worker'**
  String get saveWorker;

  /// No description provided for @farmReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your farm is ready!'**
  String get farmReadyTitle;

  /// No description provided for @farmReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your 14 free days start today and end on {date}. After that FarmTap is UGX 70,000 a month.'**
  String farmReadyBody(String date);

  /// No description provided for @summaryFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get summaryFarm;

  /// No description provided for @summaryPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get summaryPlan;

  /// No description provided for @summaryFreeUntil.
  ///
  /// In en, this message translates to:
  /// **'Free until'**
  String get summaryFreeUntil;

  /// No description provided for @planDairy.
  ///
  /// In en, this message translates to:
  /// **'FarmTap Dairy'**
  String get planDairy;

  /// No description provided for @startUsingFarmTap.
  ///
  /// In en, this message translates to:
  /// **'Start using FarmTap'**
  String get startUsingFarmTap;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @phoneIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Check the number — it needs 9 digits after +256.'**
  String get phoneIncomplete;

  /// No description provided for @farmNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the farm name.'**
  String get farmNameRequired;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN.'**
  String get pinRequired;

  /// No description provided for @herd1to10.
  ///
  /// In en, this message translates to:
  /// **'1–10'**
  String get herd1to10;

  /// No description provided for @herd11to30.
  ///
  /// In en, this message translates to:
  /// **'11–30'**
  String get herd11to30;

  /// No description provided for @herd31to100.
  ///
  /// In en, this message translates to:
  /// **'31–100'**
  String get herd31to100;

  /// No description provided for @herdOver100.
  ///
  /// In en, this message translates to:
  /// **'100+'**
  String get herdOver100;

  /// No description provided for @phonePrefix.
  ///
  /// In en, this message translates to:
  /// **'+256 '**
  String get phonePrefix;

  /// No description provided for @pinChosen.
  ///
  /// In en, this message translates to:
  /// **'PIN chosen'**
  String get pinChosen;

  /// No description provided for @roleMilkClerk.
  ///
  /// In en, this message translates to:
  /// **'Milk clerk'**
  String get roleMilkClerk;

  /// No description provided for @tapYourCard.
  ///
  /// In en, this message translates to:
  /// **'Tap your card'**
  String get tapYourCard;

  /// No description provided for @tapYourCardBody.
  ///
  /// In en, this message translates to:
  /// **'Hold your FarmTap card on the back of the phone.'**
  String get tapYourCardBody;

  /// No description provided for @enterCardInstead.
  ///
  /// In en, this message translates to:
  /// **'Enter card number instead'**
  String get enterCardInstead;

  /// No description provided for @ownerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Owner sign-in'**
  String get ownerSignIn;

  /// No description provided for @switchFarm2.
  ///
  /// In en, this message translates to:
  /// **'Switch farm'**
  String get switchFarm2;

  /// No description provided for @simulateTap.
  ///
  /// In en, this message translates to:
  /// **'Simulate tap (debug)'**
  String get simulateTap;

  /// No description provided for @cardNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your card number'**
  String get cardNumberTitle;

  /// No description provided for @cardNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s printed on the front of your card.'**
  String get cardNumberSubtitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @cardNotFound.
  ///
  /// In en, this message translates to:
  /// **'No worker has this card. Check the number.'**
  String get cardNotFound;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get enterPin;

  /// No description provided for @wrongPinTries.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. {count} tries left.'**
  String wrongPinTries(int count);

  /// No description provided for @cardLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. This card is locked for 5 minutes.'**
  String get cardLocked;

  /// No description provided for @notYou.
  ///
  /// In en, this message translates to:
  /// **'Not {name}? Tap a different card'**
  String notYou(String name);

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Ask the farm manager to reset it.'**
  String get forgotPin;

  /// No description provided for @nfcOffTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC is turned off'**
  String get nfcOffTitle;

  /// No description provided for @nfcOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on NFC in your phone settings to use cards, or type the card number.'**
  String get nfcOffBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @typeCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Type card number'**
  String get typeCardNumber;
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
