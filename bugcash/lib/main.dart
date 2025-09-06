import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'core/utils/logger.dart';
import 'core/config/app_config.dart';
// import 'features/auth/presentation/widgets/auth_wrapper.dart';  // 임시 비활성화
// import 'features/provider_dashboard/presentation/pages/provider_dashboard_page.dart';  // Provider Dashboard
import 'features/tester_dashboard/presentation/pages/tester_dashboard_page.dart';  // Tester Dashboard 직접 import
import 'shared/theme/app_theme.dart';

// 웹용 반응형 크기 헬퍼 - 깔끔한 크기로 조정
extension ResponsiveText on num {
  double get rsp => kIsWeb ? (this * 1.1).toDouble() : sp;
  double get rw => kIsWeb ? (this * 0.9).w : w;
  double get rh => kIsWeb ? (this * 0.9).h : h;
  double get rr => kIsWeb ? (this * 0.9).r : r;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 설정 초기화
  await AppConfig.initialize();
  
  bool isFirebaseAvailable = false;
  
  try {
    // Firebase 초기화 비활성화 - Mock 전용 모드로 실행
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // isFirebaseAvailable = true;
    AppLogger.info('Running in Mock-only mode', 'Main');
    
    // 데모 데이터 초기화는 건너뛰기 (Firestore 의존성 때문)
    // if (kDebugMode) {
    //   try {
    //     await FirebaseService.initializeDemoData().timeout(
    //       const Duration(seconds: 5),
    //       onTimeout: () {
    //         AppLogger.warning('Demo data initialization timed out', 'Main');
    //       },
    //     );
    //   } catch (demoError) {
    //     AppLogger.error('Demo data initialization failed', 'Main', demoError);
    //   }
    // }
  } catch (e) {
    AppLogger.error('Firebase initialization failed', 'Main', e);
    AppLogger.info('Running in offline mode with fallback data', 'Main');
  }
  
  runApp(
    ProviderScope(
      child: BugCashWebApp(isFirebaseAvailable: isFirebaseAvailable),
    ),
  );
}

class BugCashWebApp extends StatelessWidget {
  final bool isFirebaseAvailable;
  
  const BugCashWebApp({super.key, required this.isFirebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: kIsWeb ? const Size(800, 600) : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash - 웹 앱 테스트 플랫폼',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          // home: const AuthWrapper(),  // 임시 비활성화
          home: const TesterDashboardPage(
            testerId: 'test_tester_001',  // 테스트용 Tester ID
          ),
        );
      },
    );
  }
}