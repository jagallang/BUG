import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityBoardWidget extends StatefulWidget {
  final String testerId;

  const CommunityBoardWidget({
    super.key,
    required this.testerId,
  });

  @override
  State<CommunityBoardWidget> createState() => _CommunityBoardWidgetState();
}

class _CommunityBoardWidgetState extends State<CommunityBoardWidget> {
  final Set<String> _expandedPosts = {};
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: '1',
      author: '버그헌터123',
      title: 'iOS 앱 테스터 5명 모집중 (시급 15,000원)',
      content: '새로 출시되는 iOS 금융 앱 테스트를 함께 진행할 테스터분들을 모집합니다. 경험자 우대...',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 12,
      comments: 3,
      category: '모집중',
    ),
    CommunityPost(
      id: '2',
      author: '테스터프로',
      title: '안드로이드 게임 앱 테스트 프로젝트 완료',
      content: '지난 주부터 진행했던 모바일 게임 테스트 프로젝트가 성공적으로 완료되었습니다.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 28,
      comments: 8,
      category: '모집완료',
    ),
    CommunityPost(
      id: '3',
      author: '모바일매니아',
      title: '프리랜서 QA 테스터 경력직 구합니다',
      content: '스타트업에서 정규직 QA 테스터를 채용합니다. 2년 이상 경력자, 협업 도구 경험 필수...',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likes: 15,
      comments: 5,
      category: '구인',
    ),
    CommunityPost(
      id: '4',
      author: '신입테스터',
      title: '테스터 신입 구직활동 중입니다',
      content: '컴퓨터공학과 졸업 예정이며, 앱 테스팅 분야로 취업을 준비하고 있습니다. 조언 부탁드립니다.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      likes: 7,
      comments: 12,
      category: '구직',
    ),
    CommunityPost(
      id: '5',
      author: '질문왕',
      title: '테스트 리포트 작성 방법이 궁금해요',
      content: '효과적인 버그 리포트 작성 방법에 대해 질문드립니다. 어떤 형식으로 작성해야 할까요?',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      likes: 4,
      comments: 6,
      category: '질문',
    ),
    CommunityPost(
      id: '6',
      author: '자유로운영혼',
      title: '테스터들의 소소한 일상 이야기',
      content: '오늘 테스트하다가 웃긴 일이 있어서 공유해요. 개발자님이 Easter Egg를 숨겨놨네요 ㅋㅋ',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      likes: 18,
      comments: 9,
      category: '기타',
    ),
  ];

  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '모집중', '모집완료', '구인', '구직', '질문', '기타'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Header with post button
          _buildHeader(),
          SizedBox(height: 16.h),
          
          // Category filter
          _buildCategoryFilter(),
          SizedBox(height: 16.h),
          
          // Posts list
          Expanded(
            child: _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '커뮤니티',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        FloatingActionButton(
          heroTag: "community_board_fab",
          onPressed: _showCreatePostDialog,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    final filteredPosts = _selectedCategory == '전체' 
        ? _posts 
        : _posts.where((post) => post.category == _selectedCategory).toList();

    if (filteredPosts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(filteredPosts[index]);
      },
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final isExpanded = _expandedPosts.contains(post.id);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedPosts.remove(post.id);
            } else {
              _expandedPosts.add(post.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and author
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(post.category),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        post.category,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      post.author,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20.w,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                
                // Title
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: isExpanded ? null : 1,
                  overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                
                // Content - show preview when collapsed, full content when expanded
                if (!isExpanded) ...[
                  SizedBox(height: 4.h),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  // Show action counts in collapsed state
                  Row(
                    children: [
                      Icon(Icons.favorite_border, size: 14.w, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      ),
                      SizedBox(width: 16.w),
                      Icon(Icons.comment_outlined, size: 14.w, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Text(
                        post.comments.toString(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
                
                // Expanded content
                if (isExpanded) ...[
                  SizedBox(height: 12.h),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 8.h),
                  
                  // Bottom actions - only show when expanded
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildExpandedActionButton(
                        Icons.favorite_border,
                        '좋아요 ${post.likes}',
                        Colors.red,
                        () => _toggleLike(post),
                      ),
                      _buildExpandedActionButton(
                        Icons.comment_outlined,
                        '댓글 ${post.comments}',
                        Colors.blue,
                        () => _openComments(post),
                      ),
                      _buildExpandedActionButton(
                        Icons.share_outlined,
                        '공유',
                        Colors.green,
                        () => _sharePost(post),
                      ),
                      _buildExpandedActionButton(
                        Icons.open_in_new,
                        '자세히',
                        Colors.purple,
                        () => _openPostDetail(post),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildExpandedActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.w, color: color),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '아직 게시글이 없습니다',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '첫 번째 게시글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '모집중':
        return Colors.green;
      case '모집완료':
        return Colors.grey;
      case '구인':
        return Colors.blue;
      case '구직':
        return Colors.purple;
      case '질문':
        return Colors.orange;
      case '기타':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(
        onPostCreated: (post) {
          setState(() {
            _posts.insert(0, post);
          });
        },
      ),
    );
  }

  void _openPostDetail(CommunityPost post) {
    // 게시글 상세 페이지 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${post.title} 상세보기')),
    );
  }

  void _toggleLike(CommunityPost post) {
    setState(() {
      post.likes++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('좋아요를 눌렀습니다!')),
    );
  }

  void _openComments(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${post.title} 댓글보기')),
    );
  }

  void _sharePost(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${post.title} 공유하기')),
    );
  }
}

class CommunityPost {
  final String id;
  final String author;
  final String title;
  final String content;
  final DateTime timestamp;
  int likes;
  final int comments;
  final String category;

  CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.category,
  });
}

class _CreatePostDialog extends StatefulWidget {
  final Function(CommunityPost) onPostCreated;

  const _CreatePostDialog({required this.onPostCreated});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = '모집중';
  final List<String> _categories = ['모집중', '모집완료', '구인', '구직', '질문', '기타'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '새 게시글 작성',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Category selection
            Text(
              '카테고리',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            SizedBox(height: 16.h),
            
            // Title input
            Text(
              '제목',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '게시글 제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Content input
            Text(
              '내용',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '게시글 내용을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
            SizedBox(height: 20.h),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text('작성'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createPost() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
      );
      return;
    }

    final newPost = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: '나',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      timestamp: DateTime.now(),
      likes: 0,
      comments: 0,
      category: _selectedCategory,
    );

    widget.onPostCreated(newPost);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글이 작성되었습니다!')),
    );
  }
}