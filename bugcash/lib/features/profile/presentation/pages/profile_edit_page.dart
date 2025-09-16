import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/profile_provider.dart';
import '../../domain/models/user_profile.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/skills_selector.dart';
import '../widgets/interests_selector.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  
  List<String> _selectedSkills = [];
  List<String> _selectedInterests = [];
  bool _isProfilePublic = true;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    
    _usernameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _githubController = TextEditingController();
    _linkedinController = TextEditingController();
    
    // Load current profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentProfile();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    // For demo purposes, load with demo user ID
    const demoUserId = 'demo_user';
    ref.read(profileProvider.notifier).loadProfile(demoUserId);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    // Initialize form with current profile data
    if (profileState.profile != null && !_hasChanges) {
      _initializeForm(profileState.profile!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(profileState),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImageSection(profileState),
                    SizedBox(height: 24.h),
                    _buildBasicInfoSection(),
                    SizedBox(height: 24.h),
                    _buildSocialLinksSection(),
                    SizedBox(height: 24.h),
                    _buildSkillsSection(profileState),
                    SizedBox(height: 24.h),
                    _buildInterestsSection(profileState),
                    SizedBox(height: 24.h),
                    _buildPrivacySection(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(ProfileState profileState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '프로필 편집',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      actions: [
        if (profileState.isUpdating)
          Container(
            margin: EdgeInsets.only(right: 16.w),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              '저장',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF007AFF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImageSection(ProfileState profileState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileImagePicker(
            imageUrl: profileState.profile?.profileImageUrl,
            isUploading: profileState.isUploadingImage,
            onImageSelected: _onImageSelected,
            onImageDeleted: _onImageDeleted,
          ),
          SizedBox(height: 16.h),
          Text(
            '프로필 사진',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '다른 사용자들이 볼 수 있는 프로필 이미지입니다',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _usernameController,
            label: '사용자명',
            hint: '영문, 숫자, 언더스코어만 사용 가능',
            validator: _validateUsername,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _displayNameController,
            label: '표시 이름',
            hint: '다른 사용자들에게 보여질 이름',
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _bioController,
            label: '소개',
            hint: '자신을 소개해보세요',
            maxLines: 3,
            maxLength: 200,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _locationController,
            label: '위치',
            hint: '예: 서울, 대한민국',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소셜 링크',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _websiteController,
            label: '웹사이트',
            hint: 'https://yourwebsite.com',
            prefixIcon: Icons.language,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _githubController,
            label: 'GitHub',
            hint: 'github_username',
            prefixIcon: Icons.code,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _linkedinController,
            label: 'LinkedIn',
            hint: 'linkedin-profile-url',
            prefixIcon: Icons.business,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ProfileState profileState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '보유 기술',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '테스트 경험이 있는 기술을 선택해주세요 (최대 10개)',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6C757D),
            ),
          ),
          SizedBox(height: 16.h),
          SkillsSelector(
            availableSkills: profileState.availableSkills,
            selectedSkills: _selectedSkills,
            onSkillsChanged: (skills) {
              setState(() {
                _selectedSkills = skills;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(ProfileState profileState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관심 분야',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '테스트하고 싶은 분야를 선택해주세요 (최대 8개)',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6C757D),
            ),
          ),
          SizedBox(height: 16.h),
          InterestsSelector(
            availableInterests: profileState.availableInterests,
            selectedInterests: _selectedInterests,
            onInterestsChanged: (interests) {
              setState(() {
                _selectedInterests = interests;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '개인정보 설정',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          SwitchListTile(
            value: _isProfilePublic,
            onChanged: (value) {
              setState(() {
                _isProfilePublic = value;
                _hasChanges = true;
              });
            },
            title: Text(
              '프로필 공개',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              _isProfilePublic
                  ? '다른 사용자들이 내 프로필을 볼 수 있습니다'
                  : '프로필이 비공개로 설정됩니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
            activeColor: const Color(0xFF007AFF),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: (_) {
            setState(() {
              _hasChanges = true;
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6C757D),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20.w, color: const Color(0xFF6C757D))
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF007AFF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  void _initializeForm(UserProfile profile) {
    _usernameController.text = profile.username;
    _displayNameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _websiteController.text = profile.website ?? '';
    _githubController.text = profile.githubUsername ?? '';
    _linkedinController.text = profile.linkedinProfile ?? '';
    _selectedSkills = List.from(profile.skills);
    _selectedInterests = List.from(profile.interests);
    _isProfilePublic = profile.isProfilePublic;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '사용자명을 입력해주세요';
    }
    if (value.length < 3) {
      return '사용자명은 3자 이상이어야 합니다';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return '영문, 숫자, 언더스코어만 사용 가능합니다';
    }
    return null;
  }

  void _onImageSelected(File imageFile) {
    ref.read(profileProvider.notifier).uploadProfileImage(imageFile);
  }

  void _onImageDeleted() {
    ref.read(profileProvider.notifier).deleteProfileImage();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentProfile = ref.read(profileProvider).profile;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      username: _usernameController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      githubUsername: _githubController.text.trim().isEmpty
          ? null
          : _githubController.text.trim(),
      linkedinProfile: _linkedinController.text.trim().isEmpty
          ? null
          : _linkedinController.text.trim(),
      skills: _selectedSkills,
      interests: _selectedInterests,
      isProfilePublic: _isProfilePublic,
    );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('프로필이 성공적으로 업데이트되었습니다'),
          backgroundColor: const Color(0xFF007AFF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );

      Navigator.pop(context);
    }
  }
}