import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestDataPage extends StatefulWidget {
  const TestDataPage({super.key});

  @override
  State<TestDataPage> createState() => _TestDataPageState();
}

class _TestDataPageState extends State<TestDataPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트 데이터 관리'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '워크플로우 테스트용 데이터 생성',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),

            _buildTestActionCard(
              title: '테스트 프로젝트 생성',
              description: '승인 대기 상태의 테스트 프로젝트를 생성합니다.',
              onPressed: _createTestProjects,
              color: Colors.blue,
              icon: Icons.add_circle,
            ),

            SizedBox(height: 16.h),

            _buildTestActionCard(
              title: '기존 데이터 확인',
              description: '현재 데이터베이스의 프로젝트 데이터를 확인합니다.',
              onPressed: _checkExistingData,
              color: Colors.green,
              icon: Icons.search,
            ),

            SizedBox(height: 16.h),

            _buildTestActionCard(
              title: '테스트 데이터 삭제',
              description: '생성된 테스트 데이터를 모두 삭제합니다.',
              onPressed: _clearTestData,
              color: Colors.red,
              icon: Icons.delete,
            ),

            if (_isLoading) ...[
              SizedBox(height: 24.h),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestActionCard({
    required String title,
    required String description,
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Icon(icon, color: color, size: 32.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('실행'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestProjects() async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 테스트 프로젝트 1 - pending 상태
      final project1Ref = FirebaseFirestore.instance.collection('projects').doc();
      batch.set(project1Ref, {
        'appName': '테스트 쇼핑몰 앱',
        'description': '쇼핑몰 앱의 결제 기능과 사용자 인터페이스를 테스트해주세요.',
        'providerId': 'test-provider-1',
        'providerName': '테스트 공급자 1',
        'status': 'pending',
        'maxTesters': 10,
        'testPeriodDays': 14,
        'rewards': {
          'baseReward': 50000,
          'bonusReward': 10000,
        },
        'requirements': {
          'platforms': ['android', 'ios'],
          'minAge': 18,
          'maxAge': 60,
        },
        'type': 'app',
        'difficulty': 'medium',
        'platform': 'android',
        'category': 'shopping',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 테스트 프로젝트 2 - pending 상태
      final project2Ref = FirebaseFirestore.instance.collection('projects').doc();
      batch.set(project2Ref, {
        'appName': '게임 앱 테스트',
        'description': '새로운 게임 앱의 게임플레이와 버그를 찾아주세요.',
        'providerId': 'test-provider-2',
        'providerName': '테스트 공급자 2',
        'status': 'pending',
        'maxTesters': 15,
        'testPeriodDays': 21,
        'rewards': {
          'baseReward': 75000,
          'bonusReward': 15000,
        },
        'requirements': {
          'platforms': ['android', 'ios'],
          'minAge': 16,
          'maxAge': 50,
        },
        'type': 'app',
        'difficulty': 'hard',
        'platform': 'ios',
        'category': 'game',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스트 프로젝트가 성공적으로 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkExistingData() async {
    setState(() => _isLoading = true);

    try {
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      final pendingCount = projectsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      final openCount = projectsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'open')
          .length;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('현재 데이터 현황'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('총 프로젝트: ${projectsSnapshot.docs.length}개'),
                SizedBox(height: 8.h),
                Text('승인 대기: ${pendingCount}개'),
                SizedBox(height: 8.h),
                Text('승인됨: ${openCount}개'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: const Text('정말로 모든 테스트 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('providerId', whereIn: ['test-provider-1', 'test-provider-2'])
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스트 데이터가 삭제되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}