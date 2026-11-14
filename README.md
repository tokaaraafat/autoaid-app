# AutoAid -- Roadside Assistance App

**Roadside assistance, just a few taps away.**

AutoAid is a Flutter-based mobile application that connects drivers
experiencing vehicle breakdowns with nearby roadside-assistance
providers. Customers can request help, share their location, track
service progress, communicate with providers, and manage their
assistance requests through one application.

The project is based on the AutoAid graduation project design developed
at **Sadat Academy for Management Sciences -- Faculty of Computers and
Information Systems (2023--2024)**, including its use case diagrams,
class diagram, and Entity Relationship Diagram (ERD).

------------------------------------------------------------------------

## Overview

When a vehicle breaks down, finding reliable roadside assistance can be
difficult and time-consuming. AutoAid addresses this problem by
providing a platform where customers can request specific services and
connect with nearby providers.

The application supports three main roles:

-   **Customers:** Request assistance, manage vehicles, track providers,
    and communicate with service providers.
-   **Service Providers:** Receive nearby requests, manage availability,
    and handle assistance jobs.
-   **Administrators:** Verify service provider accounts.

## Key Features

### Customer

-   Register, log in, and manage account details.
-   Add and manage vehicles, including model, license plate, insurance,
    and registration information.
-   Request roadside assistance:
    -   Towing
    -   Flat tire assistance
    -   Battery jump-start
    -   Fuel delivery
    -   Vehicle lockout
    -   Engine problems
-   Select a service location using GPS or by tapping the map.
-   Track the assigned provider's live location.
-   View estimated arrival time and distance.
-   Communicate through in-app chat or phone calls.
-   Cancel a request before it is completed.
-   Select a payment method (cash or simulated wallet/Visa).
-   Rate providers after service completion.
-   Access emergency contact numbers and submit accident reports to
    providers.

### Service Provider

-   Register and wait for administrator verification.
-   Switch between available and offline modes.
-   View pending requests within a 50 km radius, ordered by distance.
-   Accept requests, with the first successful acceptance securing the
    job.
-   Update job progress:
    -   Accepted
    -   On the way
    -   Arrived
    -   Completed
-   Share live GPS location with customers while a job is active.
-   Communicate with customers through chat and phone calls.
-   Maintain an average rating based on customer reviews.

### Administrator

-   Review and verify service provider accounts.

------------------------------------------------------------------------

## Application Workflow

1.  A customer creates an account and adds vehicle information.
2.  The customer selects an assistance service and specifies a location.
3.  Nearby available providers can view the pending request.
4.  The first provider to successfully accept the request becomes
    responsible for the job.
5.  The provider updates the service status and shares their live
    location.
6.  The customer tracks the provider and communicates through the
    application.
7.  After the service is completed, the customer selects a payment
    method and submits a rating.

------------------------------------------------------------------------

## Technology Stack

  Technology                Purpose
  ------------------------- -----------------------------------------------
  Flutter                   Cross-platform mobile application development
  Dart                      Application programming language
  Firebase Authentication   User registration and authentication
  Cloud Firestore           Real-time database and data management
  OpenStreetMap             Map display and location selection
  `flutter_map`             OpenStreetMap integration
  `geolocator`              GPS and location services
  `provider`                Application state management
  `url_launcher`            Phone calls and external actions

------------------------------------------------------------------------

## Project Structure

The application uses a modular structure to separate screens, business
logic, data access, and shared components.

``` text
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants.dart
│   ├── models/
│   └── helpers/
├── services/
│   ├── app_state.dart
│   ├── firestore_service.dart
│   └── location_service.dart
├── widgets/
│   └── osm_map.dart
└── screens/
    ├── auth/
    ├── customer/
    ├── provider/
    ├── admin/
    └── shared/

firestore.rules
test/
```

### Main Components

-   **App State:** Handles authentication state and the signed-in user's
    profile.
-   **Firestore Service:** Centralizes database operations and
    communication with Cloud Firestore.
-   **Location Service:** Handles GPS access, distance calculations, and
    ETA estimation.
-   **OSM Map:** Provides map visualization and location selection.
-   **Auth Gate:** Directs users to the appropriate interface according
    to their assigned role.

------------------------------------------------------------------------

## Database Design

The Firestore structure follows the main entities and relationships
defined in the original project design.

  Design Entity          Firestore Implementation
  ---------------------- -------------------------------------------------
  `AutoAidUser`          `users` collection
  `ServiceProvider`      `users` collection (`role: provider`)
  `Vehicle`              `users/{uid}/vehicles`
  `AssistanceRequest`    `requests` collection
  `Communication`        `requests/{id}/messages`
  `Payment`              Payment fields within the request document
  Service transactions   `serviceTypes` in `lib/core/constants.dart`
  Emergency services     `emergencyNumbers` in `lib/core/constants.dart`

### Assistance Request Lifecycle

``` text
Pending
   |
   v
Accepted
   |
   v
On the Way
   |
   v
Arrived
   |
   v
Completed
```

A request can also be cancelled before completion.

Request acceptance uses a **Firestore transaction** so that only the
first successful provider acceptance is recorded.

------------------------------------------------------------------------

## Getting Started

Follow these steps to configure and run AutoAid locally.

### Prerequisites

Make sure you have installed:

-   [Flutter SDK](https://docs.flutter.dev/get-started/install)
-   [Dart SDK](https://dart.dev/get-dart)
-   [Android Studio](https://developer.android.com/studio) or Visual
    Studio Code
-   A [Firebase account](https://console.firebase.google.com/)

### 1. Clone the Repository

``` bash
git clone https://github.com/tokaaraafat/autoaid-app.git
cd autoaid-app
```

### 2. Generate Platform Folders

The repository contains the Dart source code. Generate the Android and
iOS platform folders:

``` bash
flutter create . --platforms=android,ios --project-name autoaid --org com.yourname
```

Install the dependencies:

``` bash
flutter pub get
```

### 3. Configure Firebase

1.  Create a project in the [Firebase
    Console](https://console.firebase.google.com/).
2.  Enable **Email/Password** under Authentication → Sign-in method.
3.  Create a **Cloud Firestore** database.
4.  Configure Firebase for your target platforms.

Install FlutterFire CLI:

``` bash
dart pub global activate flutterfire_cli
```

Connect the Flutter application:

``` bash
flutterfire configure
```

This generates `lib/firebase_options.dart` with your Firebase project
configuration.

### 4. Configure Firestore Security Rules

Open the Firestore **Rules** tab in the Firebase Console, paste the
contents of the repository's `firestore.rules` file, and publish the
rules.

### 5. Configure Platform Permissions

**Android**

Add the following permissions to
`android/app/src/main/AndroidManifest.xml`, inside the `<manifest>`
element and above `<application>`:

``` xml
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

Set the minimum Android SDK version to **23 or higher** in the app-level
Gradle configuration.

**iOS**

Add the following keys to `ios/Runner/Info.plist`:

``` xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AutoAid needs your location to send assistance to you.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tel</string>
</array>
```

### 6. Run the Application

``` bash
flutter run
```

Run the unit tests with:

``` bash
flutter test
```

------------------------------------------------------------------------

## Testing the Application

You can test the main workflow using two devices or emulators.

1.  Create a customer account.
2.  Create a service provider account on another device.
3.  Create an administrator account.
4.  In Firebase Console, open `users/{uid}` for the administrator
    account and manually change its `role` field to `admin`.
5.  Log in as the administrator and verify the provider account.
6.  Log in as the provider and switch the availability status to
    **Available**.
7.  Log in as the customer and submit an assistance request.
8.  Accept the request from the provider account.
9.  Update the job status and observe the customer's tracking map.

**Testing tip:** For location-based functionality, configure simulated
GPS coordinates through the Android Emulator's Extended Controls or the
iOS Simulator's Location settings.

------------------------------------------------------------------------

## Current Limitations & Future Improvements

AutoAid demonstrates the core roadside-assistance workflow. Some
components would require further development before production
deployment.

  -----------------------------------------------------------------------
  Area                    Current Implementation  Potential Improvement
  ----------------------- ----------------------- -----------------------
  Request dispatching     Providers retrieve      Server-side dispatching
                          nearby requests and     using Firebase Cloud
                          compete to accept them  Functions

  Notifications           No dedicated push       Firebase Cloud
                          notification system     Messaging

  Payments                Cash and simulated      Integration with a
                          wallet/Visa selection   payment gateway

  Ratings                 Rating fields are       Server-side validation
                          updated from the client and aggregation

  Maps                    Public OpenStreetMap    Dedicated tile hosting
                          tile server             or a commercial tile
                                                  provider

  ETA                     Straight-line estimate  Road-based routing and
                          at 40 km/h              traffic-aware ETA

  Security                Firestore security      Additional server-side
                          rules                   validation and
                                                  authorization
  -----------------------------------------------------------------------

### Additional Notes

-   Provider dispatch currently relies on client-side request discovery.
-   Payment methods record the customer's selection; no actual financial
    transaction takes place.
-   Emergency contact numbers are configured for Egypt and can be
    modified in `lib/core/constants.dart`.
-   The current ETA is an approximation, not a navigation-based
    estimate.
-   The public OpenStreetMap tile server is intended for limited use. A
    suitable tile provider should be configured before a public release.

------------------------------------------------------------------------

## Project Background

AutoAid originated as a graduation project at **Sadat Academy for
Management Sciences, Faculty of Computers and Information Systems
(2023--2024)**.

This implementation translates the original system analysis and design
into a Flutter mobile application, connecting the documented use cases,
class structure, and database entities to application components.

------------------------------------------------------------------------

## Author

**Toka Raafat**

-   [GitHub](https://github.com/tokaaraafat)

------------------------------------------------------------------------

*AutoAid --- Making roadside assistance more accessible, connected, and
convenient.*
