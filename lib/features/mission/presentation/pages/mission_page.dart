import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../services/firebase_service.dart';
import '../widgets/mission_card.dart';
import 'mission_detail_page.dart';

class MissionPage extends StatefulWidget {
  final bool isFirebaseAvailable;
  
  const MissionPage({super.key, required this.isFirebaseAvailable});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  List<Map<String, dynamic>> missions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    List<Map<String, dynamic>> loadedMissions;
    
    if (widget.isFirebaseAvailable) {
      loadedMissions = await FirebaseService.getMissions();
    } else {
      loadedMissions = _getFallbackMissions();
    }
    
    if (mounted) {
      setState(() {
        missions = loadedMissions;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackMissions() {
    return [
      {
        'id': 'offline_1',
        'title': '인스타그램 클론 앱 테스트',
        'reward': 5000,
        'deadline': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'participantCount': 8,
        'maxParticipants': 15,
      },
      {
        'id': 'offline_2',
        'title': '배달앱 주문 플로우 테스트',
        'reward': 3000,
        'deadline': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'participantCount': 12,
        'maxParticipants': 20,
      },
      {
        'id': 'offline_3',
        'title': '온라인 쇼핑몰 결제 테스트',
        'reward': 7000,
        'deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'participantCount': 5,
        'maxParticipants': 10,
      },
    ];
  }

  String _formatDate(dynamic date) {
    if (date == null) return '날짜 미정';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = DateTime.parse(date.toString());
      }
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 미정';
    }
  }

  double _calculateProgress(Map<String, dynamic> mission) {
    final participants = mission['participantCount'] ?? 0;
    final maxParticipants = mission['maxParticipants'] ?? 1;
    return (participants / maxParticipants).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🎯 미션'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00BFA5).withOpacity(0.1),
                    const Color(0xFF4EDBC5).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.bug_report,
                    size: 64.sp,
                    color: const Color(0xFF00BFA5),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '미션 센터',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00BFA5),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '다양한 앱 테스트 미션에 참여하여 리워드를 획득하세요',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '📱 진행 중인 미션',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              )
            else if (missions.isEmpty)
              Center(
                child: Text(
                  '미션이 없습니다',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF757575),
                  ),
                ),
              )
            else
              ...missions.asMap().entries.map((entry) {
                final index = entry.key;
                final mission = entry.value;
                final colors = [
                  const Color(0xFFFFE4E1),
                  const Color(0xFFE6F3FF),
                  const Color(0xFFF0FFF0),
                  const Color(0xFFFFF8DC),
                ];
                
                return MissionCard(
                  missionId: mission['id'] ?? 'unknown_$index',
                  title: mission['title'] ?? 'Unknown Mission',
                  reward: '${mission['reward'] ?? 0} 포인트',
                  deadline: _formatDate(mission['deadline']),
                  progress: _calculateProgress(mission),
                  color: colors[index % colors.length],
                  missionData: mission,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MissionDetailPage(
                          missionId: mission['id'] ?? 'unknown_$index',
                          missionData: mission,
                        ),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}