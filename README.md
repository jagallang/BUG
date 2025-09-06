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

## 📋 Version History

### v1.2.05 (Latest) - Expandable UI & Korean Localization
*Released: 2025-01-09*

**🎨 Expandable UI Components:**
- **Interactive Mission Cards**: Collapsible/expandable mission cards in progress tab with smooth 300ms animations
- **Community Board Posts**: Touch-to-expand community posts with preview and full content states
- **Daily Progress Grid**: Visual 7-day progress calendar with status indicators and touch interactions
- **Responsive Layouts**: Fixed overflow issues with proper constraints and responsive design

**📱 Community Board Enhancement:**
- **Profile → Community**: Complete transformation of profile tab into fully functional community board
- **Post Creation System**: Category-based post creation (버그발견, 팁공유, 미션추천, 질문)
- **Advanced Filtering**: Real-time category filtering with visual feedback
- **Rich Interactions**: Like, comment, share functionality with expandable action buttons

**🚀 Mission Management:**
- **Compact Overview**: Collapsed state showing essential info (progress %, points, deadline)
- **Detailed Expansion**: Full progress tracking with daily status grid and action buttons
- **Progress Visualization**: Color-coded progress indicators (green/orange/red) based on completion rates
- **Quick Actions**: Direct access to daily missions, progress history, and detailed information

**🌐 Korean Localization:**
- **Complete Translation**: All sync management and settings interfaces fully localized
- **Consistent Terminology**: Standardized Korean tech terms throughout the application
- **User-Friendly Labels**: Natural Korean expressions for better user comprehension
- **Cultural Adaptation**: UI text optimized for Korean reading patterns

**🔧 Technical Excellence:**
- **Animation Framework**: Smooth AnimatedContainer transitions for expand/collapse states
- **Overflow Prevention**: SingleChildScrollView and Wrap widgets for responsive layouts
- **Performance Optimization**: Reduced widget complexity and memory usage
- **Touch Responsiveness**: Enhanced touch targets and visual feedback systems

**📊 User Experience:**
- **Information Hierarchy**: Clear distinction between overview and detailed states
- **Space Efficiency**: More content visible in collapsed states for better screen utilization
- **Intuitive Navigation**: Visual cues (expand/collapse icons) for clear interaction guidance
- **Mobile-First Design**: Optimized for mobile touch interactions and screen sizes

### v1.2.04 - UI Simplification & Clean Design
*Released: 2025-01-09*

**🎨 UI/UX Improvements:**
- **Dashboard Simplification**: Removed statistics cards (오늘완료, 평균진행률, 오늘미션) from progress tab
- **Clean Interface**: Eliminated redundant header cards and visual clutter
- **Streamlined Navigation**: Direct focus on core mission functionality without distracting elements
- **Minimalist Design**: Simplified mission tabs and progress displays

**🔧 Code Optimization:**
- **Reduced Complexity**: Removed 130+ lines of unused UI components and methods
- **Better Performance**: Faster rendering with simplified widget structure
- **Cleaner Architecture**: Eliminated redundant calculations and unused variables
- **Mission Display**: Reduced mission cards from 5 to 3 for better focus

**📱 User Experience:**
- **Faster Loading**: Streamlined UI components for quicker app responses
- **Intuitive Design**: Removed information overload for cleaner user journey
- **Essential Features**: Focus on core functionality without unnecessary statistics
- **Mobile Optimized**: Better space utilization on mobile devices

**🚀 Performance:**
- **Lighter Codebase**: Significant reduction in UI rendering overhead
- **Improved Memory Usage**: Less widgets and calculations in memory
- **Faster Navigation**: Direct access to mission lists without header delays

### v1.2.03 - Code Quality & Performance Improvements
*Released: 2025-01-09*

**🔧 Major Improvements:**
- **Code Quality Enhancement**: Reduced Flutter analyze issues from 306 to 140 (54% improvement)
- **Performance Optimization**: Added const constructors to critical UI components
- **API Modernization**: Replaced deprecated `withOpacity()` with `withValues(alpha:)` (91+ instances)
- **Production Safety**: Replaced `print()` with `debugPrint()` statements (24+ fixes)
- **Type Safety**: Fixed UserModel and UserEntity compatibility issues

**✨ Features:**
- Enhanced provider dashboard with modular widget components
- Improved authentication system with proper user type handling
- Better error handling and debugging capabilities
- Cleaner codebase with removed unused imports and variables

**🚀 Performance:**
- Faster UI rendering with optimized constructors
- Reduced memory usage in production builds
- Eliminated deprecated API warnings
- Better debugging experience in development

**🛠️ Technical:**
- Fixed critical compilation errors
- Improved null safety handling  
- Enhanced connection status widget logic
- Better code modularity in dashboard components

### v1.2.02 - App Registration System
- Implemented comprehensive app registration for providers
- Enhanced dashboard navigation and user experience
- Added mission monitoring and analytics features

### Previous Versions
- v1.2.01: Provider Dashboard enhancements
- v1.2.00: Core platform features and authentication
- v1.1.x: Initial tester and provider functionality
- v1.0.x: Basic platform foundation

---

Built with ❤️ using Flutter and Firebase