# Nexus App

Nexus is a Flutter-based mobile application designed for gamers. It provides a platform to "Own the Arena," "Join the Community," and "Find Your Squad," allowing players to connect, chat, and team up based on their games, rank, and playstyles.

## Features

- **Dynamic Splash Screens**: 
  - Uses `flutter_native_splash` for a seamless launch experience.
  - Custom Flutter splash screen with animated "Connecting" phase.
- **Welcome Screen**: 
  - Visually striking central logo container with radial gradients.
  - Interactive "Swipe Up to Begin" gesture transition.
- **Onboarding Flow**: 
  - Sliding `PageView` interface with three distinct onboarding steps.
  - Dynamic gradient-colored page indicators.
- **Authentication Setup**:
  - **Login Screen**: Features fields for username/email, password, "Remember me", and social login options (Google, Facebook, Apple).
  - **Signup Screen**: Comprehensive account creation form collecting full name, username, DOB, gender, email, and password.
  - **Success Screen**: A congratulatory setup success screen marking the completion of the onboarding flow.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version recommended)
- Android Studio / Xcode for emulators and compilation
- VS Code or your preferred IDE with Flutter/Dart extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Pravesh-Shrestha/nexus_app.git
   cd nexus_app
   ```

2. Fetch the required dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Folder Structure

The project follows a feature-first architectural pattern:

```text
nexus_app/
├── assets/
│   └── images/
│       ├── auth/
│       ├── onboarding/
│       ├── splash/
│       └── welcome/
└── lib/
    ├── core/                # Core functionalities, theming, and constants
    ├── features/
    │   ├── auth/            # Login, Signup, Setup Success screens
    │   ├── home/            # Main application hub (in progress)
    │   ├── onboarding/      # Onboarding flow components
    │   ├── splash/          # Splash screen presentation and logic
    │   └── welcome/         # Welcome screen presentation
    └── main.dart
```

## Technologies Used
- [Flutter](https://flutter.dev/) - Framework
- [Dart](https://dart.dev/) - Language
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) - Native splash screen customization

## Authors
- **Prabesh-Shrestha** - Initial work
