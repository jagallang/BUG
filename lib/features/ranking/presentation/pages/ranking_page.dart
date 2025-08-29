import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🏆 랭킹'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64.sp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '테스터 랭킹',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00BFA5),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '다른 테스터들과 실력을 겨뤄보세요',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}