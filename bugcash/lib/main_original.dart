import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // 웹에서는 Firebase 초기화를 스킵하고 데모 모드로 실행
      if (kDebugMode) {
        print('Running in web demo mode without Firebase');
      }
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }
  
  configureDependencies();
  
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
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
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => getIt<AuthBloc>()..add(const CheckAuth()),
            ),
          ],
          child: MaterialApp(
            title: 'BugCash',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      print('${bloc.runtimeType} $change');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('${bloc.runtimeType} $error $stackTrace');
    }
    super.onError(bloc, error, stackTrace);
  }
}
