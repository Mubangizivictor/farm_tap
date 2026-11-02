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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nyn'),
  ];

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
  /// **'Free trial: {days, plural, =1{1 day} other{{days} days}} left'**
  String trialDaysLeft(int days);

  /// No description provided for @trialDaysLeftShort.
  ///
  /// In en, this message translates to:
  /// **'Free trial · {days, plural, =1{1 day} other{{days} days}} left'**
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
  /// **'Trial {days, plural, =1{1 day} other{{days} days}}'**
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

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @farmAndDate.
  ///
  /// In en, this message translates to:
  /// **'{farm} · {date}'**
  String farmAndDate(String farm, String date);

  /// No description provided for @milkToday.
  ///
  /// In en, this message translates to:
  /// **'Milk today'**
  String get milkToday;

  /// No description provided for @cows.
  ///
  /// In en, this message translates to:
  /// **'Cows'**
  String get cows;

  /// No description provided for @milkingDry.
  ///
  /// In en, this message translates to:
  /// **'{milking} milking · {dry} dry'**
  String milkingDry(int milking, int dry);

  /// No description provided for @underTreatment.
  ///
  /// In en, this message translates to:
  /// **'Under treatment'**
  String get underTreatment;

  /// No description provided for @notForSaleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} not for sale'**
  String notForSaleCount(int count);

  /// No description provided for @workersIn.
  ///
  /// In en, this message translates to:
  /// **'Workers in'**
  String get workersIn;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @recordMilk.
  ///
  /// In en, this message translates to:
  /// **'Record milk'**
  String get recordMilk;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @milkThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Milk this week'**
  String get milkThisWeek;

  /// No description provided for @litreUnit.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get litreUnit;

  /// No description provided for @helloStaff.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloStaff(String name);

  /// No description provided for @clockedIn.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at {time} · {role}'**
  String clockedIn(String time, String role);

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @whatAreYouDoing.
  ///
  /// In en, this message translates to:
  /// **'What are you doing?'**
  String get whatAreYouDoing;

  /// No description provided for @morningSession.
  ///
  /// In en, this message translates to:
  /// **'Morning session'**
  String get morningSession;

  /// No description provided for @eveningSession.
  ///
  /// In en, this message translates to:
  /// **'Evening session'**
  String get eveningSession;

  /// No description provided for @groupsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} groups left'**
  String groupsLeft(int count);

  /// No description provided for @giveTreatment.
  ///
  /// In en, this message translates to:
  /// **'Give treatment'**
  String get giveTreatment;

  /// No description provided for @dueNow.
  ///
  /// In en, this message translates to:
  /// **'{count} due now'**
  String dueNow(int count);

  /// No description provided for @dipping.
  ///
  /// In en, this message translates to:
  /// **'Dipping'**
  String get dipping;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {day}'**
  String dueOn(String day);

  /// No description provided for @heatService.
  ///
  /// In en, this message translates to:
  /// **'Heat / service'**
  String get heatService;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @photoNote.
  ///
  /// In en, this message translates to:
  /// **'Photo + note'**
  String get photoNote;

  /// No description provided for @myTasksToday.
  ///
  /// In en, this message translates to:
  /// **'My tasks today'**
  String get myTasksToday;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get filterHealth;

  /// No description provided for @filterMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get filterMilk;

  /// No description provided for @filterStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get filterStock;

  /// No description provided for @filterMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get filterMoney;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusTitle;

  /// No description provided for @syncStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Records are saved on this phone first, then sent to the cloud.'**
  String get syncStatusBody;

  /// No description provided for @syncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedLabel;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(String count);

  /// No description provided for @waitingToSend.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get waitingToSend;

  /// No description provided for @milkRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} milk records'**
  String milkRecordsCount(int count);

  /// No description provided for @failedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedLabel;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @youreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get youreOffline;

  /// No description provided for @offlineKeepRecording.
  ///
  /// In en, this message translates to:
  /// **'Keep recording — everything is saved on this phone and will sync when network returns.'**
  String get offlineKeepRecording;

  /// No description provided for @getReminders.
  ///
  /// In en, this message translates to:
  /// **'Get reminders?'**
  String get getReminders;

  /// No description provided for @getRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'FarmTap reminds you about calvings, vaccinations and when treated milk is safe again.'**
  String get getRemindersBody;

  /// No description provided for @allowReminders.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders'**
  String get allowReminders;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @syncStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusOpen;

  /// No description provided for @attnNotForSale.
  ///
  /// In en, this message translates to:
  /// **'{name} — milk not for sale'**
  String attnNotForSale(String name);

  /// No description provided for @attnSafeFrom.
  ///
  /// In en, this message translates to:
  /// **'{drug} · safe from {date}'**
  String attnSafeFrom(String drug, String date);

  /// No description provided for @attnMilkDrop.
  ///
  /// In en, this message translates to:
  /// **'Milk dropped {percent}% — {name}'**
  String attnMilkDrop(int percent, String name);

  /// No description provided for @attnMilkDropSub.
  ///
  /// In en, this message translates to:
  /// **'{today} L today vs {average} L average'**
  String attnMilkDropSub(String today, String average);

  /// No description provided for @attnCalving.
  ///
  /// In en, this message translates to:
  /// **'Calving due: {name}'**
  String attnCalving(String name);

  /// No description provided for @attnInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days · {date}'**
  String attnInDays(int days, String date);

  /// No description provided for @attnStockLow.
  ///
  /// In en, this message translates to:
  /// **'{item} is running low'**
  String attnStockLow(String item);

  /// No description provided for @attnBagsLeft.
  ///
  /// In en, this message translates to:
  /// **'{bags} bags left · about {days} days'**
  String attnBagsLeft(int bags, int days);

  /// No description provided for @attnEdited.
  ///
  /// In en, this message translates to:
  /// **'Record edited after closing'**
  String get attnEdited;

  /// No description provided for @attnEditedSub.
  ///
  /// In en, this message translates to:
  /// **'{person} · {session} session · {time}'**
  String attnEditedSub(String person, String session, String time);

  /// No description provided for @attnTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends in {days} days'**
  String attnTrialEnds(int days);

  /// No description provided for @attnTrialPay.
  ///
  /// In en, this message translates to:
  /// **'Pay UGX 70,000 to keep recording'**
  String get attnTrialPay;

  /// No description provided for @sessionAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get sessionAm;

  /// No description provided for @sessionPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get sessionPm;

  /// No description provided for @taskBefore.
  ///
  /// In en, this message translates to:
  /// **'Before {time}'**
  String taskBefore(String time);

  /// No description provided for @taskAfterEveningMilking.
  ///
  /// In en, this message translates to:
  /// **'After evening milking'**
  String get taskAfterEveningMilking;

  /// No description provided for @dairyMeal.
  ///
  /// In en, this message translates to:
  /// **'Dairy meal'**
  String get dairyMeal;

  /// No description provided for @animalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} animals'**
  String animalsCount(int count);

  /// No description provided for @scanTag.
  ///
  /// In en, this message translates to:
  /// **'Scan ear tag'**
  String get scanTag;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @searchAnimals.
  ///
  /// In en, this message translates to:
  /// **'Search by name or tag number'**
  String get searchAnimals;

  /// No description provided for @statusMilking.
  ///
  /// In en, this message translates to:
  /// **'Milking'**
  String get statusMilking;

  /// No description provided for @statusDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get statusDry;

  /// No description provided for @statusTreated.
  ///
  /// In en, this message translates to:
  /// **'Treated'**
  String get statusTreated;

  /// No description provided for @statusPregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get statusPregnant;

  /// No description provided for @statusHeifer.
  ///
  /// In en, this message translates to:
  /// **'Heifer'**
  String get statusHeifer;

  /// No description provided for @statusCalf.
  ///
  /// In en, this message translates to:
  /// **'Calf'**
  String get statusCalf;

  /// No description provided for @statusBull.
  ///
  /// In en, this message translates to:
  /// **'Bull'**
  String get statusBull;

  /// No description provided for @filterCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get filterCalves;

  /// No description provided for @tagAndBreedAge.
  ///
  /// In en, this message translates to:
  /// **'{tag} · {breed} · {age} yrs'**
  String tagAndBreedAge(String tag, String breed, int age);

  /// No description provided for @breedAge.
  ///
  /// In en, this message translates to:
  /// **'{breed} · {age} yrs'**
  String breedAge(String breed, int age);

  /// No description provided for @colAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get colAnimal;

  /// No description provided for @colTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get colTag;

  /// No description provided for @colBreedAge.
  ///
  /// In en, this message translates to:
  /// **'Breed & age'**
  String get colBreedAge;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colMilkToday.
  ///
  /// In en, this message translates to:
  /// **'Milk today'**
  String get colMilkToday;

  /// No description provided for @notForSale.
  ///
  /// In en, this message translates to:
  /// **'Not for sale'**
  String get notForSale;

  /// No description provided for @addAnimal2.
  ///
  /// In en, this message translates to:
  /// **'Add animal'**
  String get addAnimal2;

  /// No description provided for @filterAnimals.
  ///
  /// In en, this message translates to:
  /// **'Filter animals'**
  String get filterAnimals;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get sortTag;

  /// No description provided for @sortMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get sortMilk;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @showAnimals.
  ///
  /// In en, this message translates to:
  /// **'Show {count} animals'**
  String showAnimals(int count);

  /// No description provided for @calfPen.
  ///
  /// In en, this message translates to:
  /// **'Calf pen'**
  String get calfPen;

  /// No description provided for @animalTitle.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get animalTitle;

  /// No description provided for @printLabels.
  ///
  /// In en, this message translates to:
  /// **'Print ear-tag labels'**
  String get printLabels;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @animalHeaderLine.
  ///
  /// In en, this message translates to:
  /// **'{tag} · {breed} · {kind} · {age} yrs'**
  String animalHeaderLine(String tag, String breed, String kind, int age);

  /// No description provided for @kindCow.
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get kindCow;

  /// No description provided for @kindHeifer.
  ///
  /// In en, this message translates to:
  /// **'Heifer'**
  String get kindHeifer;

  /// No description provided for @kindBull.
  ///
  /// In en, this message translates to:
  /// **'Bull'**
  String get kindBull;

  /// No description provided for @kindCalf.
  ///
  /// In en, this message translates to:
  /// **'Calf'**
  String get kindCalf;

  /// No description provided for @treatedNotForSale.
  ///
  /// In en, this message translates to:
  /// **'Treated — milk not for sale'**
  String get treatedNotForSale;

  /// No description provided for @notForSaleUntil.
  ///
  /// In en, this message translates to:
  /// **'Milk not for sale until {date}'**
  String notForSaleUntil(String date);

  /// No description provided for @withdrawalBody.
  ///
  /// In en, this message translates to:
  /// **'{drug} withdrawal: {days} days left. Milk is recorded as \'not for sale\'.'**
  String withdrawalBody(String drug, int days);

  /// No description provided for @avgMilkDay.
  ///
  /// In en, this message translates to:
  /// **'Avg milk / day'**
  String get avgMilkDay;

  /// No description provided for @daysInMilk.
  ///
  /// In en, this message translates to:
  /// **'Days in milk'**
  String get daysInMilk;

  /// No description provided for @pregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get pregnancy;

  /// No description provided for @pregnancyCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get pregnancyCheck;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDate(String date);

  /// No description provided for @tabTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tabTimeline;

  /// No description provided for @tabMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get tabMilk;

  /// No description provided for @tabHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get tabHealth;

  /// No description provided for @tabBreeding.
  ///
  /// In en, this message translates to:
  /// **'Breeding'**
  String get tabBreeding;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @evTreatment.
  ///
  /// In en, this message translates to:
  /// **'{drug} treatment'**
  String evTreatment(String drug);

  /// No description provided for @evTreatmentSub.
  ///
  /// In en, this message translates to:
  /// **'{reason} · {vet} · safe from {date}'**
  String evTreatmentSub(String reason, String vet, String date);

  /// No description provided for @evMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk {litres} L'**
  String evMilk(String litres);

  /// No description provided for @evMilkSub.
  ///
  /// In en, this message translates to:
  /// **'AM {am} · PM {pm}'**
  String evMilkSub(String am, String pm);

  /// No description provided for @evServed.
  ///
  /// In en, this message translates to:
  /// **'Served — {method}'**
  String evServed(String method);

  /// No description provided for @evServedSub.
  ///
  /// In en, this message translates to:
  /// **'Straw: {straw} · {by}'**
  String evServedSub(String straw, String by);

  /// No description provided for @evVaccination.
  ///
  /// In en, this message translates to:
  /// **'{name} vaccination'**
  String evVaccination(String name);

  /// No description provided for @evBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch}'**
  String evBatch(String batch);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded here yet'**
  String get noEventsYet;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @tagNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag number'**
  String get tagNumberLabel;

  /// No description provided for @breedLabel.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breedLabel;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dobLabel;

  /// No description provided for @sexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexLabel;

  /// No description provided for @sexCowHeifer.
  ///
  /// In en, this message translates to:
  /// **'Cow / heifer'**
  String get sexCowHeifer;

  /// No description provided for @nationalTagLabel.
  ///
  /// In en, this message translates to:
  /// **'National livestock tag number'**
  String get nationalTagLabel;

  /// No description provided for @motherOptional.
  ///
  /// In en, this message translates to:
  /// **'Mother (optional)'**
  String get motherOptional;

  /// No description provided for @saveAnimal.
  ///
  /// In en, this message translates to:
  /// **'Save animal'**
  String get saveAnimal;

  /// No description provided for @animalSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} added to the herd'**
  String animalSaved(String name);

  /// No description provided for @tagRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the tag number.'**
  String get tagRequired;

  /// No description provided for @pointAtQr.
  ///
  /// In en, this message translates to:
  /// **'Point at the QR code on the ear tag'**
  String get pointAtQr;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get torch;

  /// No description provided for @typeTagInstead.
  ///
  /// In en, this message translates to:
  /// **'Type tag number instead'**
  String get typeTagInstead;

  /// No description provided for @recordFor.
  ///
  /// In en, this message translates to:
  /// **'Record for {name}'**
  String recordFor(String name);

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @evKindMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get evKindMilk;

  /// No description provided for @evKindTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get evKindTreatment;

  /// No description provided for @evKindHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat / service'**
  String get evKindHeat;

  /// No description provided for @evKindCalving.
  ///
  /// In en, this message translates to:
  /// **'Calving'**
  String get evKindCalving;

  /// No description provided for @evKindSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get evKindSold;

  /// No description provided for @evKindDied.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get evKindDied;

  /// No description provided for @welcomeLittleOne.
  ///
  /// In en, this message translates to:
  /// **'Welcome, little one!'**
  String get welcomeLittleOne;

  /// No description provided for @calfBornBody.
  ///
  /// In en, this message translates to:
  /// **'{mother} had a heifer calf. We added her to your herd as {tag}.'**
  String calfBornBody(String mother, String tag);

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @born.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get born;

  /// No description provided for @calf.
  ///
  /// In en, this message translates to:
  /// **'Calf'**
  String get calf;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(String time);

  /// No description provided for @heiferTag.
  ///
  /// In en, this message translates to:
  /// **'Heifer · {tag}'**
  String heiferTag(String tag);

  /// No description provided for @nameTheCalf.
  ///
  /// In en, this message translates to:
  /// **'Name the calf'**
  String get nameTheCalf;

  /// No description provided for @recordDeathTitle.
  ///
  /// In en, this message translates to:
  /// **'Record {name} as dead?'**
  String recordDeathTitle(String name);

  /// No description provided for @recordDeathBody.
  ///
  /// In en, this message translates to:
  /// **'She will move to \'Past animals\'. Her records are kept. This is sent to the owner\'s daily report.'**
  String get recordDeathBody;

  /// No description provided for @causeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. East Coast Fever'**
  String get causeHint;

  /// No description provided for @causeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cause (optional)'**
  String get causeLabel;

  /// No description provided for @yesRecordDeath.
  ///
  /// In en, this message translates to:
  /// **'Yes, record death'**
  String get yesRecordDeath;

  /// No description provided for @headCount.
  ///
  /// In en, this message translates to:
  /// **'Head count'**
  String get headCount;

  /// No description provided for @totalAnimals.
  ///
  /// In en, this message translates to:
  /// **'Total animals'**
  String get totalAnimals;

  /// No description provided for @milkingCows.
  ///
  /// In en, this message translates to:
  /// **'Milking cows'**
  String get milkingCows;

  /// No description provided for @dryCows.
  ///
  /// In en, this message translates to:
  /// **'Dry cows'**
  String get dryCows;

  /// No description provided for @heifers.
  ///
  /// In en, this message translates to:
  /// **'Heifers'**
  String get heifers;

  /// No description provided for @calves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get calves;

  /// No description provided for @bulls.
  ///
  /// In en, this message translates to:
  /// **'Bulls'**
  String get bulls;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @bornCount.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get bornCount;

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get bought;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @died.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get died;

  /// No description provided for @labelsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} labels selected'**
  String labelsSelected(int count);

  /// No description provided for @labelsHint.
  ///
  /// In en, this message translates to:
  /// **'Print on sticker paper and fix to the ear tags.'**
  String get labelsHint;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @emptyHerdTitle.
  ///
  /// In en, this message translates to:
  /// **'No cows yet'**
  String get emptyHerdTitle;

  /// No description provided for @emptyHerdBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first cow to start recording milk.'**
  String get emptyHerdBody;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No animals match this filter.'**
  String get noMatches;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @dayTotal.
  ///
  /// In en, this message translates to:
  /// **'Day total'**
  String get dayTotal;

  /// No description provided for @pickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get pickDay;

  /// No description provided for @sessionLabel.
  ///
  /// In en, this message translates to:
  /// **'{session} session'**
  String sessionLabel(String session);

  /// No description provided for @fromCows.
  ///
  /// In en, this message translates to:
  /// **'from {done} of {total} cows'**
  String fromCows(int done, int total);

  /// No description provided for @cowsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Cows recorded'**
  String get cowsRecorded;

  /// No description provided for @countOf.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String countOf(int done, int total);

  /// No description provided for @justRecorded.
  ///
  /// In en, this message translates to:
  /// **'Just recorded'**
  String get justRecorded;

  /// No description provided for @checkThese.
  ///
  /// In en, this message translates to:
  /// **'Check these'**
  String get checkThese;

  /// No description provided for @notForSaleUntilShort.
  ///
  /// In en, this message translates to:
  /// **'Not for sale until {date}'**
  String notForSaleUntilShort(String date);

  /// No description provided for @notRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get notRecordedYet;

  /// No description provided for @milkTools.
  ///
  /// In en, this message translates to:
  /// **'Milk tools'**
  String get milkTools;

  /// No description provided for @quickTotal.
  ///
  /// In en, this message translates to:
  /// **'Quick total'**
  String get quickTotal;

  /// No description provided for @milkUse.
  ///
  /// In en, this message translates to:
  /// **'Milk use'**
  String get milkUse;

  /// No description provided for @milkSales.
  ///
  /// In en, this message translates to:
  /// **'Milk sales'**
  String get milkSales;

  /// No description provided for @milkTrends.
  ///
  /// In en, this message translates to:
  /// **'Milk trends'**
  String get milkTrends;

  /// No description provided for @searchCow.
  ///
  /// In en, this message translates to:
  /// **'Search cow or scan tag'**
  String get searchCow;

  /// No description provided for @notRecordedCount.
  ///
  /// In en, this message translates to:
  /// **'Not recorded {count}'**
  String notRecordedCount(int count);

  /// No description provided for @allCount.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String allCount(int count);

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get recorded;

  /// No description provided for @howManyLitres.
  ///
  /// In en, this message translates to:
  /// **'How many litres?'**
  String get howManyLitres;

  /// No description provided for @lastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time: {litres} L'**
  String lastTime(String litres);

  /// No description provided for @litresValue.
  ///
  /// In en, this message translates to:
  /// **'{litres} litres'**
  String litresValue(String litres);

  /// No description provided for @recordedBy.
  ///
  /// In en, this message translates to:
  /// **'{session} · recorded by {name}'**
  String recordedBy(String session, String name);

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @bigMilkBody.
  ///
  /// In en, this message translates to:
  /// **'{litres} L is more than usual for one cow.'**
  String bigMilkBody(String litres);

  /// No description provided for @yesCorrect.
  ///
  /// In en, this message translates to:
  /// **'Yes, it is correct'**
  String get yesCorrect;

  /// No description provided for @savedMilk.
  ///
  /// In en, this message translates to:
  /// **'Saved! {litres} L from {name}'**
  String savedMilk(String litres, String name);

  /// No description provided for @cowsDoneThisSession.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} cows done this {session}. Keep going!'**
  String cowsDoneThisSession(int done, int total, String session);

  /// No description provided for @nextCow.
  ///
  /// In en, this message translates to:
  /// **'Next cow: {name}'**
  String nextCow(String name);

  /// No description provided for @finishSession.
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get finishSession;

  /// No description provided for @allCowsDone.
  ///
  /// In en, this message translates to:
  /// **'All cows recorded'**
  String get allCowsDone;

  /// No description provided for @underTreatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is under treatment'**
  String underTreatmentTitle(String name);

  /// No description provided for @underTreatmentBody.
  ///
  /// In en, this message translates to:
  /// **'{drug} given {given}. Her milk must not be sold until {until}. You can still record it as \'not for sale\'.'**
  String underTreatmentBody(String drug, String given, String until);

  /// No description provided for @recordNotForSale.
  ///
  /// In en, this message translates to:
  /// **'Record as not for sale'**
  String get recordNotForSale;

  /// No description provided for @wholeHerdSession.
  ///
  /// In en, this message translates to:
  /// **'Whole herd · {session}'**
  String wholeHerdSession(String session);

  /// No description provided for @quickMode.
  ///
  /// In en, this message translates to:
  /// **'Quick mode'**
  String get quickMode;

  /// No description provided for @quickModeBody.
  ///
  /// In en, this message translates to:
  /// **'Use this when you can\'t record each cow. Per-cow records give better alerts.'**
  String get quickModeBody;

  /// No description provided for @totalFromAllCows.
  ///
  /// In en, this message translates to:
  /// **'Total litres from all cows this {session}'**
  String totalFromAllCows(String session);

  /// No description provided for @saveTotal.
  ///
  /// In en, this message translates to:
  /// **'Save total'**
  String get saveTotal;

  /// No description provided for @totalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {litres} L for the whole herd'**
  String totalSaved(String litres);

  /// No description provided for @wholeHerd.
  ///
  /// In en, this message translates to:
  /// **'Whole herd'**
  String get wholeHerd;

  /// No description provided for @todayLitres.
  ///
  /// In en, this message translates to:
  /// **'Today · {litres} L'**
  String todayLitres(String litres);

  /// No description provided for @accountedFor.
  ///
  /// In en, this message translates to:
  /// **'Accounted for'**
  String get accountedFor;

  /// No description provided for @useSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get useSold;

  /// No description provided for @useHome.
  ///
  /// In en, this message translates to:
  /// **'Home use'**
  String get useHome;

  /// No description provided for @useCalves.
  ///
  /// In en, this message translates to:
  /// **'Fed to calves'**
  String get useCalves;

  /// No description provided for @useNotForSale.
  ///
  /// In en, this message translates to:
  /// **'Not for sale (treated)'**
  String get useNotForSale;

  /// No description provided for @useSpoiled.
  ///
  /// In en, this message translates to:
  /// **'Spoiled'**
  String get useSpoiled;

  /// No description provided for @useSaved.
  ///
  /// In en, this message translates to:
  /// **'Milk use saved'**
  String get useSaved;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @soldThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Sold this week'**
  String get soldThisWeek;

  /// No description provided for @owedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get owedToYou;

  /// No description provided for @buyersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} buyers'**
  String buyersCount(int count);

  /// No description provided for @litresTimesPrice.
  ///
  /// In en, this message translates to:
  /// **'{litres} L × {price}'**
  String litresTimesPrice(String litres, String price);

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @colBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get colBuyer;

  /// No description provided for @colLitres.
  ///
  /// In en, this message translates to:
  /// **'Litres'**
  String get colLitres;

  /// No description provided for @colPricePerL.
  ///
  /// In en, this message translates to:
  /// **'Price / L'**
  String get colPricePerL;

  /// No description provided for @colAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get colAmount;

  /// No description provided for @addSale.
  ///
  /// In en, this message translates to:
  /// **'Add sale'**
  String get addSale;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @totalThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total this month'**
  String get totalThisMonth;

  /// No description provided for @totalThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Total this week'**
  String get totalThisWeek;

  /// No description provided for @totalThisYear.
  ///
  /// In en, this message translates to:
  /// **'Total this year'**
  String get totalThisYear;

  /// No description provided for @vsPrevious.
  ///
  /// In en, this message translates to:
  /// **'{change} vs {period}'**
  String vsPrevious(String change, String period);

  /// No description provided for @topCows.
  ///
  /// In en, this message translates to:
  /// **'Top cows'**
  String get topCows;

  /// No description provided for @averagePerDay.
  ///
  /// In en, this message translates to:
  /// **'Average {litres} L / day'**
  String averagePerDay(String litres);

  /// No description provided for @droppingCheckHealth.
  ///
  /// In en, this message translates to:
  /// **'Dropping — check health'**
  String get droppingCheckHealth;

  /// No description provided for @todayVsAvg.
  ///
  /// In en, this message translates to:
  /// **'{today} L today vs {avg} L avg'**
  String todayVsAvg(String today, String avg);

  /// No description provided for @sessionOpenSince.
  ///
  /// In en, this message translates to:
  /// **'{session} session · open since {time}'**
  String sessionOpenSince(String session, String time);

  /// No description provided for @collectedThisSession.
  ///
  /// In en, this message translates to:
  /// **'Collected this {session}'**
  String collectedThisSession(String session);

  /// No description provided for @fromFarmersRejected.
  ///
  /// In en, this message translates to:
  /// **'from {farmers} farmers · {rejected} rejected'**
  String fromFarmersRejected(int farmers, int rejected);

  /// No description provided for @tapFarmerCard.
  ///
  /// In en, this message translates to:
  /// **'Tap farmer card'**
  String get tapFarmerCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// No description provided for @qualityTest.
  ///
  /// In en, this message translates to:
  /// **'Quality test'**
  String get qualityTest;

  /// No description provided for @dispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatch;

  /// No description provided for @closeSession.
  ///
  /// In en, this message translates to:
  /// **'Close session'**
  String get closeSession;

  /// No description provided for @latestDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Latest deliveries'**
  String get latestDeliveries;

  /// No description provided for @timeAndCard.
  ///
  /// In en, this message translates to:
  /// **'{time} · Card {card}'**
  String timeAndCard(String time, String card);

  /// No description provided for @litresByHour.
  ///
  /// In en, this message translates to:
  /// **'Litres by hour'**
  String get litresByHour;

  /// No description provided for @receiveMilk.
  ///
  /// In en, this message translates to:
  /// **'Receive milk'**
  String get receiveMilk;

  /// No description provided for @tapFarmersCard.
  ///
  /// In en, this message translates to:
  /// **'Tap the farmer\'s card'**
  String get tapFarmersCard;

  /// No description provided for @holdCardBack.
  ///
  /// In en, this message translates to:
  /// **'Hold the card on the back of the phone.'**
  String get holdCardBack;

  /// No description provided for @enterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter card number'**
  String get enterCardNumber;

  /// No description provided for @searchFarmerByName.
  ///
  /// In en, this message translates to:
  /// **'Search farmer by name'**
  String get searchFarmerByName;

  /// No description provided for @cardAndVillage.
  ///
  /// In en, this message translates to:
  /// **'Card {card} · {village}'**
  String cardAndVillage(String card, String village);

  /// No description provided for @cardOk.
  ///
  /// In en, this message translates to:
  /// **'Card OK'**
  String get cardOk;

  /// No description provided for @usuallyBrings.
  ///
  /// In en, this message translates to:
  /// **'Usually brings {low}–{high} L'**
  String usuallyBrings(int low, int high);

  /// No description provided for @deliveryDetail.
  ///
  /// In en, this message translates to:
  /// **'{session} · Card {card} · Test: {test}'**
  String deliveryDetail(String session, String card, String test);

  /// No description provided for @testPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get testPassed;

  /// No description provided for @testNotDone.
  ///
  /// In en, this message translates to:
  /// **'not done'**
  String get testNotDone;

  /// No description provided for @tapNextCard.
  ///
  /// In en, this message translates to:
  /// **'Tap the next card'**
  String get tapNextCard;

  /// No description provided for @readyNextFarmer.
  ///
  /// In en, this message translates to:
  /// **'Ready for the next farmer.'**
  String get readyNextFarmer;

  /// No description provided for @lastSaved.
  ///
  /// In en, this message translates to:
  /// **'Last saved'**
  String get lastSaved;

  /// No description provided for @smsQueuedPrintSlip.
  ///
  /// In en, this message translates to:
  /// **'SMS receipt queued · Print slip'**
  String get smsQueuedPrintSlip;

  /// No description provided for @savedForFarmer.
  ///
  /// In en, this message translates to:
  /// **'Saved {litres} L for {name}'**
  String savedForFarmer(String litres, String name);

  /// No description provided for @deliveryUndone.
  ///
  /// In en, this message translates to:
  /// **'Delivery removed'**
  String get deliveryUndone;

  /// No description provided for @suppliersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} suppliers'**
  String suppliersCount(int count);

  /// No description provided for @searchFarmers.
  ///
  /// In en, this message translates to:
  /// **'Search name or card number'**
  String get searchFarmers;

  /// No description provided for @deliveredToday.
  ///
  /// In en, this message translates to:
  /// **'Delivered today {count}'**
  String deliveredToday(int count);

  /// No description provided for @notToday.
  ///
  /// In en, this message translates to:
  /// **'Not today {count}'**
  String notToday(int count);

  /// No description provided for @noCard.
  ///
  /// In en, this message translates to:
  /// **'No card {count}'**
  String noCard(int count);

  /// No description provided for @cardThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Card {card} · this period {litres} L'**
  String cardThisPeriod(String card, String litres);

  /// No description provided for @colFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get colFarmer;

  /// No description provided for @colCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get colCard;

  /// No description provided for @colToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get colToday;

  /// No description provided for @colThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get colThisPeriod;

  /// No description provided for @colOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get colOwed;

  /// No description provided for @addFarmer.
  ///
  /// In en, this message translates to:
  /// **'Add farmer'**
  String get addFarmer;

  /// No description provided for @farmerTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerTitle;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @cardAndPhone.
  ///
  /// In en, this message translates to:
  /// **'Card {card} · {phone}'**
  String cardAndPhone(String card, String phone);

  /// No description provided for @smsReceiptsOn.
  ///
  /// In en, this message translates to:
  /// **'SMS receipts on'**
  String get smsReceiptsOn;

  /// No description provided for @thisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get thisPeriod;

  /// No description provided for @toBePaid.
  ///
  /// In en, this message translates to:
  /// **'To be paid'**
  String get toBePaid;

  /// No description provided for @payDay.
  ///
  /// In en, this message translates to:
  /// **'Pay day: {date}'**
  String payDay(String date);

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @statementPeriod.
  ///
  /// In en, this message translates to:
  /// **'Statement {period}'**
  String statementPeriod(String period);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @litresDelivered.
  ///
  /// In en, this message translates to:
  /// **'Litres delivered'**
  String get litresDelivered;

  /// No description provided for @pricePerLitre.
  ///
  /// In en, this message translates to:
  /// **'Price per litre'**
  String get pricePerLitre;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get gross;

  /// No description provided for @advanceOn.
  ///
  /// In en, this message translates to:
  /// **'Advance ({date})'**
  String advanceOn(String date);

  /// No description provided for @feedsOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Feeds on credit'**
  String get feedsOnCredit;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @closeSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the {session} session?'**
  String closeSessionTitle(String session);

  /// No description provided for @closeSessionBody.
  ///
  /// In en, this message translates to:
  /// **'{litres} L from {farmers} farmers. After closing, changes need a manager PIN and are reported to the owner.'**
  String closeSessionBody(String litres, int farmers);

  /// No description provided for @keepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep open'**
  String get keepOpen;

  /// No description provided for @managerPin.
  ///
  /// In en, this message translates to:
  /// **'Manager PIN'**
  String get managerPin;

  /// No description provided for @sessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session closed'**
  String get sessionClosed;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period {period}'**
  String periodLabel(String period);

  /// No description provided for @toPayOn.
  ///
  /// In en, this message translates to:
  /// **'To pay on {date}'**
  String toPayOn(String date);

  /// No description provided for @payHeroSub.
  ///
  /// In en, this message translates to:
  /// **'{farmers} farmers · {litres} L · {price} / L'**
  String payHeroSub(int farmers, String litres, String price);

  /// No description provided for @sendSmsStatements.
  ///
  /// In en, this message translates to:
  /// **'Send SMS statements'**
  String get sendSmsStatements;

  /// No description provided for @paymentSheet.
  ///
  /// In en, this message translates to:
  /// **'Payment sheet'**
  String get paymentSheet;

  /// No description provided for @litresAndCard.
  ///
  /// In en, this message translates to:
  /// **'{litres} L · Card {card}'**
  String litresAndCard(String litres, String card);

  /// No description provided for @colGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get colGross;

  /// No description provided for @colDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get colDeductions;

  /// No description provided for @colNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get colNet;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @payFarmers.
  ///
  /// In en, this message translates to:
  /// **'Pay farmers'**
  String get payFarmers;

  /// No description provided for @farmersAndAmount.
  ///
  /// In en, this message translates to:
  /// **'{farmers} farmers · {amount}'**
  String farmersAndAmount(int farmers, String amount);

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @cashSheet.
  ///
  /// In en, this message translates to:
  /// **'Cash sheet'**
  String get cashSheet;

  /// No description provided for @mobileMoneyPayouts.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money payouts'**
  String get mobileMoneyPayouts;

  /// No description provided for @mobileMoneyBody.
  ///
  /// In en, this message translates to:
  /// **'Each farmer receives an SMS when paid. Fees are shown before you confirm.'**
  String get mobileMoneyBody;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @failedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed — retry'**
  String get failedRetry;

  /// No description provided for @farmersLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmersLabel;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @estimatedFees.
  ///
  /// In en, this message translates to:
  /// **'Estimated fees'**
  String get estimatedFees;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm and pay'**
  String get confirmAndPay;

  /// No description provided for @payoutStarted.
  ///
  /// In en, this message translates to:
  /// **'Payouts started'**
  String get payoutStarted;

  /// No description provided for @smsStatements.
  ///
  /// In en, this message translates to:
  /// **'SMS statements'**
  String get smsStatements;

  /// No description provided for @previewWhatFarmersGet.
  ///
  /// In en, this message translates to:
  /// **'Preview of what each farmer receives:'**
  String get previewWhatFarmersGet;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @smsLeftThisMonth.
  ///
  /// In en, this message translates to:
  /// **'SMS left this month'**
  String get smsLeftThisMonth;

  /// No description provided for @extraSmsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Extra SMS needed'**
  String get extraSmsNeeded;

  /// No description provided for @countOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String countOfTotal(int count, int total);

  /// No description provided for @sendToFarmers.
  ///
  /// In en, this message translates to:
  /// **'Send to {count} farmers'**
  String sendToFarmers(int count);

  /// No description provided for @smsSent.
  ///
  /// In en, this message translates to:
  /// **'Statements sent'**
  String get smsSent;

  /// No description provided for @farmerAndLitres.
  ///
  /// In en, this message translates to:
  /// **'{name} · {litres} L'**
  String farmerAndLitres(String name, String litres);

  /// No description provided for @alcoholTest.
  ///
  /// In en, this message translates to:
  /// **'Alcohol test'**
  String get alcoholTest;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonSour.
  ///
  /// In en, this message translates to:
  /// **'Sour'**
  String get reasonSour;

  /// No description provided for @reasonWater.
  ///
  /// In en, this message translates to:
  /// **'Added water'**
  String get reasonWater;

  /// No description provided for @reasonDirty.
  ///
  /// In en, this message translates to:
  /// **'Dirty'**
  String get reasonDirty;

  /// No description provided for @reasonTreated.
  ///
  /// In en, this message translates to:
  /// **'Treated cow'**
  String get reasonTreated;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @willBeRejected.
  ///
  /// In en, this message translates to:
  /// **'{litres} L will be rejected'**
  String willBeRejected(String litres);

  /// No description provided for @rejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Not paid. The farmer gets an SMS explaining why.'**
  String get rejectedBody;

  /// No description provided for @rejectMilk.
  ///
  /// In en, this message translates to:
  /// **'Reject milk'**
  String get rejectMilk;

  /// No description provided for @acceptMilk.
  ///
  /// In en, this message translates to:
  /// **'Accept milk'**
  String get acceptMilk;

  /// No description provided for @reconcile.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcile;

  /// No description provided for @receivedFromFarmers.
  ///
  /// In en, this message translates to:
  /// **'Received from farmers'**
  String get receivedFromFarmers;

  /// No description provided for @dispatchedToDairy.
  ///
  /// In en, this message translates to:
  /// **'Dispatched to dairy'**
  String get dispatchedToDairy;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @diffPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · above {limit}% limit'**
  String diffPercent(String percent, int limit);

  /// No description provided for @diffPercentOk.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · within {limit}% limit'**
  String diffPercentOk(String percent, int limit);

  /// No description provided for @diffAboveLimit.
  ///
  /// In en, this message translates to:
  /// **'Difference is above the {limit}% limit'**
  String diffAboveLimit(int limit);

  /// No description provided for @diffAboveBody.
  ///
  /// In en, this message translates to:
  /// **'Check spillage and the cooler dipstick. The owner is notified.'**
  String get diffAboveBody;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @leftAt.
  ///
  /// In en, this message translates to:
  /// **'Left at'**
  String get leftAt;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @explainDifference.
  ///
  /// In en, this message translates to:
  /// **'Explain the difference'**
  String get explainDifference;

  /// No description provided for @saveReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Save reconciliation'**
  String get saveReconciliation;

  /// No description provided for @reconciliationSaved.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation saved'**
  String get reconciliationSaved;

  /// No description provided for @smsStatementText.
  ///
  /// In en, this message translates to:
  /// **'FarmTap: {name}, {period} you delivered {litres} L. Amount so far {amount}. Pay day {payDay}. Thank you!'**
  String smsStatementText(
    String name,
    String period,
    String litres,
    String amount,
    String payDay,
  );

  /// No description provided for @smsReceiptText.
  ///
  /// In en, this message translates to:
  /// **'FarmTap: Today {litres} L received at {time}. Card {card}.'**
  String smsReceiptText(String litres, String time, String card);

  /// No description provided for @dateAt.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateAt(String date, String time);

  /// No description provided for @networkPhone.
  ///
  /// In en, this message translates to:
  /// **'{network} · {phone}'**
  String networkPhone(String network, String phone);

  /// No description provided for @networkMtn.
  ///
  /// In en, this message translates to:
  /// **'MTN'**
  String get networkMtn;

  /// No description provided for @networkAirtel.
  ///
  /// In en, this message translates to:
  /// **'Airtel'**
  String get networkAirtel;

  /// No description provided for @ugxUnit.
  ///
  /// In en, this message translates to:
  /// **'UGX'**
  String get ugxUnit;

  /// No description provided for @farmerCardNotFound.
  ///
  /// In en, this message translates to:
  /// **'No farmer has this card. Check the number.'**
  String get farmerCardNotFound;

  /// No description provided for @findFarmer.
  ///
  /// In en, this message translates to:
  /// **'Find farmer'**
  String get findFarmer;

  /// No description provided for @pricePerLitreValue.
  ///
  /// In en, this message translates to:
  /// **'{price} / L'**
  String pricePerLitreValue(String price);

  /// No description provided for @cashSheetInfo.
  ///
  /// In en, this message translates to:
  /// **'Cash sheet'**
  String get cashSheetInfo;

  /// No description provided for @cashSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Print the sheet. Each farmer signs when paid in cash.'**
  String get cashSheetBody;

  /// No description provided for @printCashSheet.
  ///
  /// In en, this message translates to:
  /// **'Print cash sheet'**
  String get printCashSheet;

  /// No description provided for @retryPayout.
  ///
  /// In en, this message translates to:
  /// **'Retry payout'**
  String get retryPayout;

  /// No description provided for @wrongManagerPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get wrongManagerPin;

  /// No description provided for @dispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatchTitle;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get reasonRequired;

  /// No description provided for @farmerName.
  ///
  /// In en, this message translates to:
  /// **'Farmer name'**
  String get farmerName;

  /// No description provided for @farmerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (Mobile Money)'**
  String get farmerPhone;

  /// No description provided for @cardOptional.
  ///
  /// In en, this message translates to:
  /// **'Card number (optional)'**
  String get cardOptional;

  /// No description provided for @saveFarmer.
  ///
  /// In en, this message translates to:
  /// **'Save farmer'**
  String get saveFarmer;

  /// No description provided for @farmerSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String farmerSaved(String name);

  /// No description provided for @smsTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String smsTodayAt(String time);

  /// No description provided for @healthCalendar.
  ///
  /// In en, this message translates to:
  /// **'Health calendar'**
  String get healthCalendar;

  /// No description provided for @milkNotForSaleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} milk not for sale'**
  String milkNotForSaleCount(int count);

  /// No description provided for @dueThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get dueThisWeek;

  /// No description provided for @drugsLow.
  ///
  /// In en, this message translates to:
  /// **'Drugs low'**
  String get drugsLow;

  /// No description provided for @sickList.
  ///
  /// In en, this message translates to:
  /// **'Sick list'**
  String get sickList;

  /// No description provided for @courseDay.
  ///
  /// In en, this message translates to:
  /// **'day {day} of {total}'**
  String courseDay(int day, int total);

  /// No description provided for @daysWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysWithdrawal(int count);

  /// No description provided for @withdrawalLabel.
  ///
  /// In en, this message translates to:
  /// **'withdrawal'**
  String get withdrawalLabel;

  /// No description provided for @newTreatment.
  ///
  /// In en, this message translates to:
  /// **'New treatment'**
  String get newTreatment;

  /// No description provided for @tagTapToChange.
  ///
  /// In en, this message translates to:
  /// **'{tag} · tap to change'**
  String tagTapToChange(String tag);

  /// No description provided for @whatIsTheProblem.
  ///
  /// In en, this message translates to:
  /// **'What is the problem?'**
  String get whatIsTheProblem;

  /// No description provided for @condMastitis.
  ///
  /// In en, this message translates to:
  /// **'Mastitis'**
  String get condMastitis;

  /// No description provided for @condLame.
  ///
  /// In en, this message translates to:
  /// **'Lame'**
  String get condLame;

  /// No description provided for @condFever.
  ///
  /// In en, this message translates to:
  /// **'Fever'**
  String get condFever;

  /// No description provided for @condWound.
  ///
  /// In en, this message translates to:
  /// **'Wound'**
  String get condWound;

  /// No description provided for @condEye.
  ///
  /// In en, this message translates to:
  /// **'Eye'**
  String get condEye;

  /// No description provided for @condDiarrhoea.
  ///
  /// In en, this message translates to:
  /// **'Diarrhoea'**
  String get condDiarrhoea;

  /// No description provided for @condOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get condOther;

  /// No description provided for @drugLabel.
  ///
  /// In en, this message translates to:
  /// **'Drug'**
  String get drugLabel;

  /// No description provided for @doseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseLabel;

  /// No description provided for @routeLabel.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeLabel;

  /// No description provided for @givenBy.
  ///
  /// In en, this message translates to:
  /// **'Given by'**
  String get givenBy;

  /// No description provided for @routeInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection (IM)'**
  String get routeInjection;

  /// No description provided for @routeOral.
  ///
  /// In en, this message translates to:
  /// **'By mouth'**
  String get routeOral;

  /// No description provided for @routeSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get routeSpray;

  /// No description provided for @routePourOn.
  ///
  /// In en, this message translates to:
  /// **'Pour-on'**
  String get routePourOn;

  /// No description provided for @drugStockLine.
  ///
  /// In en, this message translates to:
  /// **'Stock: {stock} · withdrawal {days} days (milk)'**
  String drugStockLine(String stock, int days);

  /// No description provided for @noWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'No milk withdrawal'**
  String get noWithdrawal;

  /// No description provided for @blockMilkBody.
  ///
  /// In en, this message translates to:
  /// **'FarmTap will block her milk and remind you when it\'s safe.'**
  String get blockMilkBody;

  /// No description provided for @treatmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Treatment saved'**
  String get treatmentSaved;

  /// No description provided for @treatmentSavedBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s milk is marked \'not for sale\' until {weekday}. We\'ll remind you on day 3 to check her.'**
  String treatmentSavedBody(String name, String weekday);

  /// No description provided for @treatmentSavedNoWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s treatment is saved. We\'ll remind you on day 3 to check her.'**
  String treatmentSavedNoWithdrawal(String name);

  /// No description provided for @addAnotherTreatment.
  ///
  /// In en, this message translates to:
  /// **'Add another treatment'**
  String get addAnotherTreatment;

  /// No description provided for @pickAnimal.
  ///
  /// In en, this message translates to:
  /// **'Pick animal'**
  String get pickAnimal;

  /// No description provided for @drugStock.
  ///
  /// In en, this message translates to:
  /// **'Drug stock'**
  String get drugStock;

  /// No description provided for @addDrug.
  ///
  /// In en, this message translates to:
  /// **'Add drug'**
  String get addDrug;

  /// No description provided for @drugIsLow.
  ///
  /// In en, this message translates to:
  /// **'{drug} is low'**
  String drugIsLow(String drug);

  /// No description provided for @drugLowBody.
  ///
  /// In en, this message translates to:
  /// **'{count} bottle left. Usage this month is higher than recorded treatments.'**
  String drugLowBody(String count);

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @reorderNoted.
  ///
  /// In en, this message translates to:
  /// **'Added to the shopping list'**
  String get reorderNoted;

  /// No description provided for @bottlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bottle} other{{count} bottles}}'**
  String bottlesCount(int count);

  /// No description provided for @litresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} litres'**
  String litresCount(String count);

  /// No description provided for @withdrawalDaysLine.
  ///
  /// In en, this message translates to:
  /// **'withdrawal {days} days'**
  String withdrawalDaysLine(int days);

  /// No description provided for @reorderAt.
  ///
  /// In en, this message translates to:
  /// **'reorder at {count}'**
  String reorderAt(String count);

  /// No description provided for @lowBadge.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowBadge;

  /// No description provided for @drugName.
  ///
  /// In en, this message translates to:
  /// **'Drug name'**
  String get drugName;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockLabel;

  /// No description provided for @withdrawalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal days (milk)'**
  String get withdrawalDaysLabel;

  /// No description provided for @saveDrug.
  ///
  /// In en, this message translates to:
  /// **'Save drug'**
  String get saveDrug;

  /// No description provided for @drugSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String drugSaved(String name);

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthView;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskTitle;

  /// No description provided for @taskDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get taskDate;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTask;

  /// No description provided for @taskAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to the calendar'**
  String get taskAdded;

  /// No description provided for @milkNotForSale.
  ///
  /// In en, this message translates to:
  /// **'Milk not for sale'**
  String get milkNotForSale;

  /// No description provided for @keepMilkSeparate.
  ///
  /// In en, this message translates to:
  /// **'{count} cows — keep their milk separate'**
  String keepMilkSeparate(int count);

  /// No description provided for @keepMilkSeparateBody.
  ///
  /// In en, this message translates to:
  /// **'Do not sell or mix this milk until the date shown.'**
  String get keepMilkSeparateBody;

  /// No description provided for @drugSince.
  ///
  /// In en, this message translates to:
  /// **'{drug} · since {date}'**
  String drugSince(String drug, String date);

  /// No description provided for @safeFrom.
  ///
  /// In en, this message translates to:
  /// **'safe from'**
  String get safeFrom;

  /// No description provided for @whyThisMatters.
  ///
  /// In en, this message translates to:
  /// **'Why this matters'**
  String get whyThisMatters;

  /// No description provided for @whyThisMattersBody.
  ///
  /// In en, this message translates to:
  /// **'Collection centres test for drug residues and reject the whole can. One treated cow can spoil a full delivery.'**
  String get whyThisMattersBody;

  /// No description provided for @noWithdrawalsTitle.
  ///
  /// In en, this message translates to:
  /// **'All milk can be sold'**
  String get noWithdrawalsTitle;

  /// No description provided for @noWithdrawalsBody.
  ///
  /// In en, this message translates to:
  /// **'No cow is under drug withdrawal.'**
  String get noWithdrawalsBody;

  /// No description provided for @treatmentReadBack.
  ///
  /// In en, this message translates to:
  /// **'{condition} · {drug}'**
  String treatmentReadBack(String condition, String drug);

  /// No description provided for @treatmentReadBackDetail.
  ///
  /// In en, this message translates to:
  /// **'Milk not for sale until {date}'**
  String treatmentReadBackDetail(String date);

  /// No description provided for @kindVaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get kindVaccination;

  /// No description provided for @kindDipping.
  ///
  /// In en, this message translates to:
  /// **'Dipping'**
  String get kindDipping;

  /// No description provided for @kindDeworming.
  ///
  /// In en, this message translates to:
  /// **'Deworming'**
  String get kindDeworming;

  /// No description provided for @recordFeeding.
  ///
  /// In en, this message translates to:
  /// **'Record feeding'**
  String get recordFeeding;

  /// No description provided for @feedCostThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Feed cost this month'**
  String get feedCostThisMonth;

  /// No description provided for @perLitreOfMilk.
  ///
  /// In en, this message translates to:
  /// **'{amount} per litre of milk'**
  String perLitreOfMilk(String amount);

  /// No description provided for @okBadge.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okBadge;

  /// No description provided for @buyFeed.
  ///
  /// In en, this message translates to:
  /// **'Buy feed'**
  String get buyFeed;

  /// No description provided for @buyFeedSub.
  ///
  /// In en, this message translates to:
  /// **'Adds stock and records an expense.'**
  String get buyFeedSub;

  /// No description provided for @whichGroup.
  ///
  /// In en, this message translates to:
  /// **'Which group?'**
  String get whichGroup;

  /// No description provided for @whichFeed.
  ///
  /// In en, this message translates to:
  /// **'Which feed?'**
  String get whichFeed;

  /// No description provided for @groupMilkingCows.
  ///
  /// In en, this message translates to:
  /// **'Milking cows'**
  String get groupMilkingCows;

  /// No description provided for @groupDryCows.
  ///
  /// In en, this message translates to:
  /// **'Dry cows'**
  String get groupDryCows;

  /// No description provided for @groupHeifers.
  ///
  /// In en, this message translates to:
  /// **'Heifers'**
  String get groupHeifers;

  /// No description provided for @groupCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get groupCalves;

  /// No description provided for @feedDairyMeal.
  ///
  /// In en, this message translates to:
  /// **'Dairy meal'**
  String get feedDairyMeal;

  /// No description provided for @feedMaizeBran.
  ///
  /// In en, this message translates to:
  /// **'Maize bran'**
  String get feedMaizeBran;

  /// No description provided for @feedMineralLick.
  ///
  /// In en, this message translates to:
  /// **'Mineral lick'**
  String get feedMineralLick;

  /// No description provided for @feedSilage.
  ///
  /// In en, this message translates to:
  /// **'Silage'**
  String get feedSilage;

  /// No description provided for @feedBags.
  ///
  /// In en, this message translates to:
  /// **'{n} bags'**
  String feedBags(String n);

  /// No description provided for @feedBlocks.
  ///
  /// In en, this message translates to:
  /// **'{n} blocks'**
  String feedBlocks(String n);

  /// No description provided for @feedTonnes.
  ///
  /// In en, this message translates to:
  /// **'about {n} tonnes'**
  String feedTonnes(String n);

  /// No description provided for @feedLeftDays.
  ///
  /// In en, this message translates to:
  /// **'{stock} left · about {days} days'**
  String feedLeftDays(String stock, int days);

  /// No description provided for @feedLowTitle.
  ///
  /// In en, this message translates to:
  /// **'{feed}: {stock} left'**
  String feedLowTitle(String feed, String stock);

  /// No description provided for @feedLowBody.
  ///
  /// In en, this message translates to:
  /// **'About {days} days at the current rate.'**
  String feedLowBody(int days);

  /// No description provided for @unitBags.
  ///
  /// In en, this message translates to:
  /// **'bags'**
  String get unitBags;

  /// No description provided for @unitBlocks.
  ///
  /// In en, this message translates to:
  /// **'blocks'**
  String get unitBlocks;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitTonnes.
  ///
  /// In en, this message translates to:
  /// **'Tonnes'**
  String get unitTonnes;

  /// No description provided for @unitBagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get unitBagsLabel;

  /// No description provided for @unitBlocksLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get unitBlocksLabel;

  /// No description provided for @pricePerBag.
  ///
  /// In en, this message translates to:
  /// **'Price per bag'**
  String get pricePerBag;

  /// No description provided for @pricePerBlock.
  ///
  /// In en, this message translates to:
  /// **'Price per block'**
  String get pricePerBlock;

  /// No description provided for @pricePerTonne.
  ///
  /// In en, this message translates to:
  /// **'Price per tonne'**
  String get pricePerTonne;

  /// No description provided for @feedAmountCaption.
  ///
  /// In en, this message translates to:
  /// **'{unit} of {feed}'**
  String feedAmountCaption(String unit, String feed);

  /// No description provided for @colFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get colFeed;

  /// No description provided for @colInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get colInStock;

  /// No description provided for @colUsedPerDay.
  ///
  /// In en, this message translates to:
  /// **'Used / day'**
  String get colUsedPerDay;

  /// No description provided for @colDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get colDaysLeft;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @savePurchase.
  ///
  /// In en, this message translates to:
  /// **'Save purchase'**
  String get savePurchase;

  /// No description provided for @saveFeeding.
  ///
  /// In en, this message translates to:
  /// **'Save feeding'**
  String get saveFeeding;

  /// No description provided for @feedingSaved.
  ///
  /// In en, this message translates to:
  /// **'Feeding saved: {amount}'**
  String feedingSaved(String amount);

  /// No description provided for @purchaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Purchase saved: {amount}'**
  String purchaseSaved(String amount);

  /// No description provided for @moreThanInStock.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} in stock'**
  String moreThanInStock(String stock);

  /// No description provided for @pregnantLabel.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get pregnantLabel;

  /// No description provided for @calvingInDays.
  ///
  /// In en, this message translates to:
  /// **'Calving in {days} days'**
  String calvingInDays(int days);

  /// No description provided for @checkPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Check pregnancy'**
  String get checkPregnancy;

  /// No description provided for @expectedCalvings.
  ///
  /// In en, this message translates to:
  /// **'Expected calvings'**
  String get expectedCalvings;

  /// No description provided for @toDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDo;

  /// No description provided for @inDaysCount.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDaysCount(int days);

  /// No description provided for @daysShortValue.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String daysShortValue(int days);

  /// No description provided for @servedCheckFrom.
  ///
  /// In en, this message translates to:
  /// **'Served {served} · check from {from}'**
  String servedCheckFrom(String served, String from);

  /// No description provided for @heatSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Heat seen yesterday'**
  String get heatSeenYesterday;

  /// No description provided for @heatSeenToday.
  ///
  /// In en, this message translates to:
  /// **'Heat seen today'**
  String get heatSeenToday;

  /// No description provided for @checkAction.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAction;

  /// No description provided for @serveAction.
  ///
  /// In en, this message translates to:
  /// **'Serve'**
  String get serveAction;

  /// No description provided for @tipLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tipLabel;

  /// No description provided for @breedingTip.
  ///
  /// In en, this message translates to:
  /// **'Check heat signs morning and evening. A missed heat costs about 21 days of milk.'**
  String get breedingTip;

  /// No description provided for @recordHeat.
  ///
  /// In en, this message translates to:
  /// **'Record heat'**
  String get recordHeat;

  /// No description provided for @heatAndService.
  ///
  /// In en, this message translates to:
  /// **'Heat & service — {name}'**
  String heatAndService(String name);

  /// No description provided for @heiferWord.
  ///
  /// In en, this message translates to:
  /// **'heifer'**
  String get heiferWord;

  /// No description provided for @cowWord.
  ///
  /// In en, this message translates to:
  /// **'cow'**
  String get cowWord;

  /// No description provided for @heatSeen.
  ///
  /// In en, this message translates to:
  /// **'Heat seen'**
  String get heatSeen;

  /// No description provided for @servedNatural.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get servedNatural;

  /// No description provided for @aiLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiLabel;

  /// No description provided for @semenStraw.
  ///
  /// In en, this message translates to:
  /// **'Semen / straw'**
  String get semenStraw;

  /// No description provided for @bullLabel.
  ///
  /// In en, this message translates to:
  /// **'Bull'**
  String get bullLabel;

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @checkReminder.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy check reminder: {date}'**
  String checkReminder(String date);

  /// No description provided for @calvingIfPregnant.
  ///
  /// In en, this message translates to:
  /// **'Expected calving if pregnant: {date}'**
  String calvingIfPregnant(String date);

  /// No description provided for @serviceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved for {name}'**
  String serviceSaved(String name);

  /// No description provided for @whichAnimal.
  ///
  /// In en, this message translates to:
  /// **'Which animal?'**
  String get whichAnimal;

  /// No description provided for @isSheP.
  ///
  /// In en, this message translates to:
  /// **'Is {name} pregnant?'**
  String isSheP(String name);

  /// No description provided for @checkBody.
  ///
  /// In en, this message translates to:
  /// **'Served {date}. Record what the vet found.'**
  String checkBody(String date);

  /// No description provided for @yesPregnant.
  ///
  /// In en, this message translates to:
  /// **'Yes, pregnant'**
  String get yesPregnant;

  /// No description provided for @notPregnant.
  ///
  /// In en, this message translates to:
  /// **'Not pregnant'**
  String get notPregnant;

  /// No description provided for @notPregnantSaved.
  ///
  /// In en, this message translates to:
  /// **'{name}: not pregnant. Watch for heat.'**
  String notPregnantSaved(String name);

  /// No description provided for @isPregnantTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is pregnant!'**
  String isPregnantTitle(String name);

  /// No description provided for @pregnantBody.
  ///
  /// In en, this message translates to:
  /// **'Expected calving: {date}. We\'ll remind you 30 days and 7 days before.'**
  String pregnantBody(String date);

  /// No description provided for @servedLabel.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get servedLabel;

  /// No description provided for @checkedBy.
  ///
  /// In en, this message translates to:
  /// **'Checked by'**
  String get checkedBy;

  /// No description provided for @dryOffFrom.
  ///
  /// In en, this message translates to:
  /// **'Dry off from'**
  String get dryOffFrom;

  /// No description provided for @checkedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Vet'**
  String get checkedByLabel;

  /// No description provided for @cardsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsLabel;

  /// No description provided for @subscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionLabel;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @lockPhone.
  ///
  /// In en, this message translates to:
  /// **'Lock phone'**
  String get lockPhone;

  /// No description provided for @lockPhoneSub.
  ///
  /// In en, this message translates to:
  /// **'Next person taps their card'**
  String get lockPhoneSub;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutLabel;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Records on this phone stay saved. Sign in again to see them.'**
  String get signOutBody;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of FarmTap is being built.'**
  String get comingSoonBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nyn'].contains(locale.languageCode);

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
