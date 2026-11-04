# App Store: App Privacy answers

App Store Connect > App Privacy > Get started. "Do you or your third-party
partners collect data from this app?" **Yes.** FarmTap does **not** track
users (no ads, no data brokers).

For each type below choose: **Used for App Functionality**, **Linked to the
user**, **Not used for tracking** (except where noted).

| Category | Type | Linked | Purpose |
| --- | --- | --- | --- |
| Contact Info | Name | Yes | App Functionality |
| Contact Info | Email Address | Yes | App Functionality |
| Contact Info | Phone Number | Yes | App Functionality |
| Financial Info | Other Financial Info (farm sales, spending, wages) | Yes | App Functionality |
| Purchases | Purchase History (FarmTap plan) | Yes | App Functionality |
| Location | Coarse Location | Yes | App Functionality |
| User Content | Photos or Videos | Yes | App Functionality |
| User Content | Other User Content (farm records) | Yes | App Functionality |
| Identifiers | Device ID (push token) | Yes | App Functionality |
| Usage Data | Product Interaction | No | Analytics |
| Diagnostics | Crash Data | No | App Functionality |

Privacy policy URL: https://farmtap.victorbee.com/privacy/
Account deletion: in the app (Settings > Delete my account), as Apple
requires for apps with sign-up.

## Privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy` lists the same data and the required
reason APIs (UserDefaults CA92.1, file timestamps C617.1). **(Victor, once)**
In Xcode: File > Add Files to "Runner", pick `PrivacyInfo.xcprivacy`, tick
the Runner target. Firebase and the other plugins ship their own manifests.

## Export compliance

`ITSAppUsesNonExemptEncryption` is `false` in Info.plist (FarmTap only uses
standard HTTPS), so App Store Connect does not ask each build.
