import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // v2.141.0: 별점 조회
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart' hide TesterProfile; // UserType import
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../tester_dashboard/presentation/providers/tester_dashboard_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart'; // v2.142.0: 지갑 포인트 연동
import '../../../provider_dashboard/presentation/providers/provider_dashboard_provider.dart'; // v2.144.0: 공급자 통계 연동
import '../../../wallet/presentation/pages/unified_wallet_page.dart'; // v2.146.0: 통합 지갑 페이지

/// v2.148.0: 완전 통합 프로필 페이지 (역할 구분 없음)
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: BugCashLoadingWidget(),
        ),
      );
    }

    // v2.148.0: 통일된 보라색 테마
    const primaryColor = Colors.deepPurple;
    const accentColor = Colors.purpleAccent;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 앱바 + 프로필 헤더
          _buildProfileHeader(context, user, primaryColor, accentColor, ref),

          // 사용자 정보 섹션
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWalletButton(context, ref, primaryColor, user), // v2.148.0: 통합 지갑 버튼
                  SizedBox(height: 16.h),
                  _buildStatsSection(ref, primaryColor, user), // v2.148.0: 완전 통합 통계 섹션
                  SizedBox(height: 16.h),
                  _buildActionButtons(context, ref),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// v2.148.0: 통합 프로필 헤더 (역할 구분 제거)
  Widget _buildProfileHeader(
    BuildContext context,
    user,
    Color primaryColor,
    Color accentColor,
    WidgetRef ref,
  ) {
    return SliverAppBar(
      expandedHeight: 240.h, // v2.148.0: 배지 제거로 높이 감소
      pinned: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 80.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 프로필 이미지
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50.sp,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),

                SizedBox(height: 16.h),

                // v2.148.0: 이름만 표시 (레벨 배지 제거)
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

                SizedBox(height: 8.h),

                // 이메일
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                // v2.148.0: 역할 배지 제거
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// v2.156.0: 내 지갑 버튼 (파란색 강조 스타일)
  Widget _buildWalletButton(BuildContext context, WidgetRef ref, Color primaryColor, UserEntity user) {
    final userId = user.uid;
    final walletAsync = ref.watch(walletProvider(userId));

    return Container(
      decoration: BoxDecoration(
        // v2.156.0: 파란색 그라데이션 배경으로 강조
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),  // 파란색 그림자
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UnifiedWalletPage(userId: userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),  // 반투명 흰색
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 24.sp,
                  color: Colors.white,  // 흰색 아이콘
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 지갑',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,  // 흰색 텍스트
                      ),
                    ),
                    SizedBox(height: 4.h),
                    walletAsync.when(
                      data: (wallet) => Text(
                        '${NumberFormat('#,###').format(wallet.balance)}P',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),  // 흰색 투명도 90%
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => Text(
                        '...P',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      error: (_, __) => Text(
                        '0P',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.white.withOpacity(0.8),  // 흰색 화살표
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// v2.148.0: 완전 통합 통계 섹션 (모든 사용자 동일)
  Widget _buildStatsSection(WidgetRef ref, Color primaryColor, UserEntity user) {
    final userId = user.uid;
    final dateFormat = DateFormat('yyyy.MM.dd');

    // 공통: 지갑 데이터
    final walletAsync = ref.watch(walletProvider(userId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 좌상: 지갑 잔액 (공통)
              Expanded(
                child: walletAsync.when(
                  data: (wallet) => _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: primaryColor,
                    label: '지갑 잔액',
                    value: '${NumberFormat('#,###').format(wallet.balance)}P',
                  ),
                  loading: () => _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: primaryColor,
                    label: '지갑 잔액',
                    value: '...P',
                  ),
                  error: (_, __) => _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: primaryColor,
                    label: '지갑 잔액',
                    value: '0P',
                  ),
                ),
              ),
              Container(width: 1, height: 80.h, color: Colors.grey[200]),
              // 우상: 완료 미션 (공통)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final completedMissionsAsync = ref.watch(completedMissionsCountProvider(userId));
                    return completedMissionsAsync.when(
                      data: (count) => _buildStatItem(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        label: '완료 미션',
                        value: '$count개',
                      ),
                      loading: () => _buildStatItem(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        label: '완료 미션',
                        value: '...개',
                      ),
                      error: (_, __) => _buildStatItem(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        label: '완료 미션',
                        value: '0개',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Row(
            children: [
              // 좌하: 평균 평점 (공통 - 테스터/공급자 모두 평가받을 수 있음)
              Expanded(
                child: Builder(
                  builder: (ctx) {
                    final dashboardState = ref.watch(testerDashboardProvider);
                    final profile = dashboardState.testerProfile;

                    if (profile == null) {
                      return _buildStatItem(
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        label: '평균 평점',
                        value: '-',
                      );
                    }

                    return GestureDetector(
                      onTap: () => _showRatingDetailsDialog(ctx, ref, profile.id),
                      child: _buildRatingStatItem(
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        label: '평균 평점',
                        rating: profile.averageRating,
                      ),
                    );
                  },
                ),
              ),
              Container(width: 1, height: 80.h, color: Colors.grey[200]),
              // 우하: 가입일 (공통)
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blueGrey,
                  label: '가입일',
                  value: dateFormat.format(user.createdAt),
                  valueSize: 13.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    double? valueSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Icon(icon, size: 28.sp, color: iconColor),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize ?? 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// v2.148.0: 액션 버튼들 (통합 버전 - 역할 구분 없음)
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('설정'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Colors.red[200]!),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  /// v2.160.0: 로그아웃 확인 다이얼로그 (popUntil로 깔끔한 스택 정리)
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // 다이얼로그 닫기

              // v2.160.0: 로그아웃 중 로딩 표시
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await ref.read(authProvider.notifier).signOut();

                // v2.160.0: 모든 라우트를 팝하여 AuthWrapper로 복귀
                // authState.user == null이므로 AuthWrapper가 자동으로 LoginPage 표시
                // 재로그인 시 AuthWrapper가 자동으로 대시보드로 전환
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // 로딩 다이얼로그 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('로그아웃 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// v2.141.0: 별점 통계 아이템 (클릭 가능)
  Widget _buildRatingStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double rating,
  }) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Icon(icon, size: 28.sp, color: iconColor),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          // 별 아이콘 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildStarIcons(rating, size: 16.sp),
          ),
          SizedBox(height: 2.h),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '(상세 보기)',
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey[500],
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  /// v2.141.0: 별 아이콘 생성
  List<Widget> _buildStarIcons(double rating, {double size = 16}) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, size: size, color: Colors.amber));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half, size: size, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border, size: size, color: Colors.grey[400]));
      }
    }
    return stars;
  }

  /// v2.141.0: 별점 상세 다이얼로그
  Future<void> _showRatingDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    String testerId,
  ) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 별점 데이터 조회
      final ratings = await ref
          .read(testerDashboardProvider.notifier)
          .getTesterRatings(testerId);

      // 로딩 다이얼로그 닫기
      if (context.mounted) Navigator.pop(context);

      if (ratings.isEmpty) {
        // 별점이 없는 경우
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('받은 별점 내역'),
              content: const Text('아직 받은 별점이 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 별점 분포 계산
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double sum = 0;
      for (var rating in ratings) {
        sum += rating;
        distribution[rating.round()] = (distribution[rating.round()] ?? 0) + 1;
      }
      double average = sum / ratings.length;

      // 상세 다이얼로그 표시
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('받은 별점 내역'),
            content: SizedBox(
              width: 300.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 전체 평균
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '전체 평균',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildStarIcons(average, size: 20.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          average.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '총 ${ratings.length}건의 평가',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(),
                  SizedBox(height: 12.h),
                  // 별점 분포
                  ...List.generate(5, (index) {
                    int star = 5 - index;
                    int count = distribution[star] ?? 0;
                    double percentage = (count / ratings.length) * 100;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60.w,
                            child: Row(
                              children: [
                                ...List.generate(
                                  star,
                                  (_) => Icon(Icons.star,
                                      size: 12.sp, color: Colors.amber),
                                ),
                                ...List.generate(
                                  5 - star,
                                  (_) => Icon(Icons.star_border,
                                      size: 12.sp, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 8.h,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 50.w,
                            child: Text(
                              '$count건 (${percentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 에러 처리
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('오류'),
            content: Text('별점 정보를 불러오는데 실패했습니다.\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }
}

// v2.143.0: 완료된 미션 수 실시간 조회 Provider
final completedMissionsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('enrollments')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'completed')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
