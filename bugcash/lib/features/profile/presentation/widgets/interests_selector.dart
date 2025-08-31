import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InterestsSelector extends StatefulWidget {
  final List<String> availableInterests;
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;
  final int maxInterests;

  const InterestsSelector({
    super.key,
    required this.availableInterests,
    required this.selectedInterests,
    required this.onInterestsChanged,
    this.maxInterests = 8,
  });

  @override
  State<InterestsSelector> createState() => _InterestsSelectorState();
}

class _InterestsSelectorState extends State<InterestsSelector> {
  late TextEditingController _searchController;
  List<String> _filteredInterests = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredInterests = List.from(widget.availableInterests);
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
        _buildSelectedInterests(),
        SizedBox(height: 16.h),
        _buildSearchField(),
        SizedBox(height: 12.h),
        _buildAvailableInterests(),
      ],
    );
  }

  Widget _buildSelectedInterests() {
    if (widget.selectedInterests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Text(
          '관심 있는 분야를 선택해주세요',
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
              '선택된 관심 분야 (${widget.selectedInterests.length}/${widget.maxInterests})',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (widget.selectedInterests.isNotEmpty)
              TextButton(
                onPressed: () {
                  widget.onInterestsChanged([]);
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
          children: widget.selectedInterests.map((interest) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF4EDBC5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    interest,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () {
                      final updatedInterests = List<String>.from(widget.selectedInterests);
                      updatedInterests.remove(interest);
                      widget.onInterestsChanged(updatedInterests);
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
      onChanged: _filterInterests,
      decoration: InputDecoration(
        hintText: '관심 분야를 검색하세요...',
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
                  _filterInterests('');
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
          borderSide: const BorderSide(color: Color(0xFF00BFA5)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
      ),
    );
  }

  Widget _buildAvailableInterests() {
    final interestsToShow = _filteredInterests.where((interest) => 
      !widget.selectedInterests.contains(interest)
    ).toList();

    if (interestsToShow.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          _searchController.text.isNotEmpty
              ? '검색 결과가 없습니다'
              : '모든 관심 분야를 선택했습니다',
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
          '사용 가능한 관심 분야',
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
              children: interestsToShow.map((interest) {
                final canAdd = widget.selectedInterests.length < widget.maxInterests;
                
                return GestureDetector(
                  onTap: canAdd ? () => _addInterest(interest) : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: canAdd ? Colors.white : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: canAdd 
                            ? const Color(0xFF00BFA5) 
                            : const Color(0xFFE9ECEF),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          interest,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: canAdd 
                                ? const Color(0xFF00BFA5) 
                                : const Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (canAdd) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.add,
                            size: 14.w,
                            color: const Color(0xFF00BFA5),
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
        if (widget.selectedInterests.length >= widget.maxInterests)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '최대 ${widget.maxInterests}개까지 선택할 수 있습니다',
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

  void _filterInterests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInterests = List.from(widget.availableInterests);
      } else {
        _filteredInterests = widget.availableInterests
            .where((interest) => interest.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addInterest(String interest) {
    if (widget.selectedInterests.length >= widget.maxInterests) return;
    
    final updatedInterests = List<String>.from(widget.selectedInterests);
    if (!updatedInterests.contains(interest)) {
      updatedInterests.add(interest);
      widget.onInterestsChanged(updatedInterests);
    }
  }
}