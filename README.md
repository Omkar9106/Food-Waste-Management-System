# Food Waste Management App

A Flutter application that connects food donors with NGOs to reduce food waste and help communities.

## Features

- **Donor Dashboard**: Add and manage food donations
- **NGO Dashboard**: Browse available food and manage requests
- **Real-time Updates**: Firebase Firestore integration for live data
- **Location Services**: Geolocation for pickup coordination
- **Notifications**: Real-time notification system
- **Analytics**: Track donation statistics
- **Rating System**: Rate and review donations

## Platforms

- ✅ Android
- ✅ iOS
- ✅ Web (Vercel deployment ready)
- ✅ Windows
- ✅ Linux
- ✅ macOS

## Getting Started

### Prerequisites

- Flutter SDK (3.11.1 or higher)
- Firebase project with Firestore configured
- For mobile: Android Studio / Xcode
- For web: Modern web browser

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - The app uses Firebase project: `food-waste-management-549d6`
   - Firebase configuration is already set up in `lib/firebase_options.dart`
   - Ensure Firestore rules and indexes are deployed

4. Run the app:
   ```bash
   # Mobile
   flutter run

   # Web
   flutter run -d chrome
   ```

## Web Deployment

### Deploy to Vercel

1. **Automatic Deployment (Recommended)**
   - Push code to GitHub/GitLab/Bitbucket
   - Import project in [Vercel](https://vercel.com)
   - Configure:
     - Framework Preset: Other
     - Build Command: `flutter build web --release`
     - Output Directory: `build/web`
     - Install Command: `flutter pub get`
   - Deploy

2. **Manual Deployment**
   ```bash
   # Build locally
   flutter build web --release --web-renderer canvaskit

   # Deploy using Vercel CLI
   npm i -g vercel
   vercel login
   vercel --prod
   ```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)

## Firebase Configuration

### Firestore Rules
Ensure your Firestore rules are deployed:
```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes
Deploy required indexes:
```bash
firebase deploy --only firestore:indexes
```

## Project Structure

```
lib/
├── screens/          # UI screens
├── services/         # Business logic (Auth, Donation, etc.)
├── widgets/          # Reusable components
├── theme/           # App theming
└── main.dart        # App entry point
```

## Dependencies

- firebase_core: Firebase initialization
- firebase_auth: Authentication
- cloud_firestore: Database
- geolocator: Location services
- geocoding: Address geocoding
- google_fonts: Typography
- flutter_animate: Animations
- shared_preferences: Local storage

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
