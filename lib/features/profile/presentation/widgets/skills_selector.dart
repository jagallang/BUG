import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkillsSelector extends StatefulWidget {
  final List<String> availableSkills;
  final List<String> selectedSkills;
  final Function(List<String>) onSkillsChanged;
  final int maxSkills;

  const SkillsSelector({
    super.key,
    required this.availableSkills,
    required this.selectedSkills,
    required this.onSkillsChanged,
    this.maxSkills = 10,
  });

  @override
  State<SkillsSelector> createState() => _SkillsSelectorState();
}

class _SkillsSelectorState extends State<SkillsSelector> {
  late TextEditingController _searchController;
  List<String> _filteredSkills = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredSkills = List.from(widget.availableSkills);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectedSkills(),
        SizedBox(height: 16.h),
        _buildSearchField(),
        SizedBox(height: 12.h),
        _buildAvailableSkills(),
      ],
    );
  }

  Widget _buildSelectedSkills() {
    if (widget.selectedSkills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Text(
          '아직 선택된 기술이 없습니다',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF6C757D),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '선택된 기술 (${widget.selectedSkills.length}/${widget.maxSkills})',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (widget.selectedSkills.isNotEmpty)
              TextButton(
                onPressed: () {
                  widget.onSkillsChanged([]);
                },
                child: Text(
                  '모두 삭제',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.selectedSkills.map((skill) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () {
                      final updatedSkills = List<String>.from(widget.selectedSkills);
                      updatedSkills.remove(skill);
                      widget.onSkillsChanged(updatedSkills);
                    },
                    child: Icon(
                      Icons.close,
                      size: 14.w,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterSkills,
      decoration: InputDecoration(
        hintText: '기술을 검색하세요...',
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF6C757D),
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20.w,
          color: const Color(0xFF6C757D),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20.w,
                  color: const Color(0xFF6C757D),
                ),
                onPressed: () {
                  _searchController.clear();
                  _filterSkills('');
                },
              )
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
      ),
    );
  }

  Widget _buildAvailableSkills() {
    final skillsToShow = _filteredSkills.where((skill) => 
      !widget.selectedSkills.contains(skill)
    ).toList();

    if (skillsToShow.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          _searchController.text.isNotEmpty
              ? '검색 결과가 없습니다'
              : '모든 기술을 선택했습니다',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF6C757D),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용 가능한 기술',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          constraints: BoxConstraints(maxHeight: 200.h),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: skillsToShow.map((skill) {
                final canAdd = widget.selectedSkills.length < widget.maxSkills;
                
                return GestureDetector(
                  onTap: canAdd ? () => _addSkill(skill) : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: canAdd ? Colors.white : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: canAdd 
                            ? const Color(0xFF007AFF) 
                            : const Color(0xFFE9ECEF),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: canAdd 
                                ? const Color(0xFF007AFF) 
                                : const Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (canAdd) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.add,
                            size: 14.w,
                            color: const Color(0xFF007AFF),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.selectedSkills.length >= widget.maxSkills)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '최대 ${widget.maxSkills}개까지 선택할 수 있습니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = List.from(widget.availableSkills);
      } else {
        _filteredSkills = widget.availableSkills
            .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addSkill(String skill) {
    if (widget.selectedSkills.length >= widget.maxSkills) return;
    
    final updatedSkills = List<String>.from(widget.selectedSkills);
    if (!updatedSkills.contains(skill)) {
      updatedSkills.add(skill);
      widget.onSkillsChanged(updatedSkills);
    }
  }
}