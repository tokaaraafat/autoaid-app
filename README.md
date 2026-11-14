# AutoAid - Roadside Assistance App

A Flutter app that connects drivers whose car broke down with nearby roadside-assistance providers. Built with **Flutter / Dart**, **Firebase** (Authentication + Cloud Firestore) and **OpenStreetMap** (via `flutter_map`).

Based on the AutoAid graduation project design (Sadat Academy, Faculty of Computers and Information Systems, 2023-2024): use cases, class diagram and ERD.

## Features

**Customer**
- Register / log in, manage profile
- Save vehicles (model, plate, insurance, registration)
- Request assistance: towing, flat tire, battery jump-start, fuel delivery, lockout, engine problem
- Pick the location from GPS or by tapping the OpenStreetMap map
- Live tracking of the provider on the map, with distance and ETA
- In-app chat and one-tap call to the provider
- Cancel a request while it is not completed
- Pay (cash, or simulated wallet/Visa) and rate the provider
- **Accident / emergency**: emergency numbers (one-tap call) and an accident report that is sent to providers

**Service provider**
- Register, then wait for admin verification
- Available / offline switch
- See open requests within 50 km, nearest first; first provider to accept wins (Firestore transaction)
- Update the job status (on my way, arrived, completed); live GPS is shared with the customer while the job is active
- Chat with and call the customer
- Rating average updates after each review

**Administrator**
- Verify provider accounts

## How it maps to the design documents

| Design | In the app |
|---|---|
| AutoAidUser, ServiceProvider | `users` collection (`role` = customer / provider / admin) |
| Vehicle | `users/{uid}/vehicles` |
| AssistanceRequest | `requests` collection (`status`: pending, accepted, onTheWay, arrived, completed, cancelled) |
| Communication | `requests/{id}/messages` |
| Payment | `paid` and `paymentMethod` fields on the request |
| AutoAid Transactions (services, price) | `serviceTypes` in `lib/core/constants.dart` |
| EmergencyServices | `emergencyNumbers` in `lib/core/constants.dart` |

## Project structure

```
lib/
├── main.dart                    # Firebase init, providers, AuthGate (routes by role)
├── firebase_options.dart        # placeholder, replaced by `flutterfire configure`
├── core/                        # constants, models, helpers
├── services/
│   ├── app_state.dart           # auth + signed-in profile
│   ├── firestore_service.dart   # all Firestore access
│   └── location_service.dart    # GPS, distance, ETA
├── widgets/osm_map.dart         # OpenStreetMap widget
└── screens/
    ├── auth/  customer/  provider/  admin/  shared/
firestore.rules                  # security rules
test/                            # unit tests
```

## Setup

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and a free [Firebase](https://console.firebase.google.com) project.

### 1. Generate the platform folders

This repo contains the Dart code only. Generate `android/` and `ios/`:

```bash
flutter create . --platforms=android,ios --project-name autoaid --org com.yourname
rm test/widget_test.dart      # default test created by flutter create
flutter pub get
```

### 2. Create the Firebase project

In the Firebase console:
1. Create a project.
2. **Authentication** -> Sign-in method -> enable **Email/Password**.
3. **Firestore Database** -> Create database.
4. Open the **Rules** tab and paste the contents of `firestore.rules`, then publish.

Then connect the app:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This overwrites `lib/firebase_options.dart` with your project's settings.

### 3. Platform permissions

**Android** - `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` and above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<queries>
  <intent>
    <action android:name="android.intent.action.DIAL"/>
    <data android:scheme="tel"/>
  </intent>
</queries>
```

Firebase also needs `minSdk` 23 or higher: in `android/app/build.gradle(.kts)` set `minSdk = 23` (or `minSdkVersion 23`).

**iOS** - `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AutoAid needs your location to send help to you.</string>
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string></array>
```

### 4. Run

```bash
flutter run
```

Run the unit tests with `flutter test`.

## Trying it out

1. Create a **customer** account on one device or emulator.
2. Create a **provider** account on another.
3. Create an **admin**: sign up with any account, then in the Firestore console open `users/<that user's id>` and change the `role` field to `admin`. Log in with it and verify the provider.
4. As the customer, request assistance. As the provider, switch to Available, open the request, accept it, and tap "I'm on my way". The customer sees the provider moving on the map.

On emulators, set a fake location from the emulator's extended controls (Android) or Features -> Location (iOS simulator).

## Known limitations

- **Dispatch is client-side.** Providers see nearby requests and the first to accept wins. A production system would use Cloud Functions to choose the nearest provider and send push notifications (not included).
- **Payments are simulated.** Cash or "wallet/Visa" only records the choice; there is no payment gateway.
- **Rating updates come from the client.** The security rules allow any signed-in user to change the rating fields. Move this to a Cloud Function before going live.
- **OpenStreetMap tiles**: the public tile server is for light use only. Switch to a tile provider you have an account with before publishing the app (`lib/widgets/osm_map.dart`).
- ETA is a straight-line estimate at 40 km/h, not a routed estimate.
- Emergency numbers are for Egypt; edit `lib/core/constants.dart` for other countries.
- Package versions in `pubspec.yaml` were chosen without running the app; if `flutter pub get` complains, run `flutter pub upgrade --major-versions` and fix any API changes.

## Tech stack

Flutter, Dart, Firebase Auth, Cloud Firestore, flutter_map + OpenStreetMap, geolocator, provider, url_launcher.
