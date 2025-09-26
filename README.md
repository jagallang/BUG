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

### v2.0.06 (Latest) - Firebase 백엔드 완전 연동 및 로그인 시스템 수정
*Released: 2025-09-27*

**🔥 Firebase 백엔드 완전 연동:**
- **실제 프로젝트 연결**: Firebase CLI로 정확한 웹 앱 설정 정보 획득
- **API 키 적용**: 실제 프로젝트 API 키로 교체 (AIzaSyAeMQcgKwJR5smPY6t6tnDtNdqaPoCamk0)
- **측정 ID 설정**: Google Analytics 연동을 위한 측정 ID 실제 값 적용 (G-M1DT15JR9G)
- **환경변수 동기화**: .env 파일과 firebase_options.dart 설정 일치화

**🛡️ Firestore 보안 규칙 개선:**
- **필드명 통일**: role → userType 필드 기반 권한 체크로 변경
- **컬렉션 접근 권한**: missions, missionApplications, earnings 임시 허용 설정
- **인증 기반 보안**: 인증된 사용자만 데이터 접근 가능하도록 설정
- **규칙 배포 완료**: Firebase Firestore 보안 규칙 프로덕션 반영

**🌐 웹 배포 시스템 완성:**
- **호스팅 설정 추가**: firebase.json에 웹 호스팅 구성 완료
- **도메인 연결**: bugcash.web.app 도메인으로 접근 가능
- **CORS 및 라우팅**: SPA 라우팅 및 크로스 오리진 설정 완료
- **프로덕션 빌드**: 최적화된 웹 앱 빌드 및 배포

**✅ 로그인 시스템 검증:**
- **로컬 테스트 성공**: Chrome 환경에서 로그인 정상 작동 확인
- **Firebase Auth 연동**: 이메일/패스워드 로그인 시스템 완전 작동
- **사용자 데이터 로드**: Firestore에서 사용자 정보 정상 조회
- **역할별 라우팅**: tester, provider, admin 역할별 대시보드 이동

**📊 기술적 개선사항:**
- **백엔드 연동률**: Mock 시스템 → 100% Firebase 백엔드 연동
- **설정 정확도**: Placeholder 값 → 실제 프로덕션 설정값
- **보안 강화**: 임시 허용 → 인증 기반 접근 제어
- **배포 안정성**: 로컬 전용 → 프로덕션 웹 서비스 가능

### v2.0.05 - 코드 품질 및 개발환경 최적화
*Released: 2025-09-27*

**🔧 코드 품질 대폭 개선:**
- **80% 이슈 해결**: Flutter analyze 결과 431개 → 84개 이슈로 극적 개선
- **Scripts 정리**: 개발 도구 및 스크립트 파일들을 tools/ 디렉토리로 체계적 정리
- **구조 최적화**: 미사용 main_*.dart 파일 제거 및 주석 코드 정리
- **분석 최적화**: analysis_options.yaml 설정으로 개발 도구 분석 범위 최적화

**🛠️ 개발 환경 개선:**
- **개발 가이드**: CLAUDE.md 추가로 안전한 코드 수정 가이드라인 제공
- **위험성 체크**: 코드 수정 시 의존성 분석 및 영향도 평가 시스템
- **단계별 검증**: Phase별 코드 정리로 안전성과 효율성 확보
- **도구 분리**: 프로덕션 코드와 개발 도구의 명확한 분리

**⚡ 성능 및 유지보수성:**
- **빌드 최적화**: 불필요한 파일 제거로 빌드 시간 개선
- **코드 정리**: print() 사용 정리 및 deprecated API 경고 최소화
- **구조 개선**: Clean Architecture 원칙에 따른 프로젝트 구조 최적화
- **개발 생산성**: 체계적 파일 구조로 개발 효율성 향상

**📊 정량적 개선 결과:**
- **코드 이슈**: 431개 → 84개 (80.5% 개선)
- **Scripts 정리**: 8개 파일 적절한 위치로 이동
- **파일 정리**: 중복 및 미사용 파일 15개 제거
- **구조 개선**: tools/, admin/ 디렉토리 체계화

### v1.4.12 - Bidirectional Application Status Display System
*Released: 2025-01-16*

**🔄 Bidirectional Application Status Display:**
- **Tester Dashboard Enhancement**: Added comprehensive "신청 현황" (Application Status) tab in mission section
- **Real-time Status Tracking**: Live application status updates (pending, reviewing, accepted, rejected, cancelled)
- **Provider-Tester Communication**: Complete bidirectional visibility of application status between both user types
- **Status Management**: Real-time application state synchronization via Firebase Firestore streams

**🎨 UI/UX Improvements:**
- **Status Visualization**: Color-coded status indicators with intuitive icons for each application state
- **Detailed Information**: Application messages and provider responses displayed with proper formatting
- **Time Formatting**: Human-readable time-ago formatting (N일 전, N시간 전, N분 전) for application timestamps
- **Empty State Handling**: Informative empty states for both tester and provider dashboards
- **Responsive Design**: Optimized mobile interface with proper spacing and touch targets

**🏗️ Technical Implementation:**
- **Data Models**: Added MissionApplicationStatus model with comprehensive application state tracking
- **Firebase Integration**: Enhanced Firestore queries for real-time application data synchronization
- **Authentication Integration**: Seamless integration with actual Firebase user authentication data
- **Collection Consistency**: Fixed collection naming consistency (missionApplications) across the codebase
- **Stream Management**: Optimized real-time data streams for better performance and reliability

**🗑️ Code Cleanup & Optimization:**
- **Mock System Removal**: Deleted mock_auth_provider.dart completing the mock system elimination
- **Production Architecture**: Full transition to production-ready Firebase backend integration
- **Code Quality**: Enhanced error handling and debugging capabilities
- **Performance Optimization**: Reduced unnecessary widget rebuilds and improved memory management

**🤝 User Experience Enhancement:**
- **For Testers**: Complete overview of all applied missions with detailed status information
- **For Providers**: Real-time management of application requests with tester information and feedback
- **Communication Loop**: End-to-end application-response communication system between testers and providers
- **Status Transparency**: Clear visibility into application workflow for all stakeholders

**📊 Data Architecture:**
- **Real-time Queries**: Efficient Firestore queries for application status retrieval
- **Bidirectional Sync**: Automatic data synchronization between tester and provider dashboards
- **State Persistence**: Reliable application state management with proper error handling
- **Scalable Design**: Database structure optimized for production-scale application management

### v1.4.11 - Complete Mock Data Removal & Real Firebase Backend Integration
*Released: 2025-01-16*

**🗑️ Mock Data Elimination:**
- **Complete Removal**: Eliminated all hardcoded mock data from mock_data_source.dart
- **Service Cleanup**: Deleted mock_auth_service.dart completely
- **Production Ready**: Removed local data storage and simulation systems
- **Real Data Flow**: Transitioned from simulated to actual Firebase data operations

**🔄 Firebase Integration:**
- **Full Firestore Integration**: Converted MockDataSource to FirebaseDataSource with real queries
- **Async Operations**: Implemented proper async/await patterns for all data operations
- **Real-time Sync**: Added Stream-based real-time data synchronization across the app
- **Error Handling**: Enhanced error management with proper exception handling

**🔐 Authentication Overhaul:**
- **Pure Firebase Auth**: Migrated to 100% Firebase Authentication system
- **Hybrid Removal**: Eliminated complex hybrid authentication approach
- **Real-time State**: Implemented live auth state management with automatic updates
- **Google Sign-In**: Added native Google Sign-In support
- **Data Persistence**: Enhanced user data storage and retrieval in Firestore

**📊 Real-time Features:**
- **Live Mission Updates**: Stream-based mission applications monitoring
- **Dynamic Dashboards**: Real-time provider dashboard statistics
- **Tester Tracking**: Live tester profile and earnings tracking
- **Mission Distribution**: Dynamic mission distribution with Firestore queries

**🏗️ Architecture Improvements:**
- **Clean Separation**: Proper data source and business logic separation
- **Async Error Handling**: Comprehensive error handling throughout the app
- **State Management**: Streamlined provider state management system
- **Provider Cleanup**: Removed duplicate provider definitions and conflicts

**🚀 Performance Optimizations:**
- **Efficient Queries**: Optimized Firestore query patterns for better performance
- **Reduced Fetching**: Minimized unnecessary data fetching operations
- **Memory Management**: Better memory management with optimized real-time listeners
- **Production Architecture**: Full production-ready backend integration

**📱 Data Structure:**
- **Firestore Collections**: Organized data structure with proper collections (users, providers, testers, missions, missionApplications, bugReports, apps, activities)
- **Real-time Updates**: Live data synchronization across all app components
- **Scalable Design**: Database structure designed for production scalability

### v1.2.05 - Expandable UI & Korean Localization
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