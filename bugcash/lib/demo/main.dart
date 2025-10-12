import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'theme/demo_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BugCashWebDemo());
}

class BugCashWebDemo extends StatelessWidget {
  const BugCashWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash - Web Demo',
          debugShowCheckedModeBanner: false,
          theme: DemoTheme.lightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}