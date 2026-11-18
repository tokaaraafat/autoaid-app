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


## Author

**Toka Raafat**

-   [GitHub](https://github.com/tokaaraafat)

------------------------------------------------------------------------

*AutoAid --- Making roadside assistance more accessible, connected, and
convenient.*
