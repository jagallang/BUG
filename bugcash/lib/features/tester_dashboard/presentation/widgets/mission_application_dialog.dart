import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';
import '../providers/tester_dashboard_provider.dart' as provider;

class MissionApplicationDialog extends StatefulWidget {
  final provider.MissionCard mission;
  final VoidCallback onApplicationSubmitted;

  const MissionApplicationDialog({
    super.key,
    required this.mission,
    required this.onApplicationSubmitted,
  });

  @override
  State<MissionApplicationDialog> createState() => _MissionApplicationDialogState();
}

class _MissionApplicationDialogState extends State<MissionApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _hasReadRequirements = false;
  bool _hasInstalledApp = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: 700.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '미션 신청하기',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.mission.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mission Info Summary
                      _buildMissionSummary(),
                      
                      SizedBox(height: 20.h),
                      
                      // Requirements Checklist
                      _buildRequirementsChecklist(),
                      
                      SizedBox(height: 20.h),
                      
                      // Message Input
                      _buildMessageInput(),
                      
                      SizedBox(height: 20.h),
                      
                      // Application Guidelines
                      _buildApplicationGuidelines(),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canSubmit() && !_isSubmitting 
                          ? _submitApplication 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '신청하기',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '미션 정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('앱 이름', widget.mission.appName, Icons.apps),
              ),
              Expanded(
                child: _buildInfoItem('보상', '${widget.mission.rewardPoints}P', Icons.monetization_on),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('소요시간', '${widget.mission.estimatedMinutes}분', Icons.schedule),
              ),
              Expanded(
                child: _buildInfoItem('참여자', '${widget.mission.currentParticipants}/${widget.mission.maxParticipants}', Icons.people),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey.shade600),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementsChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '신청 전 확인사항',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        
        // 요구사항 확인
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _hasReadRequirements,
                onChanged: (value) {
                  setState(() {
                    _hasReadRequirements = value ?? false;
                  });
                },
                title: Text(
                  '공급자의 테스트 요구사항을 확인했습니다',
                  style: TextStyle(fontSize: 14.sp),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _hasInstalledApp,
                onChanged: (value) {
                  setState(() {
                    _hasInstalledApp = value ?? false;
                  });
                },
                title: Text(
                  '앱을 설치하고 테스트할 준비가 되었습니다',
                  style: TextStyle(fontSize: 14.sp),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '신청 메시지 (선택사항)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '공급자에게 전달할 메시지를 작성해주세요. 경험이나 특별한 사항을 어필할 수 있습니다.',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '예: 안녕하세요! 저는 모바일 앱 테스트 경험이 3년 있으며, 특히 UI/UX 테스트를 전문으로 합니다. 책임감을 갖고 꼼꼼히 테스트하겠습니다.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            contentPadding: EdgeInsets.all(12.w),
          ),
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildApplicationGuidelines() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.green, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '신청 안내',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '• 신청 후 공급자가 검토하여 수락/거부를 결정합니다\n'
            '• 수락되면 즉시 테스트를 시작할 수 있습니다\n'
            '• 거부되더라도 다른 미션에 계속 신청할 수 있습니다\n'
            '• 신청은 취소할 수 있지만, 수락 후에는 취소가 어렵습니다',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _hasReadRequirements && _hasInstalledApp;
  }

  Future<void> _submitApplication() async {
    if (!_canSubmit() || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Replace with actual Firebase mission application API
      await Future.delayed(const Duration(seconds: 2));

      // 성공 처리
      if (mounted) {
        Navigator.of(context).pop();
        widget.onApplicationSubmitted();
        
        // 성공 스낵바
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('미션 신청이 완료되었습니다!\n공급자의 승인을 기다려주세요.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (error) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Text('신청 중 오류가 발생했습니다. 다시 시도해주세요.'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}