# Release checklist

Tick each line for every release. **(Victor)** = only Victor can do it.

## Before building

- [ ] All tests green: `flutter test --exclude-tags golden`, `cd webapp && npm test && npm run build`, `cd functions && npm test`, rules tests
- [ ] Goldens regenerated on the Mac and checked: `flutter test --update-goldens test/goldens` **(Victor)**
- [ ] Version raised in `pubspec.yaml` (build number always +1)
- [ ] Prices, plans and payment methods set in Admin > Plans and Admin > Payments **(Victor)**
- [ ] Privacy policy and terms published in Admin > Legal documents (effective date right) **(Victor)**
- [ ] Logo, stamp and signature uploaded in Admin > Brand and documents **(Victor)**
- [ ] Reviewer demo account works on the phone and web **(Victor)**

## Google Play

- [ ] Upload key and `android/key.properties` in place (ANDROID_SIGNING.md) **(Victor)**
- [ ] `flutter build appbundle --release`
- [ ] Internal testing track: install on 2 phones (one old Android), sign in, record milk offline, sync, pay screen opens, reminders show
- [ ] Store listing, graphics, screenshots (LISTING.md, `graphics/`, `screenshots/play_phone`)
- [ ] Data safety (PLAY_DATA_SAFETY.md), content rating questionnaire, target audience 18+, ads: none, account deletion URL
- [ ] App signing SHA-1/SHA-256 added to Firebase after first upload **(Victor)**
- [ ] Promote to Production, roll out 20% then 100%

## Apple App Store

- [ ] Developer account, App ID capabilities, APNs key in Firebase (IOS_RELEASE.md) **(Victor)**
- [ ] `PrivacyInfo.xcprivacy` added to the Runner target in Xcode (once) **(Victor)**
- [ ] `flutter build ipa --release`, upload, TestFlight on an iPhone: sign in with Apple and Google, NFC card read, camera, notifications
- [ ] Listing, screenshots (`apple_6_9`, `apple_ipad_13`), App Privacy (APPLE_PRIVACY.md), reviewer login, notes about payments (LISTING.md)
- [ ] Submit for review

## After release

- [ ] Website shows the store badges/links (Admin > Website) **(Victor)**
- [ ] Watch Crashlytics and support WhatsApp for 48 hours
