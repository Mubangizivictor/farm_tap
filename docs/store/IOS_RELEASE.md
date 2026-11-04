# iOS: App Store release

Needs a Mac with Xcode and an Apple Developer account (USD 99 a year) **(Victor)**.

- Bundle id: `com.victorbee.farmTap`
- Team: your Apple Developer team (Xcode > Runner > Signing & Capabilities > Team)
- Version: from `pubspec.yaml` (1.0.0, build 1)

## Capabilities (Xcode > Runner > Signing & Capabilities)

Already in `Runner.entitlements`; Xcode asks to enable them for the App ID:

- Sign in with Apple
- Near Field Communication Tag Reading (staff and farmer cards)
- Push Notifications (`aps-environment`; reminders)
- Background Modes > Remote notifications (in Info.plist)

## Push notifications (once)

1. developer.apple.com > Keys > + > tick **Apple Push Notifications service
   (APNs)** > download the `.p8` key (only downloadable once), note the Key
   ID and your Team ID.
2. Firebase console > Project settings > Cloud Messaging > Apple app
   configuration > upload the `.p8` with Key ID and Team ID.

Without this the app still shows its own reminders; only server pushes wait.

## Build and upload

```
flutter build ipa --release
```

Open `build/ios/archive/Runner.xcarchive` in Xcode Organizer > Distribute
App > App Store Connect > Upload (or use the Transporter app with
`build/ios/ipa/*.ipa`).

## App Store Connect

1. My Apps > + > New App: name FarmTap, bundle id above, SKU `farmtap-ios`.
2. Paste the listing (LISTING.md), screenshots (`screenshots/apple_6_9`,
   `screenshots/apple_ipad_13`), App Privacy (APPLE_PRIVACY.md), the
   reviewer login, support URL and privacy URL.
3. Pick the uploaded build, then Submit for Review.
