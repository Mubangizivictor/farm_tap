# FarmTap store pack (Google Play and Apple App Store)

Everything needed to publish the FarmTap phone app (decision 0024). The
steps only Victor can do are marked **(Victor)**.

| File | What it is |
| --- | --- |
| [LISTING.md](LISTING.md) | App name, short and full description, keywords, category, contact, URLs |
| [PLAY_DATA_SAFETY.md](PLAY_DATA_SAFETY.md) | Answers for Play Console > App content > Data safety |
| [APPLE_PRIVACY.md](APPLE_PRIVACY.md) | Answers for App Store Connect > App Privacy (and the privacy manifest) |
| [ANDROID_SIGNING.md](ANDROID_SIGNING.md) | Making the upload key and building the signed app bundle |
| [IOS_RELEASE.md](IOS_RELEASE.md) | Bundle id, signing, push notifications, building for the App Store |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Every step, in order, for each release |
| `screenshots/` | Ready store screenshots (Play phone 1080x1920, iPhone 6.9" 1320x2868, iPad 13" 2064x2752) |
| `graphics/` | Play icon 512, Play feature graphic 1024x500, App Store icon 1024 |

## Screenshots

Made from the real app screens with sample farm data:

```
STORE_SHOTS=1 flutter test --update-goldens test/store   # raw screens
python3 tool/store_frames.py                             # caption + frame
```

The six screens: home, milk, herd, duty roster, feeds store, plan and
payment. Captions are in `tool/store_frames.py`. Upload them in that order.

## Links the stores ask for

- Privacy policy: https://farmtap.victorbee.com/privacy/
- Terms of use: https://farmtap.victorbee.com/terms/
- Delete account (Google requires a web link): https://farmtap.victorbee.com/delete-account/
- Support: https://farmtap.victorbee.com/ and WhatsApp/phone +256 793 128 137
- In the app: More > Settings > Legal (privacy, terms, Delete my account)

## Version

`pubspec.yaml` is `1.0.0+1` for the first release. Raise the number after
the `+` for every upload (Play and Apple both refuse a number used before);
raise `1.0.0` when users should see a new version.
