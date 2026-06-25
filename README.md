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
- **Authentication & Setup**:
  - **Login Screen**: Fields for username/email, password, "Remember me", password recovery reset dialog, and social login options (Google, Facebook, Apple).
  - **Signup Screen**: Account creation form collecting full name, username, DOB (with auto-formatting `YYYY/MM/DD` mask and validation), gender, email, password, and a **Terms & Privacy policy agreement checkbox**.
  - **Success Screen**: A congratulatory setup success screen that automatically triggers a styled Welcome Email.
- **SMTP Email Notification Service**:
  - Integrates an SMTP server configuration (`email_config.dart` supporting Google App Passwords).
  - Triggers beautiful responsive dark-themed transactional HTML emails for welcome notifications and password updated security alerts.
  - Modular helper structure allowing developers to add future notification templates (e.g. community invites).
- **Cloudinary Avatar integration**:
  - Tapping the avatar stack opens a sheet to pick images from **Camera** or **Gallery**.
  - Automatically signs and uploads image files to Cloudinary's secure REST API.
  - Dynamically displays network/base64 avatars across the Profile, Edit Profile form, and Home Screen headers.

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
    ├── core/                # Core functionalities, utilities, theming, and constants
    │   ├── config/          # Configurations (Cloudinary, SMTP Email)
    │   ├── services/        # Services (SMTP Email, Cloudinary uploading)
    │   ├── utils/           # Shared utility classes (TextInputFormatters)
    │   └── theme/           # Theming assets (AppColors, AppSizes)
    ├── features/
    │   ├── auth/            # Login, Signup, Setup Success screens
    │   ├── home/            # Main application hub
    │   ├── onboarding/      # Onboarding flow components
    │   ├── profile/         # Profile management, password edits
    │   ├── splash/          # Splash screen presentation and logic
    │   └── welcome/         # Welcome screen presentation
    └── main.dart
```

## Technologies Used
- [Flutter](https://flutter.dev/) - Framework
- [Dart](https://dart.dev/) - Language
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) - Native splash screen customization
- [mailer](https://pub.dev/packages/mailer) - SMTP email transmission helper
- [image_picker](https://pub.dev/packages/image_picker) - Access device photo library and camera
- [crypto](https://pub.dev/packages/crypto) - Hashing for secure Cloudinary uploads

## Authors
- **Prabesh-Shrestha**
