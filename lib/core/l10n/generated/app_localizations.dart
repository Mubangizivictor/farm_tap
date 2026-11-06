import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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
  /// **'Your 7 free days start today and end on {date}. After that FarmTap is UGX 70,000 a month.'**
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
  /// **'{count, plural, =1{1 buyer} other{{count} buyers}}'**
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
  /// **'SMS receipt queued'**
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

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{n} people'**
  String peopleCount(int n);

  /// No description provided for @filterInNow.
  ///
  /// In en, this message translates to:
  /// **'In now'**
  String get filterInNow;

  /// No description provided for @filterNotIn.
  ///
  /// In en, this message translates to:
  /// **'Not in'**
  String get filterNotIn;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @notInLabel.
  ///
  /// In en, this message translates to:
  /// **'Not in'**
  String get notInLabel;

  /// No description provided for @inAt.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String inAt(String time);

  /// No description provided for @outAt.
  ///
  /// In en, this message translates to:
  /// **'Out {time}'**
  String outAt(String time);

  /// No description provided for @cardBadge.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardBadge;

  /// No description provided for @noCardBadge.
  ///
  /// In en, this message translates to:
  /// **'No card'**
  String get noCardBadge;

  /// No description provided for @cardNumberBadge.
  ///
  /// In en, this message translates to:
  /// **'Card {number}'**
  String cardNumberBadge(String number);

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get addWorker;

  /// No description provided for @workerTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get workerTitle;

  /// No description provided for @roleSince.
  ///
  /// In en, this message translates to:
  /// **'{role} · since {date}'**
  String roleSince(String role, String date);

  /// No description provided for @daysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Days this month'**
  String get daysThisMonth;

  /// No description provided for @milkRecords.
  ///
  /// In en, this message translates to:
  /// **'Milk records'**
  String get milkRecords;

  /// No description provided for @balanceOwed.
  ///
  /// In en, this message translates to:
  /// **'Balance owed'**
  String get balanceOwed;

  /// No description provided for @resetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPin;

  /// No description provided for @replaceLostCard.
  ///
  /// In en, this message translates to:
  /// **'Replace lost card'**
  String get replaceLostCard;

  /// No description provided for @assignCardRow.
  ///
  /// In en, this message translates to:
  /// **'Assign card'**
  String get assignCardRow;

  /// No description provided for @whatCanDo.
  ///
  /// In en, this message translates to:
  /// **'What {name} can do'**
  String whatCanDo(String name);

  /// No description provided for @canDoManager.
  ///
  /// In en, this message translates to:
  /// **'Everything except money settings'**
  String get canDoManager;

  /// No description provided for @canDoHerdsman.
  ///
  /// In en, this message translates to:
  /// **'Milk, feeding, treatments'**
  String get canDoHerdsman;

  /// No description provided for @canDoClerk.
  ///
  /// In en, this message translates to:
  /// **'Milk, collection, payments'**
  String get canDoClerk;

  /// No description provided for @canDoWorker.
  ///
  /// In en, this message translates to:
  /// **'Milk, feeding'**
  String get canDoWorker;

  /// No description provided for @canDoVet.
  ///
  /// In en, this message translates to:
  /// **'Treatments, breeding'**
  String get canDoVet;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activityLog;

  /// No description provided for @resetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset {name}\'s PIN?'**
  String resetPinTitle(String name);

  /// No description provided for @resetPinBody.
  ///
  /// In en, this message translates to:
  /// **'They choose a new 4-digit PIN the next time they tap their card.'**
  String get resetPinBody;

  /// No description provided for @resetPinDone.
  ///
  /// In en, this message translates to:
  /// **'{name} will choose a new PIN'**
  String resetPinDone(String name);

  /// No description provided for @assignCard.
  ///
  /// In en, this message translates to:
  /// **'Assign card'**
  String get assignCard;

  /// No description provided for @tapNewCardNow.
  ///
  /// In en, this message translates to:
  /// **'Tap the new card now'**
  String get tapNewCardNow;

  /// No description provided for @holdBlankCard.
  ///
  /// In en, this message translates to:
  /// **'Hold {name}\'s blank card on the back of the phone.'**
  String holdBlankCard(String name);

  /// No description provided for @cardAssigned.
  ///
  /// In en, this message translates to:
  /// **'Card {number} is now {name}\'s'**
  String cardAssigned(String number, String name);

  /// No description provided for @cardTaken.
  ///
  /// In en, this message translates to:
  /// **'Card {number} belongs to {name}'**
  String cardTaken(String number, String name);

  /// No description provided for @typeTheCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Type the number printed on the card'**
  String get typeTheCardNumber;

  /// No description provided for @useCard.
  ///
  /// In en, this message translates to:
  /// **'Use this card'**
  String get useCard;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @ofInCount.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} in'**
  String ofInCount(int n, int total);

  /// No description provided for @tapToClock.
  ///
  /// In en, this message translates to:
  /// **'Tap your card to clock in or out'**
  String get tapToClock;

  /// No description provided for @clockInOut.
  ///
  /// In en, this message translates to:
  /// **'Clock in / out — tap card'**
  String get clockInOut;

  /// No description provided for @clockedInToast.
  ///
  /// In en, this message translates to:
  /// **'{name} clocked in {time}'**
  String clockedInToast(String name, String time);

  /// No description provided for @clockedOutToast.
  ///
  /// In en, this message translates to:
  /// **'{name} clocked out {time}'**
  String clockedOutToast(String name, String time);

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get tabThisWeek;

  /// No description provided for @tabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tabDone;

  /// No description provided for @doneAt.
  ///
  /// In en, this message translates to:
  /// **'Done {time}'**
  String doneAt(String time);

  /// No description provided for @photoNeeded.
  ///
  /// In en, this message translates to:
  /// **'Photo needed'**
  String get photoNeeded;

  /// No description provided for @overdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBadge;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @whoDoesIt.
  ///
  /// In en, this message translates to:
  /// **'Who does it?'**
  String get whoDoesIt;

  /// No description provided for @whenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenLabel;

  /// No description provided for @taskSaved.
  ///
  /// In en, this message translates to:
  /// **'Task saved'**
  String get taskSaved;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get noTasks;

  /// No description provided for @wagesAdvances.
  ///
  /// In en, this message translates to:
  /// **'Wages & advances'**
  String get wagesAdvances;

  /// No description provided for @wagesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Wages this month'**
  String get wagesThisMonth;

  /// No description provided for @advancesGiven.
  ///
  /// In en, this message translates to:
  /// **'Advances given'**
  String get advancesGiven;

  /// No description provided for @wageLine.
  ///
  /// In en, this message translates to:
  /// **'Wage {wage} · advance {advance}'**
  String wageLine(String wage, String advance);

  /// No description provided for @toPayLabel.
  ///
  /// In en, this message translates to:
  /// **'to pay'**
  String get toPayLabel;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidBadge;

  /// No description provided for @recordAdvance.
  ///
  /// In en, this message translates to:
  /// **'Record advance'**
  String get recordAdvance;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @payWage.
  ///
  /// In en, this message translates to:
  /// **'Pay {name}'**
  String payWage(String name);

  /// No description provided for @wagePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid {name} {amount}'**
  String wagePaid(String name, String amount);

  /// No description provided for @advanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount} to {name}'**
  String advanceSaved(String amount, String name);

  /// No description provided for @advanceKind.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advanceKind;

  /// No description provided for @wageKind.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wageKind;

  /// No description provided for @visitingVet.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitingVet;

  /// No description provided for @colName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get colName;

  /// No description provided for @colRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get colRole;

  /// No description provided for @colThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get colThisMonth;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysCount(int n);

  /// No description provided for @noOneHasCard.
  ///
  /// In en, this message translates to:
  /// **'No one has card {number}'**
  String noOneHasCard(String number);

  /// No description provided for @managerPinNeeded.
  ///
  /// In en, this message translates to:
  /// **'Manager PIN needed'**
  String get managerPinNeeded;

  /// No description provided for @typedCardNeedsManager.
  ///
  /// In en, this message translates to:
  /// **'Card {number} was typed, not tapped. A manager must confirm clocking in or out.'**
  String typedCardNeedsManager(String number);

  /// No description provided for @wagesShort.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get wagesShort;

  /// No description provided for @editWorker.
  ///
  /// In en, this message translates to:
  /// **'Edit worker'**
  String get editWorker;

  /// No description provided for @workerSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String workerSaved(String name);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @profitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profitLabel;

  /// No description provided for @lossLabel.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get lossLabel;

  /// No description provided for @costPerLitre.
  ///
  /// In en, this message translates to:
  /// **'Cost per litre'**
  String get costPerLitre;

  /// No description provided for @milkIncomeCaption.
  ///
  /// In en, this message translates to:
  /// **'Milk {amount}'**
  String milkIncomeCaption(String amount);

  /// No description provided for @expenseShare.
  ///
  /// In en, this message translates to:
  /// **'{group} {percent}%'**
  String expenseShare(String group, int percent);

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expensesByCategory;

  /// No description provided for @latestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestLabel;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @exportLabel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @groupFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get groupFeed;

  /// No description provided for @groupDrugsVet.
  ///
  /// In en, this message translates to:
  /// **'Drugs & vet'**
  String get groupDrugsVet;

  /// No description provided for @groupWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get groupWages;

  /// No description provided for @groupTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get groupTransport;

  /// No description provided for @groupFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel & power'**
  String get groupFuel;

  /// No description provided for @groupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groupOther;

  /// No description provided for @groupDrugsShort.
  ///
  /// In en, this message translates to:
  /// **'Drugs'**
  String get groupDrugsShort;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @receiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get receiptPhoto;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved: {amount}'**
  String expenseSaved(String amount);

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @monthlyFarmReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly farm report'**
  String get monthlyFarmReport;

  /// No description provided for @monthlyFarmReportSub.
  ///
  /// In en, this message translates to:
  /// **'Milk, herd, health, money · PDF'**
  String get monthlyFarmReportSub;

  /// No description provided for @milkRecordsReport.
  ///
  /// In en, this message translates to:
  /// **'Milk records'**
  String get milkRecordsReport;

  /// No description provided for @milkRecordsReportSub.
  ///
  /// In en, this message translates to:
  /// **'Per cow, per day · Excel / CSV'**
  String get milkRecordsReportSub;

  /// No description provided for @farmerStatements.
  ///
  /// In en, this message translates to:
  /// **'Farmer statements'**
  String get farmerStatements;

  /// No description provided for @farmerStatementsSub.
  ///
  /// In en, this message translates to:
  /// **'Collection centre · PDF'**
  String get farmerStatementsSub;

  /// No description provided for @treatmentsReport.
  ///
  /// In en, this message translates to:
  /// **'Treatments & withdrawals'**
  String get treatmentsReport;

  /// No description provided for @treatmentsReportSub.
  ///
  /// In en, this message translates to:
  /// **'For buyers and inspections · PDF'**
  String get treatmentsReportSub;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all my data'**
  String get exportAll;

  /// No description provided for @exportAllSub.
  ///
  /// In en, this message translates to:
  /// **'Everything you have recorded'**
  String get exportAllSub;

  /// No description provided for @dailyWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Daily WhatsApp report'**
  String get dailyWhatsapp;

  /// No description provided for @dailyWhatsappSub.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String dailyWhatsappSub(String time);

  /// No description provided for @previewReport.
  ///
  /// In en, this message translates to:
  /// **'Preview · {month} report'**
  String previewReport(String month);

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'{farm} — {month}'**
  String reportTitle(String farm, String month);

  /// No description provided for @milkProduced.
  ///
  /// In en, this message translates to:
  /// **'Milk produced'**
  String get milkProduced;

  /// No description provided for @milkSold.
  ///
  /// In en, this message translates to:
  /// **'Milk sold'**
  String get milkSold;

  /// No description provided for @sentToEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone} every day at {time}'**
  String sentToEveryDay(String phone, String time);

  /// No description provided for @sendTime.
  ///
  /// In en, this message translates to:
  /// **'Send time'**
  String get sendTime;

  /// No description provided for @includeMoney.
  ///
  /// In en, this message translates to:
  /// **'Include money'**
  String get includeMoney;

  /// No description provided for @includeMoneySub.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses'**
  String get includeMoneySub;

  /// No description provided for @smsIfWhatsappFails.
  ///
  /// In en, this message translates to:
  /// **'SMS if WhatsApp fails'**
  String get smsIfWhatsappFails;

  /// No description provided for @rpMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk: {litres} L ({trend})'**
  String rpMilk(String litres, String trend);

  /// No description provided for @rpNotForSale.
  ///
  /// In en, this message translates to:
  /// **'Not for sale: {litres} L ({who}, treated)'**
  String rpNotForSale(String litres, String who);

  /// No description provided for @rpTreatmentsFeed.
  ///
  /// In en, this message translates to:
  /// **'Treatments: {n} · Feed used: {bags} bags'**
  String rpTreatmentsFeed(int n, String bags);

  /// No description provided for @rpWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers in: {n} of {total}'**
  String rpWorkers(int n, int total);

  /// No description provided for @rpAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert: {item}: {n} bags left'**
  String rpAlert(String item, int n);

  /// No description provided for @rpMoney.
  ///
  /// In en, this message translates to:
  /// **'Money this month: in {income}, out {expenses}'**
  String rpMoney(String income, String expenses);

  /// No description provided for @searchList.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchList;

  /// No description provided for @useTyped.
  ///
  /// In en, this message translates to:
  /// **'Use “{text}”'**
  String useTyped(String text);

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Type the full name to use it.'**
  String get nothingFound;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location in your phone settings, or pick the district.'**
  String get locationOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is not allowed. Pick the district from the list.'**
  String get locationDenied;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find your district. Pick it from the list.'**
  String get locationNotFound;

  /// No description provided for @findingLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get findingLocation;

  /// No description provided for @cowsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'How many cows?'**
  String get cowsCountLabel;

  /// No description provided for @cowsCountHelper.
  ///
  /// In en, this message translates to:
  /// **'All cattle on the farm today'**
  String get cowsCountHelper;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleMilker.
  ///
  /// In en, this message translates to:
  /// **'Milker'**
  String get roleMilker;

  /// No description provided for @roleSecretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get roleSecretary;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleGuard.
  ///
  /// In en, this message translates to:
  /// **'Security guard'**
  String get roleGuard;

  /// No description provided for @roleCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get roleCook;

  /// No description provided for @roleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family member'**
  String get roleFamily;

  /// No description provided for @roleCoOwner.
  ///
  /// In en, this message translates to:
  /// **'Co-owner'**
  String get roleCoOwner;

  /// No description provided for @roleFarmManager.
  ///
  /// In en, this message translates to:
  /// **'Farm manager'**
  String get roleFarmManager;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get jobLabel;

  /// No description provided for @jobHelper.
  ///
  /// In en, this message translates to:
  /// **'Pick one or type your own, e.g. “Farmer\'s daughter”'**
  String get jobHelper;

  /// No description provided for @accessLabel.
  ///
  /// In en, this message translates to:
  /// **'What they can do in FarmTap'**
  String get accessLabel;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get phoneOptional;

  /// No description provided for @wageOptional.
  ///
  /// In en, this message translates to:
  /// **'Monthly pay (optional)'**
  String get wageOptional;

  /// No description provided for @cardForWorker.
  ///
  /// In en, this message translates to:
  /// **'Their card'**
  String get cardForWorker;

  /// No description provided for @cardForWorkerHelp.
  ///
  /// In en, this message translates to:
  /// **'Hold their FarmTap card to the back of the phone, or type the number printed on it.'**
  String get cardForWorkerHelp;

  /// No description provided for @cardReadNumber.
  ///
  /// In en, this message translates to:
  /// **'Card {number}'**
  String cardReadNumber(String number);

  /// No description provided for @changeCard.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeCard;

  /// No description provided for @noCardYet.
  ///
  /// In en, this message translates to:
  /// **'No card yet: give one later from the worker\'s page.'**
  String get noCardYet;

  /// No description provided for @yourRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get yourRoleLabel;

  /// No description provided for @ownerAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access: I own the farm and pay for FarmTap'**
  String get ownerAccess;

  /// No description provided for @managerAccess.
  ///
  /// In en, this message translates to:
  /// **'Manager: I run the farm for the owner'**
  String get managerAccess;

  /// No description provided for @accessTitle.
  ///
  /// In en, this message translates to:
  /// **'What can you do?'**
  String get accessTitle;

  /// No description provided for @cowsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type the number of cows, e.g. 25'**
  String get cowsInvalid;

  /// No description provided for @firstWorkerSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String firstWorkerSaved(String name);

  /// No description provided for @farmCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the farm. Check the internet and try again.'**
  String get farmCreateFailed;

  /// No description provided for @creatingFarm.
  ///
  /// In en, this message translates to:
  /// **'Creating your farm…'**
  String get creatingFarm;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeHelp.
  ///
  /// In en, this message translates to:
  /// **'Phone follows your phone\'s light or dark setting.'**
  String get themeHelp;

  /// No description provided for @soundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get soundsLabel;

  /// No description provided for @soundsSub.
  ///
  /// In en, this message translates to:
  /// **'Clicks and chimes when you save'**
  String get soundsSub;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @farmTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farmTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Stuck or have a question? Talk to the FarmTap team. We answer in English.'**
  String get helpIntro;

  /// No description provided for @helpWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get helpWhatsapp;

  /// No description provided for @helpWhatsappSub.
  ///
  /// In en, this message translates to:
  /// **'Fastest; send a screenshot if something looks wrong'**
  String get helpWhatsappSub;

  /// No description provided for @helpCall.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get helpCall;

  /// No description provided for @helpSms.
  ///
  /// In en, this message translates to:
  /// **'Send an SMS'**
  String get helpSms;

  /// No description provided for @helpOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that on this phone.'**
  String get helpOpenFailed;

  /// No description provided for @authNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet. Connect and try again.'**
  String get authNoInternet;

  /// No description provided for @authProviderOff.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not switched on for FarmTap yet. Use Google or email for now.'**
  String get authProviderOff;

  /// No description provided for @authOtherMethod.
  ///
  /// In en, this message translates to:
  /// **'This email already uses another sign-in. Use Google or email.'**
  String get authOtherMethod;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get authEmailInUse;

  /// No description provided for @authFailedCode.
  ///
  /// In en, this message translates to:
  /// **'That did not work ({code}). Try again.'**
  String authFailedCode(String code);

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordsDontMatch;

  /// No description provided for @passwordRuleStrong.
  ///
  /// In en, this message translates to:
  /// **'8+ characters with A-Z, a-z and 0-9'**
  String get passwordRuleStrong;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Add a capital letter, a small letter and a number.'**
  String get passwordWeak;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @suggestPassword.
  ///
  /// In en, this message translates to:
  /// **'Suggest a strong password'**
  String get suggestPassword;

  /// No description provided for @suggestedPasswordNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {password}. Save it somewhere safe.'**
  String suggestedPasswordNote(String password);

  /// No description provided for @copyWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'Same as WhatsApp'**
  String get copyWhatsappNumber;

  /// No description provided for @smsNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Alerts go here. It can be a different line from WhatsApp.'**
  String get smsNumberHelp;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Simple records for your business.\nWorks even without network.'**
  String get signInTagline;

  /// No description provided for @signInCardOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get signInCardOffline;

  /// No description provided for @signInCardTap.
  ///
  /// In en, this message translates to:
  /// **'Tap cards'**
  String get signInCardTap;

  /// No description provided for @signInCardBackup.
  ///
  /// In en, this message translates to:
  /// **'Safe backup'**
  String get signInCardBackup;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @scanCard.
  ///
  /// In en, this message translates to:
  /// **'Scan card'**
  String get scanCard;

  /// No description provided for @workerCardTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s worker card'**
  String workerCardTitle(String name);

  /// No description provided for @workerCardOnCollect.
  ///
  /// In en, this message translates to:
  /// **'This card is for clocking in and out. Farmers bringing milk need their own farmer card.'**
  String get workerCardOnCollect;

  /// No description provided for @openAttendance.
  ///
  /// In en, this message translates to:
  /// **'Clock in or out'**
  String get openAttendance;

  /// No description provided for @newCardTitle.
  ///
  /// In en, this message translates to:
  /// **'New card {number}'**
  String newCardTitle(String number);

  /// No description provided for @newCardOnCollect.
  ///
  /// In en, this message translates to:
  /// **'No farmer has this card yet. Add the farmer now and the card is theirs.'**
  String get newCardOnCollect;

  /// No description provided for @addFarmerWithCard.
  ///
  /// In en, this message translates to:
  /// **'Add farmer with this card'**
  String get addFarmerWithCard;

  /// No description provided for @newCardOnAttendance.
  ///
  /// In en, this message translates to:
  /// **'No worker has this card yet. Give it to a worker, then tap again to clock in.'**
  String get newCardOnAttendance;

  /// No description provided for @giveCardToWorker.
  ///
  /// In en, this message translates to:
  /// **'Give it to a worker'**
  String get giveCardToWorker;

  /// No description provided for @farmerCardOnAttendance.
  ///
  /// In en, this message translates to:
  /// **'This is {name}\'s farmer card. Worker cards clock in here.'**
  String farmerCardOnAttendance(String name);

  /// No description provided for @typeCardNumberLink.
  ///
  /// In en, this message translates to:
  /// **'Type the card number'**
  String get typeCardNumberLink;

  /// No description provided for @gettingFarmReady.
  ///
  /// In en, this message translates to:
  /// **'Getting {farm} ready…'**
  String gettingFarmReady(String farm);

  /// No description provided for @gettingFarmReadySub.
  ///
  /// In en, this message translates to:
  /// **'Bringing back your animals, workers and records.'**
  String get gettingFarmReadySub;

  /// No description provided for @welcomeBackName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBackName(String name);

  /// No description provided for @welcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(String name);

  /// No description provided for @welcomeBackPlain.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBackPlain;

  /// No description provided for @openingFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening {farm}'**
  String openingFarmTitle(String farm);

  /// No description provided for @farmPickerOneSub.
  ///
  /// In en, this message translates to:
  /// **'Your farm is ready on this phone. Tap it to open.'**
  String get farmPickerOneSub;

  /// No description provided for @farmPickerManySub.
  ///
  /// In en, this message translates to:
  /// **'You can open {count} farms. Pick the one to work on.'**
  String farmPickerManySub(int count);

  /// No description provided for @openFarmButton.
  ///
  /// In en, this message translates to:
  /// **'Open farm'**
  String get openFarmButton;

  /// No description provided for @placeDairyFarm.
  ///
  /// In en, this message translates to:
  /// **'Dairy farm'**
  String get placeDairyFarm;

  /// No description provided for @placeCentre.
  ///
  /// In en, this message translates to:
  /// **'Milk collection centre'**
  String get placeCentre;

  /// No description provided for @placeDairyAndCentre.
  ///
  /// In en, this message translates to:
  /// **'Dairy farm and milk centre'**
  String get placeDairyAndCentre;

  /// No description provided for @herdCows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cow} other{{count} cows}}'**
  String herdCows(int count);

  /// No description provided for @herdBirds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bird} other{{count} birds}}'**
  String herdBirds(int count);

  /// No description provided for @herdPigs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pig} other{{count} pigs}}'**
  String herdPigs(int count);

  /// No description provided for @herdAnimals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 animal} other{{count} animals}}'**
  String herdAnimals(int count);

  /// No description provided for @youAreRole.
  ///
  /// In en, this message translates to:
  /// **'You: {role}'**
  String youAreRole(String role);

  /// No description provided for @freeTrialLabel.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get freeTrialLabel;

  /// No description provided for @trialDaysLeftOf.
  ///
  /// In en, this message translates to:
  /// **'{left} of {total} days left'**
  String trialDaysLeftOf(int left, int total);

  /// No description provided for @paidUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Paid until {date}'**
  String paidUntilDate(String date);

  /// No description provided for @graceDaysToPay.
  ///
  /// In en, this message translates to:
  /// **'Payment due · {days, plural, =1{1 day} other{{days} days}} to pay'**
  String graceDaysToPay(int days);

  /// No description provided for @readOnlyPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Trial ended. You can look at records but not add new ones until you pay.'**
  String get readOnlyPickerHint;

  /// No description provided for @signedInAsEmail.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAsEmail(String email);

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// No description provided for @noFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your farm'**
  String get noFarmTitle;

  /// No description provided for @noFarmBody.
  ///
  /// In en, this message translates to:
  /// **'It takes about 2 minutes. Your first {days} days are free.'**
  String noFarmBody(int days);

  /// No description provided for @setUpMyFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up my farm'**
  String get setUpMyFarm;

  /// No description provided for @joinFarmHint.
  ///
  /// In en, this message translates to:
  /// **'Joining someone else\'s farm? Ask the owner to add your email, then tap Check again.'**
  String get joinFarmHint;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @placesOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load your farm'**
  String get placesOfflineTitle;

  /// No description provided for @placesOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'This phone needs the internet once to download your farm. After that it works offline.'**
  String get placesOfflineBody;

  /// No description provided for @farmLimitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'This account already has a farm. To run more than one farm, ask us about the multi-farm plan.'**
  String get farmLimitReachedBody;

  /// No description provided for @talkToUsWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Talk to us on WhatsApp'**
  String get talkToUsWhatsApp;

  /// No description provided for @multiFarmWhatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello FarmTap, I want to run more than one farm. Please tell me about the multi-farm plan.'**
  String get multiFarmWhatsAppMessage;

  /// No description provided for @multiFarmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Running more than one farm?'**
  String get multiFarmQuestion;

  /// No description provided for @multiFarmAnswer.
  ///
  /// In en, this message translates to:
  /// **'One account runs one farm. Ask us about the multi-farm plan.'**
  String get multiFarmAnswer;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfSub.
  ///
  /// In en, this message translates to:
  /// **'To print, or send on WhatsApp or email'**
  String get exportPdfSub;

  /// No description provided for @exportSheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (Excel)'**
  String get exportSheet;

  /// No description provided for @exportSheetSub.
  ///
  /// In en, this message translates to:
  /// **'Opens in Excel or Google Sheets'**
  String get exportSheetSub;

  /// No description provided for @nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet'**
  String get nothingToExport;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make the file. Try again.'**
  String get exportFailed;

  /// No description provided for @viewingDay.
  ///
  /// In en, this message translates to:
  /// **'Viewing {day}'**
  String viewingDay(String day);

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get backToToday;

  /// No description provided for @noMilkRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'No milk recorded today yet. Record milk first, then split it here.'**
  String get noMilkRecordedToday;

  /// No description provided for @useMoreThanMilked.
  ///
  /// In en, this message translates to:
  /// **'{litres} more than was milked today'**
  String useMoreThanMilked(String litres);

  /// No description provided for @buyerCentre.
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get buyerCentre;

  /// No description provided for @buyerShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get buyerShop;

  /// No description provided for @buyerNeighbours.
  ///
  /// In en, this message translates to:
  /// **'Neighbours'**
  String get buyerNeighbours;

  /// No description provided for @saleSaved.
  ///
  /// In en, this message translates to:
  /// **'Sale saved'**
  String get saleSaved;

  /// No description provided for @salePaidSaved.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get salePaidSaved;

  /// No description provided for @saleUnpaidSaved.
  ///
  /// In en, this message translates to:
  /// **'Marked as not paid'**
  String get saleUnpaidSaved;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String paidOn(String date);

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as not paid'**
  String get markUnpaid;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @noSalesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add each sale of milk, to the centre, a shop or neighbours. Unpaid sales show what buyers owe you.'**
  String get noSalesYetBody;

  /// No description provided for @enterBuyer.
  ///
  /// In en, this message translates to:
  /// **'Enter who bought the milk'**
  String get enterBuyer;

  /// No description provided for @enterLitres.
  ///
  /// In en, this message translates to:
  /// **'Enter the litres'**
  String get enterLitres;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter the price'**
  String get enterPrice;

  /// No description provided for @notPaidYet.
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get notPaidYet;

  /// No description provided for @paidNow.
  ///
  /// In en, this message translates to:
  /// **'Paid now'**
  String get paidNow;

  /// No description provided for @saveSale.
  ///
  /// In en, this message translates to:
  /// **'Save sale'**
  String get saveSale;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from phone'**
  String get choosePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the photo. Try again.'**
  String get photoFailed;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'FarmTap needs the camera to scan. Allow it in your phone settings.'**
  String get cameraPermissionNeeded;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'The camera is not available. Type the number instead.'**
  String get cameraNotAvailable;

  /// No description provided for @noAnimalWithTag.
  ///
  /// In en, this message translates to:
  /// **'No animal with tag {tag} on this farm'**
  String noAnimalWithTag(String tag);

  /// No description provided for @tagTaken.
  ///
  /// In en, this message translates to:
  /// **'Another animal already has tag {tag}'**
  String tagTaken(String tag);

  /// No description provided for @editAnimal.
  ///
  /// In en, this message translates to:
  /// **'Edit animal'**
  String get editAnimal;

  /// No description provided for @statusNow.
  ///
  /// In en, this message translates to:
  /// **'What is she doing now?'**
  String get statusNow;

  /// No description provided for @animalSoldSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} recorded as sold'**
  String animalSoldSaved(String name);

  /// No description provided for @sellAnimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell {name}'**
  String sellAnimalTitle(String name);

  /// No description provided for @sellAnimalBody.
  ///
  /// In en, this message translates to:
  /// **'She moves to past animals. The price is added to this month\'s income.'**
  String get sellAnimalBody;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get salePrice;

  /// No description provided for @boughtByOptional.
  ///
  /// In en, this message translates to:
  /// **'Bought by (optional)'**
  String get boughtByOptional;

  /// No description provided for @recordSale.
  ///
  /// In en, this message translates to:
  /// **'Record sale'**
  String get recordSale;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get conditionLabel;

  /// No description provided for @givenByLabel.
  ///
  /// In en, this message translates to:
  /// **'Given by'**
  String get givenByLabel;

  /// No description provided for @milkSafeFrom.
  ///
  /// In en, this message translates to:
  /// **'Milk safe from'**
  String get milkSafeFrom;

  /// No description provided for @averagePerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Average a day'**
  String get averagePerDayLabel;

  /// No description provided for @cardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardLabel;

  /// No description provided for @grossLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross (UGX)'**
  String get grossLabel;

  /// No description provided for @deductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Deductions (UGX)'**
  String get deductionsLabel;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'To pay (UGX)'**
  String get netLabel;

  /// No description provided for @incomeAnimalSale.
  ///
  /// In en, this message translates to:
  /// **'Animal sold'**
  String get incomeAnimalSale;

  /// No description provided for @incomeCalfSale.
  ///
  /// In en, this message translates to:
  /// **'Calf sold'**
  String get incomeCalfSale;

  /// No description provided for @incomeManure.
  ///
  /// In en, this message translates to:
  /// **'Manure'**
  String get incomeManure;

  /// No description provided for @incomeHire.
  ///
  /// In en, this message translates to:
  /// **'Bull service / hire'**
  String get incomeHire;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// No description provided for @incomeSaved.
  ///
  /// In en, this message translates to:
  /// **'{amount} income saved'**
  String incomeSaved(String amount);

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get sourceLabel;

  /// No description provided for @otherIncomeCaption.
  ///
  /// In en, this message translates to:
  /// **'Other {amount}'**
  String otherIncomeCaption(String amount);

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Remove this expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'Only remove an expense entered by mistake. It stays in the audit trail.'**
  String get deleteExpenseBody;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense removed'**
  String get expenseDeleted;

  /// No description provided for @fromFeedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Made by a feed purchase. Change it in Feeding.'**
  String get fromFeedPurchase;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No money recorded this month'**
  String get noExpensesYet;

  /// No description provided for @noExpensesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add expenses as you spend, and milk sales as you sell. Profit and cost per litre are worked out for you.'**
  String get noExpensesYetBody;

  /// No description provided for @makingReport.
  ///
  /// In en, this message translates to:
  /// **'Making the report…'**
  String get makingReport;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @notSetYet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get notSetYet;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get whatsappNumber;

  /// No description provided for @setWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'Set the WhatsApp number that gets this report.'**
  String get setWhatsappNumber;

  /// No description provided for @sendNowWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send today\'s report on WhatsApp'**
  String get sendNowWhatsapp;

  /// No description provided for @addAnimalsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your animals in Herd first, then record treatments here.'**
  String get addAnimalsFirst;

  /// No description provided for @diseaseName.
  ///
  /// In en, this message translates to:
  /// **'Name of the disease'**
  String get diseaseName;

  /// No description provided for @whatYouSee.
  ///
  /// In en, this message translates to:
  /// **'What you see (optional)'**
  String get whatYouSee;

  /// No description provided for @boughtMore.
  ///
  /// In en, this message translates to:
  /// **'Bought more'**
  String get boughtMore;

  /// No description provided for @countStock.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get countStock;

  /// No description provided for @howManyNow.
  ///
  /// In en, this message translates to:
  /// **'How many are on the shelf now'**
  String get howManyNow;

  /// No description provided for @howManyBought.
  ///
  /// In en, this message translates to:
  /// **'How many did you buy'**
  String get howManyBought;

  /// No description provided for @pricePaidOptional.
  ///
  /// In en, this message translates to:
  /// **'Price paid (optional)'**
  String get pricePaidOptional;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterAmount;

  /// No description provided for @stockSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock saved'**
  String get stockSaved;

  /// No description provided for @markJobDone.
  ///
  /// In en, this message translates to:
  /// **'Is “{job}” done?'**
  String markJobDone(String job);

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Yes, it is done'**
  String get markDone;

  /// No description provided for @jobDone.
  ///
  /// In en, this message translates to:
  /// **'Marked as done'**
  String get jobDone;

  /// No description provided for @noHealthJobs.
  ///
  /// In en, this message translates to:
  /// **'No health jobs planned'**
  String get noHealthJobs;

  /// No description provided for @noHealthJobsBody.
  ///
  /// In en, this message translates to:
  /// **'Add dipping, deworming and vaccinations so nobody forgets them.'**
  String get noHealthJobsBody;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @feedNapier.
  ///
  /// In en, this message translates to:
  /// **'Napier grass'**
  String get feedNapier;

  /// No description provided for @feedHay.
  ///
  /// In en, this message translates to:
  /// **'Hay'**
  String get feedHay;

  /// No description provided for @feedCottonCake.
  ///
  /// In en, this message translates to:
  /// **'Cotton seed cake'**
  String get feedCottonCake;

  /// No description provided for @feedBrewersWaste.
  ///
  /// In en, this message translates to:
  /// **'Brewers\' waste'**
  String get feedBrewersWaste;

  /// No description provided for @countFeedStock.
  ///
  /// In en, this message translates to:
  /// **'Count stock'**
  String get countFeedStock;

  /// No description provided for @countFeedStockSub.
  ///
  /// In en, this message translates to:
  /// **'What is in the store now. Do this when you start, and whenever the numbers look wrong.'**
  String get countFeedStockSub;

  /// No description provided for @addFemalesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your cows and heifers in Herd first, then record heats and services here.'**
  String get addFemalesFirst;

  /// No description provided for @editFarmer.
  ///
  /// In en, this message translates to:
  /// **'Edit farmer'**
  String get editFarmer;

  /// No description provided for @sendSmsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Send SMS receipts'**
  String get sendSmsReceipts;

  /// No description provided for @sendSmsReceiptsHint.
  ///
  /// In en, this message translates to:
  /// **'A text after every delivery'**
  String get sendSmsReceiptsHint;

  /// No description provided for @priceSaved.
  ///
  /// In en, this message translates to:
  /// **'Price saved: {price} per litre'**
  String priceSaved(String price);

  /// No description provided for @pricePerLitreHint.
  ///
  /// In en, this message translates to:
  /// **'What the centre pays farmers for each litre. Amounts owed update straight away.'**
  String get pricePerLitreHint;

  /// No description provided for @phoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneCopied;

  /// No description provided for @absentWord.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentWord;

  /// No description provided for @presentWord.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentWord;

  /// No description provided for @broughtToday.
  ///
  /// In en, this message translates to:
  /// **'Brought {litres} today'**
  String broughtToday(String litres);

  /// No description provided for @notDeliveredToday.
  ///
  /// In en, this message translates to:
  /// **'No milk today'**
  String get notDeliveredToday;

  /// No description provided for @cardNotUsable.
  ///
  /// In en, this message translates to:
  /// **'Card cannot be used'**
  String get cardNotUsable;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo for the ID card'**
  String get photoSheetTitle;

  /// No description provided for @photoSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Face the camera, in good light.'**
  String get photoSheetBody;

  /// No description provided for @photoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get photoSaved;

  /// No description provided for @photoSavedLocal.
  ///
  /// In en, this message translates to:
  /// **'Photo saved. The full photo uploads when cloud storage is on.'**
  String get photoSavedLocal;

  /// No description provided for @photoNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo not saved. Try again.'**
  String get photoNotSaved;

  /// No description provided for @clockInOutShort.
  ///
  /// In en, this message translates to:
  /// **'Clock in/out'**
  String get clockInOutShort;

  /// No description provided for @lookUpShort.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get lookUpShort;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @emergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @ninLabel.
  ///
  /// In en, this message translates to:
  /// **'NIN'**
  String get ninLabel;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get memberSinceLabel;

  /// No description provided for @issuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issuedLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idNumberLabel;

  /// No description provided for @downloadCardPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadCardPdf;

  /// No description provided for @printCard.
  ///
  /// In en, this message translates to:
  /// **'Print card'**
  String get printCard;

  /// No description provided for @printOnA4.
  ///
  /// In en, this message translates to:
  /// **'Print on A4 paper'**
  String get printOnA4;

  /// No description provided for @giveCardToSomeone.
  ///
  /// In en, this message translates to:
  /// **'Give this card'**
  String get giveCardToSomeone;

  /// No description provided for @holdQrToCamera.
  ///
  /// In en, this message translates to:
  /// **'Hold the card\'s QR code to the camera'**
  String get holdQrToCamera;

  /// No description provided for @idCardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get idCardBack;

  /// No description provided for @idCardFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get idCardFront;

  /// No description provided for @idCardFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'ID card of {name}, front'**
  String idCardFrontLabel(String name);

  /// No description provided for @idCardBackLabel.
  ///
  /// In en, this message translates to:
  /// **'ID card of {name}, back'**
  String idCardBackLabel(String name);

  /// No description provided for @idCardIfFound.
  ///
  /// In en, this message translates to:
  /// **'If found, please return to the farm'**
  String get idCardIfFound;

  /// No description provided for @idCardNoCardTitle.
  ///
  /// In en, this message translates to:
  /// **'No card yet'**
  String get idCardNoCardTitle;

  /// No description provided for @idCardNoCardBody.
  ///
  /// In en, this message translates to:
  /// **'Give a card first. Its number and QR code go on the print.'**
  String get idCardNoCardBody;

  /// No description provided for @idCardPrintHelp.
  ///
  /// In en, this message translates to:
  /// **'Card printer: print the 2 pages on a blank PVC card. Normal printer: print on A4, cut along the marks and laminate.'**
  String get idCardPrintHelp;

  /// No description provided for @idCardScanMe.
  ///
  /// In en, this message translates to:
  /// **'Scan me'**
  String get idCardScanMe;

  /// No description provided for @idCardStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get idCardStaff;

  /// No description provided for @idCardSupplier.
  ///
  /// In en, this message translates to:
  /// **'Milk supplier'**
  String get idCardSupplier;

  /// No description provided for @idCardTitle.
  ///
  /// In en, this message translates to:
  /// **'ID card'**
  String get idCardTitle;

  /// No description provided for @idCardValidNote.
  ///
  /// In en, this message translates to:
  /// **'Valid until revoked. Tap or scan at the farm.'**
  String get idCardValidNote;

  /// No description provided for @lastPaidLine.
  ///
  /// In en, this message translates to:
  /// **'Last paid {amount} on {date}'**
  String lastPaidLine(String amount, String date);

  /// No description provided for @payrollLine.
  ///
  /// In en, this message translates to:
  /// **'Wage {wage} · advances {advances} · paid {paid}'**
  String payrollLine(String wage, String advances, String paid);

  /// No description provided for @lostCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card {number} was reported lost'**
  String lostCardTitle(String number);

  /// No description provided for @lostCardBody.
  ///
  /// In en, this message translates to:
  /// **'It belonged to {name} ({date}). Keep the card and tell the manager.'**
  String lostCardBody(String name, String date);

  /// No description provided for @returnedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card {number} was returned'**
  String returnedCardTitle(String number);

  /// No description provided for @returnedCardBody.
  ///
  /// In en, this message translates to:
  /// **'It belonged to {name}. Give it to someone new from their page.'**
  String returnedCardBody(String name);

  /// No description provided for @unknownCardBody.
  ///
  /// In en, this message translates to:
  /// **'No one has this card yet.'**
  String get unknownCardBody;

  /// No description provided for @otherFarmCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card from another farm'**
  String get otherFarmCardTitle;

  /// No description provided for @otherFarmCardBody.
  ///
  /// In en, this message translates to:
  /// **'This card belongs to another farm and does not work here.'**
  String get otherFarmCardBody;

  /// No description provided for @moneyOwedLabel.
  ///
  /// In en, this message translates to:
  /// **'Money owed'**
  String get moneyOwedLabel;

  /// No description provided for @thisPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get thisPeriodLabel;

  /// No description provided for @payDayLine.
  ///
  /// In en, this message translates to:
  /// **'Pay day {date} · {price} a litre'**
  String payDayLine(String date, String price);

  /// No description provided for @rejectedWord.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get rejectedWord;

  /// No description provided for @nextCard.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get nextCard;

  /// No description provided for @openDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get openDetails;

  /// No description provided for @scanModeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Each card clocks in or out'**
  String get scanModeAttendance;

  /// No description provided for @scanModeLookUp.
  ///
  /// In en, this message translates to:
  /// **'Each card shows who it is'**
  String get scanModeLookUp;

  /// No description provided for @scanQrInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan QR with camera'**
  String get scanQrInstead;

  /// No description provided for @useNfcInstead.
  ///
  /// In en, this message translates to:
  /// **'Tap cards instead'**
  String get useNfcInstead;

  /// No description provided for @scanStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan cards'**
  String get scanStationTitle;

  /// No description provided for @scanStationBody.
  ///
  /// In en, this message translates to:
  /// **'Tap one card after another. Each person shows for a few seconds.'**
  String get scanStationBody;

  /// No description provided for @scannedTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanned ({n})'**
  String scannedTodayTitle(int n);

  /// No description provided for @statusClockedIn.
  ///
  /// In en, this message translates to:
  /// **'Clocked in {time}'**
  String statusClockedIn(String time);

  /// No description provided for @statusClockedOut.
  ///
  /// In en, this message translates to:
  /// **'Clocked out {time}'**
  String statusClockedOut(String time);

  /// No description provided for @statusLeftAt.
  ///
  /// In en, this message translates to:
  /// **'Left at {time}'**
  String statusLeftAt(String time);

  /// No description provided for @statusPresentSince.
  ///
  /// In en, this message translates to:
  /// **'Present since {time}'**
  String statusPresentSince(String time);

  /// No description provided for @statusNotInToday.
  ///
  /// In en, this message translates to:
  /// **'Not in today'**
  String get statusNotInToday;

  /// No description provided for @advanceWord.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advanceWord;

  /// No description provided for @advancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get advancesLabel;

  /// No description provided for @alreadyHasCard.
  ///
  /// In en, this message translates to:
  /// **'This person already has a card. Replace it instead.'**
  String get alreadyHasCard;

  /// No description provided for @cardActive.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get cardActive;

  /// No description provided for @cardHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Card history'**
  String get cardHistoryTitle;

  /// No description provided for @cardLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get cardLost;

  /// No description provided for @cardNotGivenTitle.
  ///
  /// In en, this message translates to:
  /// **'Card not given'**
  String get cardNotGivenTitle;

  /// No description provided for @cardRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'All cards'**
  String get cardRegisterTitle;

  /// No description provided for @cardReturned.
  ///
  /// In en, this message translates to:
  /// **'Given back'**
  String get cardReturned;

  /// No description provided for @changeMyPin.
  ///
  /// In en, this message translates to:
  /// **'Change my PIN'**
  String get changeMyPin;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @chooseOwnPinBody.
  ///
  /// In en, this message translates to:
  /// **'Pick 4 numbers only you know. Not 1234, not 0000.'**
  String get chooseOwnPinBody;

  /// No description provided for @chooseOwnPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your own PIN'**
  String get chooseOwnPinTitle;

  /// No description provided for @confirmPinBody.
  ///
  /// In en, this message translates to:
  /// **'Type the same 4 numbers again.'**
  String get confirmPinBody;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get confirmPinTitle;

  /// No description provided for @departmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Department (optional)'**
  String get departmentOptional;

  /// No description provided for @deptAnimalHealth.
  ///
  /// In en, this message translates to:
  /// **'Animal health'**
  String get deptAnimalHealth;

  /// No description provided for @deptCollection.
  ///
  /// In en, this message translates to:
  /// **'Milk collection'**
  String get deptCollection;

  /// No description provided for @deptFeeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get deptFeeding;

  /// No description provided for @deptField.
  ///
  /// In en, this message translates to:
  /// **'Field and pasture'**
  String get deptField;

  /// No description provided for @deptHerd.
  ///
  /// In en, this message translates to:
  /// **'Herd'**
  String get deptHerd;

  /// No description provided for @deptKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get deptKitchen;

  /// No description provided for @deptManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get deptManagement;

  /// No description provided for @deptMilking.
  ///
  /// In en, this message translates to:
  /// **'Milking'**
  String get deptMilking;

  /// No description provided for @deptOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get deptOffice;

  /// No description provided for @deptSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get deptSecurity;

  /// No description provided for @deptTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get deptTransport;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// No description provided for @emergencyNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Next of kin (optional)'**
  String get emergencyNameOptional;

  /// No description provided for @emergencyPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Next of kin phone (optional)'**
  String get emergencyPhoneOptional;

  /// No description provided for @idCardRowBody.
  ///
  /// In en, this message translates to:
  /// **'See, print or download the ID card'**
  String get idCardRowBody;

  /// No description provided for @myAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'My days'**
  String get myAttendanceTitle;

  /// No description provided for @myPageShort.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get myPageShort;

  /// No description provided for @myPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My page'**
  String get myPageTitle;

  /// No description provided for @myTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasksTitle;

  /// No description provided for @nfcChipWord.
  ///
  /// In en, this message translates to:
  /// **'NFC chip'**
  String get nfcChipWord;

  /// No description provided for @ninOptional.
  ///
  /// In en, this message translates to:
  /// **'National ID number (optional)'**
  String get ninOptional;

  /// No description provided for @noCardsToPrint.
  ///
  /// In en, this message translates to:
  /// **'No one has a card yet. Give cards first.'**
  String get noCardsToPrint;

  /// No description provided for @noCardsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Cards you give to workers and milk suppliers show here.'**
  String get noCardsYetBody;

  /// No description provided for @noCardsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get noCardsYetTitle;

  /// No description provided for @noTasksForYou.
  ///
  /// In en, this message translates to:
  /// **'No tasks for you today'**
  String get noTasksForYou;

  /// No description provided for @openMyCard.
  ///
  /// In en, this message translates to:
  /// **'Open my card'**
  String get openMyCard;

  /// No description provided for @paidInFull.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get paidInFull;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneSignInBadge.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in'**
  String get phoneSignInBadge;

  /// No description provided for @pinChangedToast.
  ///
  /// In en, this message translates to:
  /// **'Your new PIN is saved'**
  String get pinChangedToast;

  /// No description provided for @pinTooEasy.
  ///
  /// In en, this message translates to:
  /// **'Too easy to guess. Pick other numbers.'**
  String get pinTooEasy;

  /// No description provided for @pinWhatFor.
  ///
  /// In en, this message translates to:
  /// **'Your card says who you are. Your PIN proves it is you, so nobody can clock in or record milk with your card. On your own phone it is your password.'**
  String get pinWhatFor;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The two PINs are not the same. Try again.'**
  String get pinsDoNotMatch;

  /// No description provided for @printAllCards.
  ///
  /// In en, this message translates to:
  /// **'Print all cards'**
  String get printAllCards;

  /// No description provided for @printedCardNoChip.
  ///
  /// In en, this message translates to:
  /// **'Printed card, no chip (QR and number only)'**
  String get printedCardNoChip;

  /// No description provided for @revokeCardRow.
  ///
  /// In en, this message translates to:
  /// **'Take back or report lost'**
  String get revokeCardRow;

  /// No description provided for @revokeCardRowBody.
  ///
  /// In en, this message translates to:
  /// **'The card stops working at once'**
  String get revokeCardRowBody;

  /// No description provided for @revokeLost.
  ///
  /// In en, this message translates to:
  /// **'Lost or stolen: never use again'**
  String get revokeLost;

  /// No description provided for @revokeReturned.
  ///
  /// In en, this message translates to:
  /// **'Given back: can go to someone new'**
  String get revokeReturned;

  /// No description provided for @setUpPhoneSignIn.
  ///
  /// In en, this message translates to:
  /// **'Set up phone sign-in'**
  String get setUpPhoneSignIn;

  /// No description provided for @setUpPhoneSignInBody.
  ///
  /// In en, this message translates to:
  /// **'They sign in on their own phone with phone number and PIN'**
  String get setUpPhoneSignInBody;

  /// No description provided for @staffLoginNotMade.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in was not set up. Check the internet and try again.'**
  String get staffLoginNotMade;

  /// No description provided for @staffLoginOtherFarm.
  ///
  /// In en, this message translates to:
  /// **'This phone number already signs in to another farm.'**
  String get staffLoginOtherFarm;

  /// No description provided for @staffPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type a Ugandan phone number, like 0701 220 318.'**
  String get staffPhoneInvalid;

  /// No description provided for @staffSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Type the phone number your farm saved for you.'**
  String get staffSignInBody;

  /// No description provided for @staffSignInEntry.
  ///
  /// In en, this message translates to:
  /// **'I work on a farm: sign in with phone and PIN'**
  String get staffSignInEntry;

  /// No description provided for @staffSignInHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your farm manager. They add your phone number and give you a PIN to start. The first time, you choose your own PIN.'**
  String get staffSignInHelpBody;

  /// No description provided for @staffSignInHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'No PIN yet?'**
  String get staffSignInHelpTitle;

  /// No description provided for @staffSignInOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet. Sign-in needs internet the first time.'**
  String get staffSignInOffline;

  /// No description provided for @staffSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in as a worker'**
  String get staffSignInTitle;

  /// No description provided for @staffSignInTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes and try again.'**
  String get staffSignInTooMany;

  /// No description provided for @staffSignInWrong.
  ///
  /// In en, this message translates to:
  /// **'Phone number or PIN is wrong.'**
  String get staffSignInWrong;

  /// No description provided for @temporaryPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting PIN'**
  String get temporaryPinTitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @villageOptional.
  ///
  /// In en, this message translates to:
  /// **'Village (optional)'**
  String get villageOptional;

  /// No description provided for @wageLabel.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wageLabel;

  /// No description provided for @wageWord.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wageWord;

  /// No description provided for @cardLostCannotReuse.
  ///
  /// In en, this message translates to:
  /// **'Card {card} was reported lost. It can never be given again.'**
  String cardLostCannotReuse(String card);

  /// No description provided for @cardRevokedToast.
  ///
  /// In en, this message translates to:
  /// **'Card {card} no longer works'**
  String cardRevokedToast(String card);

  /// No description provided for @cardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 working card} other{{count} working cards}}'**
  String cardsCount(int count);

  /// No description provided for @endedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String endedOn(String date);

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Given {date}'**
  String issuedOn(String date);

  /// No description provided for @myPayTitle.
  ///
  /// In en, this message translates to:
  /// **'My pay for {month}'**
  String myPayTitle(String month);

  /// No description provided for @opensSections.
  ///
  /// In en, this message translates to:
  /// **'Opens: {sections}'**
  String opensSections(String sections);

  /// No description provided for @replaceCardBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s card {card} will be marked lost and stop working. Then tap the new card.'**
  String replaceCardBody(String name, String card);

  /// No description provided for @replaceCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace card {card}?'**
  String replaceCardTitle(String card);

  /// No description provided for @resetPinBodyTemp.
  ///
  /// In en, this message translates to:
  /// **'Give {name} a starting PIN. They must choose their own the next time they sign in.'**
  String resetPinBodyTemp(String name);

  /// No description provided for @resetPinDoneTemp.
  ///
  /// In en, this message translates to:
  /// **'{name} must choose a new PIN at next sign-in'**
  String resetPinDoneTemp(String name);

  /// No description provided for @revokeCardBody.
  ///
  /// In en, this message translates to:
  /// **'What happened to {name}\'s card?'**
  String revokeCardBody(String name);

  /// No description provided for @revokeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card {card}'**
  String revokeCardTitle(String card);

  /// No description provided for @staffLoginMade.
  ///
  /// In en, this message translates to:
  /// **'{name} can now sign in on their phone with {phone} and the starting PIN'**
  String staffLoginMade(String name, String phone);

  /// No description provided for @staffSignInPinBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN for {phone}'**
  String staffSignInPinBody(String phone);

  /// No description provided for @temporaryPinBody.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} this PIN. They choose their own the first time.'**
  String temporaryPinBody(String name);

  /// No description provided for @sendOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get sendOnWhatsapp;

  /// No description provided for @sendBySms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sendBySms;

  /// No description provided for @smsAppOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the SMS app on this phone.'**
  String get smsAppOpenFailed;

  /// No description provided for @whatsappOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open WhatsApp. Is it installed? Try SMS.'**
  String get whatsappOpenFailed;

  /// No description provided for @messagesToSend.
  ///
  /// In en, this message translates to:
  /// **'Messages to send'**
  String get messagesToSend;

  /// No description provided for @messagesFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Messages go out from this phone\'s WhatsApp or SMS app with the words already typed. Tap Send there. FarmTap charges nothing; SMS uses your own airtime or bundle.'**
  String get messagesFreeNote;

  /// No description provided for @noMessagesWaiting.
  ///
  /// In en, this message translates to:
  /// **'No messages waiting'**
  String get noMessagesWaiting;

  /// No description provided for @noMessagesWaitingSub.
  ///
  /// In en, this message translates to:
  /// **'Milk receipts and weekly statements appear here, ready to send.'**
  String get noMessagesWaitingSub;

  /// No description provided for @messagesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message waiting} other{{count} messages waiting}}'**
  String messagesWaiting(int count);

  /// No description provided for @sendNextTo.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String sendNextTo(String name);

  /// No description provided for @sendNextOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send next · WhatsApp'**
  String get sendNextOnWhatsapp;

  /// No description provided for @sendNextBySms.
  ///
  /// In en, this message translates to:
  /// **'Send next · SMS'**
  String get sendNextBySms;

  /// No description provided for @recentlySent.
  ///
  /// In en, this message translates to:
  /// **'Recently sent'**
  String get recentlySent;

  /// No description provided for @sentFromThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Sent from this phone'**
  String get sentFromThisPhone;

  /// No description provided for @msgSentAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Sent automatically'**
  String get msgSentAutomatically;

  /// No description provided for @msgKindReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get msgKindReceipt;

  /// No description provided for @msgKindStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get msgKindStatement;

  /// No description provided for @removeMessage.
  ///
  /// In en, this message translates to:
  /// **'Don\'t send'**
  String get removeMessage;

  /// No description provided for @statementsQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No farmer delivered this week, so there is nothing to send.} =1{1 statement is ready to send.} other{{count} statements are ready to send.}}'**
  String statementsQueued(int count);

  /// No description provided for @statementsReady.
  ///
  /// In en, this message translates to:
  /// **'Statements ready'**
  String get statementsReady;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get sendNow;

  /// No description provided for @statementsFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Sent one by one from this phone\'s WhatsApp or SMS. FarmTap charges nothing.'**
  String get statementsFreeNote;

  /// No description provided for @readyEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Ready every day at {time}. Tap a button to send it to {phone}.'**
  String readyEveryDay(String phone, String time);

  /// No description provided for @receiptWaiting.
  ///
  /// In en, this message translates to:
  /// **'Receipt ready to send'**
  String get receiptWaiting;

  /// No description provided for @opsContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get opsContacts;

  /// No description provided for @opsAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get opsAddContact;

  /// No description provided for @opsEditContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get opsEditContact;

  /// No description provided for @opsContactKind.
  ///
  /// In en, this message translates to:
  /// **'Who is this'**
  String get opsContactKind;

  /// No description provided for @opsContactNeeds.
  ///
  /// In en, this message translates to:
  /// **'Add a name and a phone number of at least 9 digits.'**
  String get opsContactNeeds;

  /// No description provided for @opsContactOrg.
  ///
  /// In en, this message translates to:
  /// **'Business or clinic (optional)'**
  String get opsContactOrg;

  /// No description provided for @opsContactPlace.
  ///
  /// In en, this message translates to:
  /// **'Where they are (optional)'**
  String get opsContactPlace;

  /// No description provided for @opsShowWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers can see this contact'**
  String get opsShowWorkers;

  /// No description provided for @opsSearchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get opsSearchContacts;

  /// No description provided for @opsNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get opsNoContacts;

  /// No description provided for @opsNoContactsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your vet, AI technician, feed suppliers and buyers here so anyone on the farm can call them.'**
  String get opsNoContactsBody;

  /// No description provided for @opsWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get opsWhatsapp;

  /// No description provided for @opsKindVet.
  ///
  /// In en, this message translates to:
  /// **'Vets'**
  String get opsKindVet;

  /// No description provided for @opsKindAi.
  ///
  /// In en, this message translates to:
  /// **'AI technicians'**
  String get opsKindAi;

  /// No description provided for @opsKindFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed suppliers'**
  String get opsKindFeed;

  /// No description provided for @opsKindAgrovet.
  ///
  /// In en, this message translates to:
  /// **'Agrovet shops'**
  String get opsKindAgrovet;

  /// No description provided for @opsKindBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get opsKindBuyer;

  /// No description provided for @opsKindTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get opsKindTransport;

  /// No description provided for @opsKindEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get opsKindEmergency;

  /// No description provided for @opsKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get opsKindOther;

  /// No description provided for @opsRoster.
  ///
  /// In en, this message translates to:
  /// **'Duty roster'**
  String get opsRoster;

  /// No description provided for @opsAddDuty.
  ///
  /// In en, this message translates to:
  /// **'Add duty'**
  String get opsAddDuty;

  /// No description provided for @opsEditDuty.
  ///
  /// In en, this message translates to:
  /// **'Edit duty'**
  String get opsEditDuty;

  /// No description provided for @opsDutyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Pick who does it and on which days.'**
  String get opsDutyNeeds;

  /// No description provided for @opsNoDuties.
  ///
  /// In en, this message translates to:
  /// **'No duties yet'**
  String get opsNoDuties;

  /// No description provided for @opsNoDutiesBody.
  ///
  /// In en, this message translates to:
  /// **'Give each job a person and the days they do it. Stand-ins cover when someone is away.'**
  String get opsNoDutiesBody;

  /// No description provided for @opsNothingThatDay.
  ///
  /// In en, this message translates to:
  /// **'No duties on this day.'**
  String get opsNothingThatDay;

  /// No description provided for @opsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get opsTomorrow;

  /// No description provided for @opsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get opsYou;

  /// No description provided for @opsNobodyOn.
  ///
  /// In en, this message translates to:
  /// **'{name} is away and nobody stands in'**
  String opsNobodyOn(String name);

  /// No description provided for @opsStandsIn.
  ///
  /// In en, this message translates to:
  /// **'{who} stands in for {colleague}'**
  String opsStandsIn(String who, String colleague);

  /// No description provided for @opsAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get opsAway;

  /// No description provided for @opsAddAway.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get opsAddAway;

  /// No description provided for @opsNobodyAway.
  ///
  /// In en, this message translates to:
  /// **'Nobody is away.'**
  String get opsNobodyAway;

  /// No description provided for @opsAddWorkersFirst.
  ///
  /// In en, this message translates to:
  /// **'Add workers first, then give them duties.'**
  String get opsAddWorkersFirst;

  /// No description provided for @opsJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get opsJob;

  /// No description provided for @opsJobName.
  ///
  /// In en, this message translates to:
  /// **'Name of the job'**
  String get opsJobName;

  /// No description provided for @opsWho.
  ///
  /// In en, this message translates to:
  /// **'Who does it'**
  String get opsWho;

  /// No description provided for @opsStandIn.
  ///
  /// In en, this message translates to:
  /// **'Stand-in when away'**
  String get opsStandIn;

  /// No description provided for @opsNoStandIn.
  ///
  /// In en, this message translates to:
  /// **'No stand-in'**
  String get opsNoStandIn;

  /// No description provided for @opsShift.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get opsShift;

  /// No description provided for @opsEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get opsEveryDay;

  /// No description provided for @opsSomeDays.
  ///
  /// In en, this message translates to:
  /// **'Some days'**
  String get opsSomeDays;

  /// No description provided for @opsWhichDays.
  ///
  /// In en, this message translates to:
  /// **'Which days'**
  String get opsWhichDays;

  /// No description provided for @opsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get opsFrom;

  /// No description provided for @opsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get opsTo;

  /// No description provided for @opsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get opsReason;

  /// No description provided for @opsDutyMilking.
  ///
  /// In en, this message translates to:
  /// **'Milking'**
  String get opsDutyMilking;

  /// No description provided for @opsDutyFeeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get opsDutyFeeding;

  /// No description provided for @opsDutyHealth.
  ///
  /// In en, this message translates to:
  /// **'Health checks'**
  String get opsDutyHealth;

  /// No description provided for @opsDutyCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get opsDutyCleaning;

  /// No description provided for @opsDutyGrazing.
  ///
  /// In en, this message translates to:
  /// **'Grazing'**
  String get opsDutyGrazing;

  /// No description provided for @opsDutySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get opsDutySecurity;

  /// No description provided for @opsDutyCollection.
  ///
  /// In en, this message translates to:
  /// **'Milk collection'**
  String get opsDutyCollection;

  /// No description provided for @opsDutyManager.
  ///
  /// In en, this message translates to:
  /// **'Manager on duty'**
  String get opsDutyManager;

  /// No description provided for @opsDutyOther.
  ///
  /// In en, this message translates to:
  /// **'Other job'**
  String get opsDutyOther;

  /// No description provided for @opsShiftMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get opsShiftMorning;

  /// No description provided for @opsShiftAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get opsShiftAfternoon;

  /// No description provided for @opsShiftEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get opsShiftEvening;

  /// No description provided for @opsShiftNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get opsShiftNight;

  /// No description provided for @opsShiftAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get opsShiftAllDay;

  /// No description provided for @opsFeedStore.
  ///
  /// In en, this message translates to:
  /// **'Feeds store'**
  String get opsFeedStore;

  /// No description provided for @opsAddFeed.
  ///
  /// In en, this message translates to:
  /// **'Add feed'**
  String get opsAddFeed;

  /// No description provided for @opsEditFeed.
  ///
  /// In en, this message translates to:
  /// **'Edit feed'**
  String get opsEditFeed;

  /// No description provided for @opsBuyOrFeed.
  ///
  /// In en, this message translates to:
  /// **'Record buying or feeding'**
  String get opsBuyOrFeed;

  /// No description provided for @opsInStore.
  ///
  /// In en, this message translates to:
  /// **'In the store'**
  String get opsInStore;

  /// No description provided for @opsNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds yet'**
  String get opsNoFeeds;

  /// No description provided for @opsNoFeedsBody.
  ///
  /// In en, this message translates to:
  /// **'Add the feeds you use. FarmTap works out how long each one lasts.'**
  String get opsNoFeedsBody;

  /// No description provided for @opsNoUseYet.
  ///
  /// In en, this message translates to:
  /// **'No feeding recorded yet'**
  String get opsNoUseYet;

  /// No description provided for @opsLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get opsLow;

  /// No description provided for @opsLastsDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Runs out today} =1{Lasts about 1 day} other{Lasts about {days} days}}'**
  String opsLastsDays(int days);

  /// No description provided for @opsRunningLow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feed running low} other{{count} feeds running low}}'**
  String opsRunningLow(int count);

  /// No description provided for @opsCountStore.
  ///
  /// In en, this message translates to:
  /// **'Count the store'**
  String get opsCountStore;

  /// No description provided for @opsCountStoreSub.
  ///
  /// In en, this message translates to:
  /// **'Set what is really left'**
  String get opsCountStoreSub;

  /// No description provided for @opsHowMuchLeft.
  ///
  /// In en, this message translates to:
  /// **'How much is left ({unit})'**
  String opsHowMuchLeft(String unit);

  /// No description provided for @opsFeedName.
  ///
  /// In en, this message translates to:
  /// **'Feed name'**
  String get opsFeedName;

  /// No description provided for @opsFeedNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example dairy meal'**
  String get opsFeedNameHint;

  /// No description provided for @opsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get opsUnit;

  /// No description provided for @opsUnitHint.
  ///
  /// In en, this message translates to:
  /// **'kg, bags or bales'**
  String get opsUnitHint;

  /// No description provided for @opsLowAt.
  ///
  /// In en, this message translates to:
  /// **'Warn me when below (optional)'**
  String get opsLowAt;

  /// No description provided for @opsVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get opsVaccinations;

  /// No description provided for @opsRecordVaccination.
  ///
  /// In en, this message translates to:
  /// **'Record vaccination'**
  String get opsRecordVaccination;

  /// No description provided for @opsNoVaccinations.
  ///
  /// In en, this message translates to:
  /// **'No vaccinations yet'**
  String get opsNoVaccinations;

  /// No description provided for @opsNoVaccinationsBody.
  ///
  /// In en, this message translates to:
  /// **'Record each vaccination and FarmTap reminds you when the next dose is due.'**
  String get opsNoVaccinationsBody;

  /// No description provided for @opsNextDoses.
  ///
  /// In en, this message translates to:
  /// **'Next doses'**
  String get opsNextDoses;

  /// No description provided for @opsGiven.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get opsGiven;

  /// No description provided for @opsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get opsOverdue;

  /// No description provided for @opsSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get opsSoon;

  /// No description provided for @opsVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get opsVaccine;

  /// No description provided for @opsWholeHerd.
  ///
  /// In en, this message translates to:
  /// **'Whole herd'**
  String get opsWholeHerd;

  /// No description provided for @opsWholeHerdNote.
  ///
  /// In en, this message translates to:
  /// **'Leave animals empty to record it for the whole herd.'**
  String get opsWholeHerdNote;

  /// No description provided for @opsGivenOn.
  ///
  /// In en, this message translates to:
  /// **'Given on'**
  String get opsGivenOn;

  /// No description provided for @opsNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next dose due (optional)'**
  String get opsNextDue;

  /// No description provided for @opsCostUgx.
  ///
  /// In en, this message translates to:
  /// **'Cost in UGX (optional)'**
  String get opsCostUgx;

  /// No description provided for @opsVet.
  ///
  /// In en, this message translates to:
  /// **'Vet (optional)'**
  String get opsVet;

  /// No description provided for @opsNoVet.
  ///
  /// In en, this message translates to:
  /// **'No vet'**
  String get opsNoVet;

  /// No description provided for @opsRemoveVaccination.
  ///
  /// In en, this message translates to:
  /// **'Remove this vaccination?'**
  String get opsRemoveVaccination;

  /// No description provided for @opsRemoveVaccinationBody.
  ///
  /// In en, this message translates to:
  /// **'Its cost is removed from your spending too.'**
  String get opsRemoveVaccinationBody;

  /// No description provided for @opsUgx.
  ///
  /// In en, this message translates to:
  /// **'UGX {amount}'**
  String opsUgx(int amount);

  /// No description provided for @opsAnimals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 animal} other{{count} animals}}'**
  String opsAnimals(int count);

  /// No description provided for @opsNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get opsNoDate;

  /// No description provided for @opsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get opsClear;

  /// No description provided for @opsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get opsRemove;

  /// No description provided for @opsViewOnly.
  ///
  /// In en, this message translates to:
  /// **'Only owners and managers can change this.'**
  String get opsViewOnly;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersSub.
  ///
  /// In en, this message translates to:
  /// **'Duties, vaccinations, calving and your plan'**
  String get remindersSub;

  /// No description provided for @remindersToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get remindersToday;

  /// No description provided for @remindersNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remind you of today'**
  String get remindersNone;

  /// No description provided for @remindersNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Duties, vaccinations, calving and plan reminders show here on the day.'**
  String get remindersNoneBody;

  /// No description provided for @remindersWhat.
  ///
  /// In en, this message translates to:
  /// **'Remind about'**
  String get remindersWhat;

  /// No description provided for @remindersDuties.
  ///
  /// In en, this message translates to:
  /// **'Duties for each worker'**
  String get remindersDuties;

  /// No description provided for @remindersVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations due'**
  String get remindersVaccinations;

  /// No description provided for @remindersCalving.
  ///
  /// In en, this message translates to:
  /// **'Calving, pregnancy checks and heat'**
  String get remindersCalving;

  /// No description provided for @remindersPlan.
  ///
  /// In en, this message translates to:
  /// **'Free trial and plan ending'**
  String get remindersPlan;

  /// No description provided for @remindersHow.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get remindersHow;

  /// No description provided for @remindersPush.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this phone'**
  String get remindersPush;

  /// No description provided for @remindersPushSub.
  ///
  /// In en, this message translates to:
  /// **'Shown once each day'**
  String get remindersPushSub;

  /// No description provided for @remindersWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp to workers'**
  String get remindersWhatsapp;

  /// No description provided for @remindersWhatsappSub.
  ///
  /// In en, this message translates to:
  /// **'Ready to send from this phone, free'**
  String get remindersWhatsappSub;

  /// No description provided for @remindersSms.
  ///
  /// In en, this message translates to:
  /// **'SMS to workers'**
  String get remindersSms;

  /// No description provided for @remindersSmsSub.
  ///
  /// In en, this message translates to:
  /// **'Sent from this phone at your normal SMS rate'**
  String get remindersSmsSub;

  /// No description provided for @remindersHour.
  ///
  /// In en, this message translates to:
  /// **'Remind at'**
  String get remindersHour;

  /// No description provided for @remindersFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Messages go from your own phone, so FarmTap charges nothing for them.'**
  String get remindersFreeNote;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan and payment'**
  String get subscriptionTitle;

  /// No description provided for @payChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get payChoosePlan;

  /// No description provided for @payPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month'**
  String payPerMonth(String amount);

  /// No description provided for @payHow.
  ///
  /// In en, this message translates to:
  /// **'How to pay'**
  String get payHow;

  /// No description provided for @payPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money number'**
  String get payPhone;

  /// No description provided for @payPhoneNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter an MTN or Airtel number, like 0772 123 456.'**
  String get payPhoneNeeded;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @payMobileNote.
  ///
  /// In en, this message translates to:
  /// **'A prompt comes to that phone. Enter your Mobile Money PIN to pay.'**
  String get payMobileNote;

  /// No description provided for @payCardNote.
  ///
  /// In en, this message translates to:
  /// **'A secure card page opens. Come back here when you have paid.'**
  String get payCardNote;

  /// No description provided for @payByHand.
  ///
  /// In en, this message translates to:
  /// **'Pay, then send us the transaction ID'**
  String get payByHand;

  /// No description provided for @payByHandAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String payByHandAmount(String amount);

  /// No description provided for @payAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get payAccountName;

  /// No description provided for @payCode.
  ///
  /// In en, this message translates to:
  /// **'Account or pay code'**
  String get payCode;

  /// No description provided for @payReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get payReference;

  /// No description provided for @payReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'From your payment message'**
  String get payReferenceHint;

  /// No description provided for @payReferenceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the transaction ID from your payment message.'**
  String get payReferenceNeeded;

  /// No description provided for @paySendDetails.
  ///
  /// In en, this message translates to:
  /// **'Send payment details'**
  String get paySendDetails;

  /// No description provided for @payWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment'**
  String get payWaiting;

  /// No description provided for @payWaitingPhone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone and enter your Mobile Money PIN. This page updates by itself.'**
  String get payWaitingPhone;

  /// No description provided for @payWaitingCard.
  ///
  /// In en, this message translates to:
  /// **'Finish paying on the card page. This page updates by itself.'**
  String get payWaitingCard;

  /// No description provided for @payCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get payCheckNow;

  /// No description provided for @payDone.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get payDone;

  /// No description provided for @payDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your farm is open and your receipt is below.'**
  String get payDoneBody;

  /// No description provided for @payClaimSent.
  ///
  /// In en, this message translates to:
  /// **'Payment details sent'**
  String get payClaimSent;

  /// No description provided for @payClaimSentBody.
  ///
  /// In en, this message translates to:
  /// **'FarmTap checks your payment and opens your farm, usually within a few hours.'**
  String get payClaimSentBody;

  /// No description provided for @payFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment not finished'**
  String get payFailed;

  /// No description provided for @payFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was taken. Try again, or pay another way.'**
  String get payFailedBody;

  /// No description provided for @payTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get payTryAgain;

  /// No description provided for @payNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The payment could not start. Check your internet and try again.'**
  String get payNotStarted;

  /// No description provided for @paySoon.
  ///
  /// In en, this message translates to:
  /// **'Paying in the app is coming soon'**
  String get paySoon;

  /// No description provided for @paySoonBody.
  ///
  /// In en, this message translates to:
  /// **'For now, WhatsApp or call FarmTap on {phone} to pay.'**
  String paySoonBody(String phone);

  /// No description provided for @payAskOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or a manager pays'**
  String get payAskOwner;

  /// No description provided for @payAskOwnerBody.
  ///
  /// In en, this message translates to:
  /// **'Ask them to pay for FarmTap. Recording starts again as soon as the payment is confirmed.'**
  String get payAskOwnerBody;

  /// No description provided for @payActive.
  ///
  /// In en, this message translates to:
  /// **'Your plan is active'**
  String get payActive;

  /// No description provided for @payPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until {date}'**
  String payPaidUntil(String date);

  /// No description provided for @payTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends on {date}'**
  String payTrialEnds(String date);

  /// No description provided for @payLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan and pay to record again. Your records are safe.'**
  String get payLockedBody;

  /// No description provided for @payReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts and invoices'**
  String get payReceipts;

  /// No description provided for @payNoReceipts.
  ///
  /// In en, this message translates to:
  /// **'Your receipts show here after each payment.'**
  String get payNoReceipts;

  /// No description provided for @payReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt (PDF)'**
  String get payReceipt;

  /// No description provided for @payInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice (PDF)'**
  String get payInvoice;

  /// No description provided for @payRefundNote.
  ///
  /// In en, this message translates to:
  /// **'Refund note (PDF)'**
  String get payRefundNote;

  /// No description provided for @payReceiptFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be made. Try again.'**
  String get payReceiptFailed;

  /// No description provided for @payHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help paying?'**
  String get payHelp;

  /// No description provided for @payHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello FarmTap, I want to pay for {farm}.'**
  String payHelpMessage(String farm);

  /// No description provided for @lockedTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended'**
  String get lockedTrialTitle;

  /// No description provided for @lockedPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your FarmTap plan has ended'**
  String get lockedPlanTitle;

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing can be added or changed on {farm} until it is paid for. Your records are safe and nothing is deleted.'**
  String lockedBody(String farm);

  /// No description provided for @lockedPay.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan and pay'**
  String get lockedPay;

  /// No description provided for @lockedView.
  ///
  /// In en, this message translates to:
  /// **'Look at my records'**
  String get lockedView;

  /// No description provided for @lockedOtherFarm.
  ///
  /// In en, this message translates to:
  /// **'Open another farm'**
  String get lockedOtherFarm;

  /// No description provided for @readOnlyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get readOnlyBannerTitle;

  /// No description provided for @readOnlyBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended. Pay to record again; anything saved now will not be kept.'**
  String get readOnlyBannerBody;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @profilePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Shown on your account on this phone and the web.'**
  String get profilePhotoBody;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteTitle;

  /// No description provided for @deleteSub.
  ///
  /// In en, this message translates to:
  /// **'Kept 90 days, then erased'**
  String get deleteSub;

  /// No description provided for @deleteWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'This closes your account'**
  String get deleteWarnTitle;

  /// No description provided for @deleteWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Read what happens before you go on.'**
  String get deleteWarnBody;

  /// No description provided for @deleteWhatHappens.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get deleteWhatHappens;

  /// No description provided for @deleteWhat1.
  ///
  /// In en, this message translates to:
  /// **'You are signed out on every phone and computer, and cannot sign in again.'**
  String get deleteWhat1;

  /// No description provided for @deleteWhat2.
  ///
  /// In en, this message translates to:
  /// **'Every farm you own closes with it: nobody can open or record on it.'**
  String get deleteWhat2;

  /// No description provided for @deleteWhat3.
  ///
  /// In en, this message translates to:
  /// **'Your workers and managers lose access to those farms.'**
  String get deleteWhat3;

  /// No description provided for @deleteWhat4.
  ///
  /// In en, this message translates to:
  /// **'Any time left on your plan is not refunded.'**
  String get deleteWhat4;

  /// No description provided for @deleteWhat5.
  ///
  /// In en, this message translates to:
  /// **'For 90 days FarmTap keeps everything, so support can bring it back if you change your mind.'**
  String get deleteWhat5;

  /// No description provided for @deleteWhat6.
  ///
  /// In en, this message translates to:
  /// **'After 90 days your account, farms and records are erased for good.'**
  String get deleteWhat6;

  /// No description provided for @deleteInstead.
  ///
  /// In en, this message translates to:
  /// **'Only want to stop paying? You do not need to delete anything: the farm turns read-only and your records stay safe.'**
  String get deleteInstead;

  /// No description provided for @deleteContinue.
  ///
  /// In en, this message translates to:
  /// **'I still want to delete'**
  String get deleteContinue;

  /// No description provided for @deleteUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand my farms close and are erased after 90 days'**
  String get deleteUnderstand;

  /// No description provided for @deleteTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteTypeLabel;

  /// No description provided for @deleteTypeNeeded.
  ///
  /// In en, this message translates to:
  /// **'Type the word DELETE.'**
  String get deleteTypeNeeded;

  /// No description provided for @deleteReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving? (optional)'**
  String get deleteReason;

  /// No description provided for @deleteNow.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteNow;

  /// No description provided for @deleteKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get deleteKeep;

  /// No description provided for @deleteLastTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account now?'**
  String get deleteLastTitle;

  /// No description provided for @deleteLastBody.
  ///
  /// In en, this message translates to:
  /// **'You are signed out straight away. Support can restore it within 90 days.'**
  String get deleteLastBody;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account was not deleted. Check your internet and try again.'**
  String get deleteFailed;

  /// No description provided for @closedTitle.
  ///
  /// In en, this message translates to:
  /// **'This account is closed'**
  String get closedTitle;

  /// No description provided for @closedBody.
  ///
  /// In en, this message translates to:
  /// **'It can be brought back until {date}. After that it is erased for good.'**
  String closedBody(String date);

  /// No description provided for @closedBodySoon.
  ///
  /// In en, this message translates to:
  /// **'It can be brought back for 90 days. After that it is erased for good.'**
  String get closedBodySoon;

  /// No description provided for @closedRestore.
  ///
  /// In en, this message translates to:
  /// **'Ask FarmTap to bring it back'**
  String get closedRestore;

  /// No description provided for @closedRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello FarmTap, I closed my account and want it back.'**
  String get closedRestoreMessage;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Intelligence'**
  String get aiTitle;

  /// No description provided for @aiIntro.
  ///
  /// In en, this message translates to:
  /// **'Your farm records, read for you. Every answer says how it was made.'**
  String get aiIntro;

  /// No description provided for @aiTodaysInsights.
  ///
  /// In en, this message translates to:
  /// **'Today\'s insights'**
  String get aiTodaysInsights;

  /// No description provided for @aiTools.
  ///
  /// In en, this message translates to:
  /// **'AI tools'**
  String get aiTools;

  /// No description provided for @aiNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention'**
  String get aiNothing;

  /// No description provided for @aiNothingBody.
  ///
  /// In en, this message translates to:
  /// **'FarmTap found nothing to warn you about from your records today.'**
  String get aiNothingBody;

  /// No description provided for @aiSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get aiSeen;

  /// No description provided for @aiMarkSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen'**
  String get aiMarkSeen;

  /// No description provided for @aiMarkFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark as fixed'**
  String get aiMarkFixed;

  /// No description provided for @aiFindings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get aiFindings;

  /// No description provided for @aiToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get aiToday;

  /// No description provided for @aiYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get aiYesterday;

  /// No description provided for @aiAvg7.
  ///
  /// In en, this message translates to:
  /// **'7-day average'**
  String get aiAvg7;

  /// No description provided for @aiNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get aiNotRecorded;

  /// No description provided for @aiBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the milk went'**
  String get aiBalanceTitle;

  /// No description provided for @aiProduced.
  ///
  /// In en, this message translates to:
  /// **'Produced'**
  String get aiProduced;

  /// No description provided for @aiSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get aiSold;

  /// No description provided for @aiHomeUse.
  ///
  /// In en, this message translates to:
  /// **'Used at home'**
  String get aiHomeUse;

  /// No description provided for @aiThrownAway.
  ///
  /// In en, this message translates to:
  /// **'Thrown away'**
  String get aiThrownAway;

  /// No description provided for @aiNotAccounted.
  ///
  /// In en, this message translates to:
  /// **'Not accounted for'**
  String get aiNotAccounted;

  /// No description provided for @aiNoSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales recorded yet'**
  String get aiNoSalesYet;

  /// No description provided for @aiCowsDropping.
  ///
  /// In en, this message translates to:
  /// **'Cows giving less milk'**
  String get aiCowsDropping;

  /// No description provided for @aiNoForecast.
  ///
  /// In en, this message translates to:
  /// **'No forecast yet'**
  String get aiNoForecast;

  /// No description provided for @aiForecastNeeds.
  ///
  /// In en, this message translates to:
  /// **'A forecast needs about two weeks of milk records.'**
  String get aiForecastNeeds;

  /// No description provided for @aiNext7.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get aiNext7;

  /// No description provided for @aiNext30.
  ///
  /// In en, this message translates to:
  /// **'Next 30 days'**
  String get aiNext30;

  /// No description provided for @aiNextDays.
  ///
  /// In en, this message translates to:
  /// **'Coming days'**
  String get aiNextDays;

  /// No description provided for @aiPerCow.
  ///
  /// In en, this message translates to:
  /// **'Per cow'**
  String get aiPerCow;

  /// No description provided for @aiForecastNote.
  ///
  /// In en, this message translates to:
  /// **'A forecast is an estimate from your past records. Disease, weather and feed can change it.'**
  String get aiForecastNote;

  /// No description provided for @aiNoUseYet.
  ///
  /// In en, this message translates to:
  /// **'No use recorded yet'**
  String get aiNoUseYet;

  /// No description provided for @aiNoFeed.
  ///
  /// In en, this message translates to:
  /// **'No feeds yet'**
  String get aiNoFeed;

  /// No description provided for @aiNoFeedBody.
  ///
  /// In en, this message translates to:
  /// **'Add feeds and record what you use, and FarmTap will tell you when they run out.'**
  String get aiNoFeedBody;

  /// No description provided for @aiFeedInStore.
  ///
  /// In en, this message translates to:
  /// **'Feed in the store'**
  String get aiFeedInStore;

  /// No description provided for @aiCostPerLitre.
  ///
  /// In en, this message translates to:
  /// **'Cost per litre'**
  String get aiCostPerLitre;

  /// No description provided for @aiLitresPer1000.
  ///
  /// In en, this message translates to:
  /// **'Litres per 1,000 of feed spend'**
  String get aiLitresPer1000;

  /// No description provided for @aiDrugStock.
  ///
  /// In en, this message translates to:
  /// **'Drugs and supplies'**
  String get aiDrugStock;

  /// No description provided for @aiNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted yet'**
  String get aiNotCounted;

  /// No description provided for @aiInCalf.
  ///
  /// In en, this message translates to:
  /// **'In calf'**
  String get aiInCalf;

  /// No description provided for @aiOpenCows.
  ///
  /// In en, this message translates to:
  /// **'Open cows'**
  String get aiOpenCows;

  /// No description provided for @aiCalvingInterval.
  ///
  /// In en, this message translates to:
  /// **'Calving interval'**
  String get aiCalvingInterval;

  /// No description provided for @aiServedOrInCalf.
  ///
  /// In en, this message translates to:
  /// **'Served or in calf'**
  String get aiServedOrInCalf;

  /// No description provided for @aiConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get aiConfirmed;

  /// No description provided for @aiNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get aiNotConfirmed;

  /// No description provided for @aiNoHeatRecorded.
  ///
  /// In en, this message translates to:
  /// **'No heat recorded'**
  String get aiNoHeatRecorded;

  /// No description provided for @aiBreedingNote.
  ///
  /// In en, this message translates to:
  /// **'Dates come from your breeding records. A vet check confirms pregnancy.'**
  String get aiBreedingNote;

  /// No description provided for @aiNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get aiNeedAttention;

  /// No description provided for @aiInWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'In withdrawal'**
  String get aiInWithdrawal;

  /// No description provided for @aiVaccinesDue.
  ///
  /// In en, this message translates to:
  /// **'Vaccines due'**
  String get aiVaccinesDue;

  /// No description provided for @aiLastMonths.
  ///
  /// In en, this message translates to:
  /// **'Last months'**
  String get aiLastMonths;

  /// No description provided for @aiIncomeShort.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get aiIncomeShort;

  /// No description provided for @aiSpentShort.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get aiSpentShort;

  /// No description provided for @aiNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get aiNet;

  /// No description provided for @aiLargeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Unusually large expenses'**
  String get aiLargeExpenses;

  /// No description provided for @aiNoRisks.
  ///
  /// In en, this message translates to:
  /// **'No risks found'**
  String get aiNoRisks;

  /// No description provided for @aiFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get aiFilterAll;

  /// No description provided for @aiFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get aiFilterNew;

  /// No description provided for @aiUseByNote.
  ///
  /// In en, this message translates to:
  /// **'Use-by times follow the farm rule below. Your buyer decides what they accept.'**
  String get aiUseByNote;

  /// No description provided for @aiAddBatch.
  ///
  /// In en, this message translates to:
  /// **'Add a batch'**
  String get aiAddBatch;

  /// No description provided for @aiNoBatches.
  ///
  /// In en, this message translates to:
  /// **'No batches yet'**
  String get aiNoBatches;

  /// No description provided for @aiNoBatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Add the milk you keep on the farm to watch how long it stays good.'**
  String get aiNoBatchesBody;

  /// No description provided for @aiInStorage.
  ///
  /// In en, this message translates to:
  /// **'In storage'**
  String get aiInStorage;

  /// No description provided for @aiClosedBatches.
  ///
  /// In en, this message translates to:
  /// **'Finished batches'**
  String get aiClosedBatches;

  /// No description provided for @aiExpired.
  ///
  /// In en, this message translates to:
  /// **'Past use-by'**
  String get aiExpired;

  /// No description provided for @aiUseSoon.
  ///
  /// In en, this message translates to:
  /// **'Use soon'**
  String get aiUseSoon;

  /// No description provided for @aiFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get aiFresh;

  /// No description provided for @aiNoReading.
  ///
  /// In en, this message translates to:
  /// **'No temperature yet'**
  String get aiNoReading;

  /// No description provided for @aiRecordTemp.
  ///
  /// In en, this message translates to:
  /// **'Record temperature'**
  String get aiRecordTemp;

  /// No description provided for @aiMarkSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get aiMarkSold;

  /// No description provided for @aiMarkUsed.
  ///
  /// In en, this message translates to:
  /// **'Mark as used'**
  String get aiMarkUsed;

  /// No description provided for @aiMarkDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Mark as thrown away'**
  String get aiMarkDiscarded;

  /// No description provided for @aiLitresNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the litres'**
  String get aiLitresNeeded;

  /// No description provided for @aiLitres.
  ///
  /// In en, this message translates to:
  /// **'Litres'**
  String get aiLitres;

  /// No description provided for @aiPlaceOptional.
  ///
  /// In en, this message translates to:
  /// **'Where it is kept (optional)'**
  String get aiPlaceOptional;

  /// No description provided for @aiPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Cooler 1, Can A'**
  String get aiPlaceHint;

  /// No description provided for @aiCooledQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is it in a cooler or cooling tank?'**
  String get aiCooledQuestion;

  /// No description provided for @aiTempNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the temperature'**
  String get aiTempNeeded;

  /// No description provided for @aiTempC.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get aiTempC;

  /// No description provided for @aiRuleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the numbers in the rule'**
  String get aiRuleInvalid;

  /// No description provided for @aiRuleNote.
  ///
  /// In en, this message translates to:
  /// **'These are starting rules. Check them with your buyer or the Dairy Development Authority.'**
  String get aiRuleNote;

  /// No description provided for @aiCooledHours.
  ///
  /// In en, this message translates to:
  /// **'Hours it keeps when cooled'**
  String get aiCooledHours;

  /// No description provided for @aiWarmHours.
  ///
  /// In en, this message translates to:
  /// **'Hours it keeps when warm'**
  String get aiWarmHours;

  /// No description provided for @aiMaxTemp.
  ///
  /// In en, this message translates to:
  /// **'Warmest safe temperature (°C)'**
  String get aiMaxTemp;

  /// No description provided for @aiAssistantNote.
  ///
  /// In en, this message translates to:
  /// **'Answers come from your own records and are worked out on your phone.'**
  String get aiAssistantNote;

  /// No description provided for @aiAskLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask about your farm'**
  String get aiAskLabel;

  /// No description provided for @aiAskHint.
  ///
  /// In en, this message translates to:
  /// **'How much milk did we get this week?'**
  String get aiAskHint;

  /// No description provided for @aiAskButton.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get aiAskButton;

  /// No description provided for @aiTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get aiTryAsking;

  /// No description provided for @aiWhichAnimal.
  ///
  /// In en, this message translates to:
  /// **'Which animal?'**
  String get aiWhichAnimal;

  /// No description provided for @aiChooseAnimal.
  ///
  /// In en, this message translates to:
  /// **'Choose an animal'**
  String get aiChooseAnimal;

  /// No description provided for @aiTempOptional.
  ///
  /// In en, this message translates to:
  /// **'Temperature (optional)'**
  String get aiTempOptional;

  /// No description provided for @aiTempHelp.
  ///
  /// In en, this message translates to:
  /// **'Normal for a cow is about 38 to 39.'**
  String get aiTempHelp;

  /// No description provided for @aiDaysSeen.
  ///
  /// In en, this message translates to:
  /// **'Days she has been unwell'**
  String get aiDaysSeen;

  /// No description provided for @aiCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get aiCheckNow;

  /// No description provided for @aiNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get aiNoteOptional;

  /// No description provided for @aiSavedToHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to her health history'**
  String get aiSavedToHistory;

  /// No description provided for @aiChooseAnimalToSave.
  ///
  /// In en, this message translates to:
  /// **'Choose an animal to save this check'**
  String get aiChooseAnimalToSave;

  /// No description provided for @aiSaveToHistory.
  ///
  /// In en, this message translates to:
  /// **'Save to health history'**
  String get aiSaveToHistory;

  /// No description provided for @aiCallVetNow.
  ///
  /// In en, this message translates to:
  /// **'Call the vet now'**
  String get aiCallVetNow;

  /// No description provided for @aiCallVetToday.
  ///
  /// In en, this message translates to:
  /// **'Call the vet today'**
  String get aiCallVetToday;

  /// No description provided for @aiCallVetSoon.
  ///
  /// In en, this message translates to:
  /// **'Call the vet soon'**
  String get aiCallVetSoon;

  /// No description provided for @aiWarningSigns.
  ///
  /// In en, this message translates to:
  /// **'Warning signs'**
  String get aiWarningSigns;

  /// No description provided for @aiPossibleCauses.
  ///
  /// In en, this message translates to:
  /// **'Possible causes'**
  String get aiPossibleCauses;

  /// No description provided for @aiMustReport.
  ///
  /// In en, this message translates to:
  /// **'Report this to the authorities'**
  String get aiMustReport;

  /// No description provided for @aiWhatToDoNow.
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get aiWhatToDoNow;

  /// No description provided for @aiScreeningNote.
  ///
  /// In en, this message translates to:
  /// **'Disease screening from photos is experimental and cannot replace a vet.'**
  String get aiScreeningNote;

  /// No description provided for @aiPhotoCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check a photo'**
  String get aiPhotoCheckTitle;

  /// No description provided for @aiPhotoCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Check that a photo is clear enough before you send it to a vet.'**
  String get aiPhotoCheckBody;

  /// No description provided for @aiPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'This photo is not clear enough'**
  String get aiPhotoFailed;

  /// No description provided for @aiPhotoGood.
  ///
  /// In en, this message translates to:
  /// **'This photo is clear enough'**
  String get aiPhotoGood;

  /// No description provided for @aiPhotoRetake.
  ///
  /// In en, this message translates to:
  /// **'Take it again in good light, closer and steady.'**
  String get aiPhotoRetake;

  /// No description provided for @aiScreeningTargets.
  ///
  /// In en, this message translates to:
  /// **'What screening will look for'**
  String get aiScreeningTargets;

  /// No description provided for @aiNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model yet'**
  String get aiNoModel;

  /// No description provided for @aiScreeningPromise.
  ///
  /// In en, this message translates to:
  /// **'FarmTap will not guess from a photo until a tested model is added.'**
  String get aiScreeningPromise;

  /// No description provided for @aiReportAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask for a report'**
  String get aiReportAsk;

  /// No description provided for @aiReportAskHint.
  ///
  /// In en, this message translates to:
  /// **'Milk report for last month'**
  String get aiReportAskHint;

  /// No description provided for @aiReportNotFound.
  ///
  /// In en, this message translates to:
  /// **'FarmTap could not tell which report you want. Choose one below.'**
  String get aiReportNotFound;

  /// No description provided for @aiReportKind.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get aiReportKind;

  /// No description provided for @aiReportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get aiReportPeriod;

  /// No description provided for @aiShowReport.
  ///
  /// In en, this message translates to:
  /// **'Show report'**
  String get aiShowReport;

  /// No description provided for @aiReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show for this period'**
  String get aiReportEmpty;

  /// No description provided for @aiExportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get aiExportReport;

  /// No description provided for @aiPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get aiPeriodLastMonth;

  /// No description provided for @aiPeriod7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get aiPeriod7;

  /// No description provided for @aiPeriod30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get aiPeriod30;

  /// No description provided for @aiPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get aiPeriodThisMonth;

  /// No description provided for @aiSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String aiSeeAll(int count);

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'{level} confidence'**
  String aiConfidence(String level);

  /// No description provided for @aiMadeFromDays.
  ///
  /// In en, this message translates to:
  /// **'Made from {count} days of records'**
  String aiMadeFromDays(int count);

  /// No description provided for @aiDaysAtRate.
  ///
  /// In en, this message translates to:
  /// **'{days} days left at {perDay} {unit} a day'**
  String aiDaysAtRate(int days, String perDay, String unit);

  /// No description provided for @aiReorderAt.
  ///
  /// In en, this message translates to:
  /// **'Reorder at {level}'**
  String aiReorderAt(String level);

  /// No description provided for @aiDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String aiDaysShort(int count);

  /// No description provided for @aiDueAbout.
  ///
  /// In en, this message translates to:
  /// **'Due about {date}'**
  String aiDueAbout(String date);

  /// No description provided for @aiNextHeatAbout.
  ///
  /// In en, this message translates to:
  /// **'Next heat about {date}'**
  String aiNextHeatAbout(String date);

  /// No description provided for @aiSafeFrom.
  ///
  /// In en, this message translates to:
  /// **'Safe from {date}'**
  String aiSafeFrom(String date);

  /// No description provided for @aiOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String aiOverdueDays(int count);

  /// No description provided for @aiDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String aiDueOn(String date);

  /// No description provided for @aiNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Estimate for {month}'**
  String aiNextMonth(String month);

  /// No description provided for @aiUsually.
  ///
  /// In en, this message translates to:
  /// **'usually {amount}'**
  String aiUsually(String amount);

  /// No description provided for @aiShelfRule.
  ///
  /// In en, this message translates to:
  /// **'Keeps {cooledHours} hours at {maxTemp} °C or colder, {warmHours} hours when warm'**
  String aiShelfRule(String cooledHours, String maxTemp, String warmHours);

  /// No description provided for @aiUseBy.
  ///
  /// In en, this message translates to:
  /// **'Use by {time}'**
  String aiUseBy(String time);

  /// No description provided for @aiPhotoNumbers.
  ///
  /// In en, this message translates to:
  /// **'Light {brightness}, contrast {contrast}, sharpness {sharpness}'**
  String aiPhotoNumbers(int brightness, int contrast, int sharpness);
}
