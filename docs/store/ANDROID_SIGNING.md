# Android: signed release build

Google Play needs an app bundle signed with your **upload key**. Google
keeps the real app signing key (Play App Signing). Do this once **(Victor)**.

## 1. Make the upload key (once, on your Mac)

```
keytool -genkey -v -keystore ~/farmtap-upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Choose a strong password and write it down with the file somewhere safe
(password manager + a USB stick). If it is lost, Google can reset the upload
key, but it takes days.

## 2. Tell the build where it is

Create `android/key.properties` (never committed; `.gitignore` covers it):

```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=/Users/victor/farmtap-upload.jks
```

`android/app/build.gradle.kts` reads it. Without the file, release builds use
the debug key (fine for testing, refused by Play).

## 3. Build

```
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console >
Test and release > Production (or Internal testing first).

## 4. After the first upload

Play Console > Test and release > App integrity > App signing: copy the
**SHA-1** and **SHA-256** of the *app signing key* and add both in the
Firebase console (Project settings > Your apps > Android app > Add
fingerprint), then download the new `google-services.json` into
`android/app/`. Google sign-in on phones installed from Play needs this.

The app id is `com.victorbee.farm_tap` and can never change after the first upload.
