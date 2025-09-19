import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'generated/l10n/app_localizations.dart';
import 'core/utils/logger.dart';
import 'core/config/app_config.dart';
import 'core/services/api_key_service.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
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

  // 환경변수 초기화 (Firebase 초기화 전에 실행)
  await _initializeEnvironment();

  // Firebase 초기화 (Firebase 공식 권장 방식)
  await _initializeFirebase();

  runApp(
    const ProviderScope(
      child: BugCashWebApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
    // Firebase 초기화 - 동적 API 키 사용
    final firebaseOptions = await DefaultFirebaseOptions.currentPlatformWithApiKey;
    await Firebase.initializeApp(
      options: firebaseOptions,
    );

    if (AppConfig.enableLogging) {
      AppLogger.info('Firebase initialized successfully', 'Main');
    }

    // Firebase 설정 (선택적)
    if (AppConfig.enableAnalytics) {
      // Firebase Analytics 활성화 (프로덕션 환경에서만)
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }

  } catch (e) {
    AppLogger.error('Firebase initialization failed', 'Main', e);

    // Firebase 초기화 실패 시에도 앱은 실행되도록 함
    // 오프라인 모드나 제한된 기능으로 동작
    if (AppConfig.enableLogging) {
      AppLogger.info('Running in limited mode without Firebase', 'Main');
    }
  }
}

class BugCashWebApp extends StatelessWidget {
  const BugCashWebApp({super.key});

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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ko', ''),
          ],
          locale: const Locale('ko', ''),  // 기본 언어를 한글로 설정
          home: const AuthWrapper(),
        );
      },
    );
  }
}

Future<void> _initializeEnvironment() async {
  try {
    // 환경변수 로드
    await ApiKeyService.loadEnv();

    if (AppConfig.enableLogging) {
      AppLogger.info('Environment variables initialized', 'Main');
    }
  } catch (e) {
    AppLogger.error('Environment initialization failed', 'Main', e);

    if (AppConfig.enableLogging) {
      AppLogger.info('Continuing with default configuration', 'Main');
    }
  }
}