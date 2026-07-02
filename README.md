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
- **Communities & Events Spaces**:
  - **Create Community & Event**: Clean bottom sheets allowing creation of public or invite-only spaces and online/offline meetup events.
  - **Dynamic Detail Views**: Dedicated detail pages rendering live descriptions, schedules, host info, dynamic member avatar tabs, and direct navigations to view friend accounts.
  - **Creator/Organizer Action Locks**: Prevents community creators and event organizers from leaving their own spaces, locking the primary actions to "Creator" and "Organizer" respectively.
- **Interactive Posts Feed**:
  - **Real-time Feed**: Real-time posts stream sorted in memory to deliver the newest updates on top indefinitely.
  - **Minimal Post Composer**: Bottom sheet composer featuring smooth text fields, tags management, and a closeable image preview widget.
  - **Post Engagement**: Dynamic Like and Dislike toggle actions with responsive color highlights (Cyan for Likes, Soft Red for Dislikes) that automatically cancel opposing states.
- **Dynamic HomeScreen Hub & Coordinated Navigation**:
  - **Live Streams**: Home page binds directly to Firestore displaying the top trending communities (sorted by membership) and the closest upcoming events.
  - **Tab Navigation Controller**: A decoupled programmatic event controller that synchronizes navigation index switches and sub-tab selection (Communities vs. Events) seamlessly.
- **Clipboard Sharing Integration**:
  - All share buttons on Communities, Events, and Posts copy active deep-link URLs directly to the system clipboard (supported with floating SnackBars).

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
    │   ├── community/       # Data models, streams, services for communities & posts
    │   ├── event/           # Data models and streams for event management
    │   ├── explore/         # Creation sheets, details pages, search, and dynamic tab panels
    │   ├── home/            # Main application layout, notifications, and tab navigation
    │   ├── onboarding/      # Onboarding flow components
    │   ├── profile/         # Profile management, password edits
    │   ├── splash/          # Splash screen presentation and logic
    │   └── welcome/         # Welcome screen presentation
    └── main.dart
```

## Technologies Used
- [Flutter](https://flutter.dev/) - Framework
- [Dart](https://dart.dev/) - Language
- [Cloud Firestore](https://firebase.google.com/docs/firestore) - NoSQL Cloud Database
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) - Native splash screen customization
- [mailer](https://pub.dev/packages/mailer) - SMTP email transmission helper
- [image_picker](https://pub.dev/packages/image_picker) - Access device photo library and camera
- [crypto](https://pub.dev/packages/crypto) - Hashing for secure Cloudinary uploads
- [animated_notch_bottom_bar](https://pub.dev/packages/animated_notch_bottom_bar) - Bottom navigation styling

## Authors
- **Prabesh-Shrestha**
