import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // 웹에서는 Firebase 초기화를 스킵하고 데모 모드로 실행
      if (kDebugMode) {
        debugPrint('Running in web demo mode without Firebase');
      }
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
  
  runApp(const BugCashApp());
}

class BugCashApp extends StatelessWidget {
  const BugCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

