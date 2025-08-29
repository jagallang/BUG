import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🔍 검색'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF757575)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '미션을 검색하세요',
                        hintStyle: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF757575),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64.sp,
                      color: const Color(0xFF00BFA5),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      '미션 검색',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '원하는 조건의 미션을 검색하고 신청하세요',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}