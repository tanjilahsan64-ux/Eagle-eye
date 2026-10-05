# Field Tracker — Flutter/Firebase starter

A field-tracking application with:

- Main Admin / Co-Admin / Field Agent roles
- Team tagging
- Firestore-backed live positions
- Interactive OpenStreetMap map
- 5-minute stop detection
- Android foreground notification
- iOS CoreLocation background mode
- Battery-conscious 15-second Android updates + 20m distance filter
- Firestore security rules

## 1. Create the Flutter project

This repository is intended to be placed over a fresh Flutter project. Run:

```bash
flutter create field_tracker
cd field_tracker
```

Copy the `lib/`, `pubspec.yaml`, and `firestore.rules` files from this repository into it.

## 2. Firebase

Install FlutterFire CLI and configure the project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
```

This generates `lib/firebase_options.dart` for your Firebase project.

Enable Firebase Authentication > Email/Password and Cloud Firestore.

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

## 3. Create users

Create accounts in Firebase Authentication, then create matching `/users/{uid}` documents.

Example:

```json
{
  "name": "Alice Agent",
  "email": "alice@example.com",
  "role": "fieldAgent",
  "teamIds": ["team-a"],
  "trackingEnabled": true
}
```

Roles are exactly `mainAdmin`, `coAdmin`, or `fieldAgent`.

For an admin:

```json
{
  "name": "Operations Admin",
  "email": "admin@example.com",
  "role": "mainAdmin",
  "teamIds": [],
  "trackingEnabled": false
}
```

## 4. Android permissions

Merge the supplied `android/app/src/main/AndroidManifest.xml` additions into your generated manifest. Android 10+ requires background location permission for continued background access, and Android 14+ requires the location foreground-service permission. Approximate location also applies to background access. See Android's current guidance and the geolocator permission notes. 

## 5. iOS

Merge the supplied Info.plist entries and enable the **Location Updates** Background Mode capability in Xcode. Apple may require a detailed justification for continuous background location.

## 6. Stop detection

The algorithm uses:

- 50m stationary radius
- <= 2 m/s speed
- <= 100m accuracy when available
- 5 continuous minutes before creating/updating a stop

A stop is written under:

`users/{uid}/stops/{stopId}`

and the live marker becomes `stopped`.

## 7. Production notes

1. Do not put Firebase service-account credentials in the Flutter app.
2. Do not ship with Firestore test-mode rules.
3. Obtain explicit employee/user consent for location tracking and provide an understandable privacy notice.
4. On Android, instruct users not to restrict the app's battery/background activity if reliable tracking is required. Device manufacturers may still terminate background work.
5. iOS can suspend/terminate apps and controls background execution; no app can guarantee uninterrupted GPS collection.
6. For high-volume deployments, write raw location events to a time-series/BigQuery pipeline rather than indefinitely storing every point in Firestore.
7. OpenStreetMap's public tile server is suitable for development/light use; use an appropriate commercial/self-hosted tile provider for production traffic and follow its attribution/usage policy.
