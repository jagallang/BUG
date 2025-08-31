# BugCash

A Flutter-based bug testing platform that connects software providers with testers through gamified missions and rewards.

## 🌟 Overview

BugCash is a comprehensive bug testing platform built with Flutter that enables:
- **Software Providers**: Register applications, create testing missions, and monitor results
- **Testers**: Discover missions, test applications, and earn rewards for valid bug reports

## ✨ Features

### For Testers
- 🎯 **Mission Discovery**: Browse and accept testing missions
- 🏆 **Gamification**: Earn points and climb rankings
- 💰 **Rewards System**: Get paid for valid bug reports
- 📱 **Real-time Updates**: Live mission updates and notifications
- 🔍 **Search & Filter**: Find missions that match your skills

### For Providers
- 📋 **Mission Management**: Create and monitor testing campaigns
- 📊 **Analytics Dashboard**: Track mission performance and results
- 👥 **Tester Management**: Review and validate bug reports
- 🎯 **Difficulty Analysis**: AI-powered mission difficulty assessment
- 📈 **Progress Tracking**: Real-time mission progress monitoring

### Core Features
- 🔐 **Firebase Authentication**: Secure login with Google Sign-In
- 💾 **Offline Support**: Continue testing even without internet
- 🔄 **Real-time Sync**: Automatic data synchronization
- 📱 **Multi-platform**: Web, iOS, Android, and Desktop support
- 🎨 **Modern UI**: Responsive design with dark/light theme support

## 🚀 Tech Stack

- **Flutter** 3.29.2 - Cross-platform UI framework
- **Firebase** - Authentication, Firestore, Storage, Messaging
- **Riverpod** - State management
- **Flutter Bloc** - State management pattern
- **Google Fonts** - Typography
- **Screen Util** - Responsive design

## 🏗️ Architecture

The project follows Clean Architecture principles with feature-based organization:

```
lib/
├── core/                    # Shared utilities and configurations
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── missions/          # Mission management
│   ├── provider_dashboard/ # Provider interface
│   ├── tester_dashboard/  # Tester interface
│   ├── notifications/     # Push notifications
│   └── ...
└── shared/                # Shared widgets and themes
```

## 🛠️ Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase project setup
- Environment configuration

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/jagallang/BUG.git
   cd BUG/bugcash
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add your Firebase configuration files
   - Copy `.env.example` to `.env` and fill in your configuration

4. **Run the application**
   ```bash
   flutter run -d web      # For web
   flutter run -d ios      # For iOS
   flutter run -d android  # For Android
   ```

## 📱 Supported Platforms

- ✅ **Web** (Primary target)
- ✅ **iOS**
- ✅ **Android**
- ✅ **macOS**
- ✅ **Linux**
- ✅ **Windows**

## 🔧 Development

### Build Commands
```bash
# Development
flutter run -d web

# Production builds
flutter build web
flutter build apk
flutter build ios
```

### Testing
```bash
flutter test
flutter analyze
```

## 🌐 Deployment

The application supports Firebase Hosting for web deployment:

```bash
firebase deploy
```

Refer to `DEPLOYMENT_GUIDE.md` for detailed deployment instructions.

## 📄 License

This project is available for educational and demonstration purposes.

## 🤝 Contributing

This is a demonstration project. For inquiries, please contact the repository owner.

## 📞 Support

For technical support or questions, please create an issue in the GitHub repository.

---

Built with ❤️ using Flutter and Firebase