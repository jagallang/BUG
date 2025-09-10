import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/auth_service.dart';

class CommunityBoardWidget extends ConsumerStatefulWidget {
  final String testerId;

  const CommunityBoardWidget({
    super.key,
    required this.testerId,
  });

  @override
  ConsumerState<CommunityBoardWidget> createState() => _CommunityBoardWidgetState();
}

class _CommunityBoardWidgetState extends ConsumerState<CommunityBoardWidget> {
  final Set<String> _expandedPosts = {};
  // Removed hardcoded dummy data - now using Firebase

  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '모집중', '모집완료', '구인', '구직', '질문', '기타'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple.shade50, // 연한 보라색 배경
      child: Padding(
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('데이터를 불러올 수 없습니다: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final posts = snapshot.data!.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList();

        final filteredPosts = _selectedCategory == '전체'
            ? posts
            : posts.where((post) => post.category == _selectedCategory).toList();

        if (filteredPosts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(filteredPosts[index]);
          },
        );
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
          // Firebase streams automatically update the UI
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('게시글이 작성되었습니다!')),
            );
          }
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

  void _toggleLike(CommunityPost post) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(post.id)
          .update({
        'likes': FieldValue.increment(1),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요를 눌렀습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 처리에 실패했습니다: $e')),
        );
      }
    }
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
  final String authorId;

  CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.category,
    required this.authorId,
  });

  factory CommunityPost.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      author: data['author'] ?? '익명',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      category: data['category'] ?? '기타',
      authorId: data['authorId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'author': author,
      'title': title,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
      'category': category,
      'authorId': authorId,
    };
  }
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

  void _createPost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
      );
      return;
    }

    try {
      final currentUserId = CurrentUserService.getCurrentUserIdOrDefault();
      final newPost = CommunityPost(
        id: '',
        author: '익명 사용자',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        timestamp: DateTime.now(),
        likes: 0,
        comments: 0,
        category: _selectedCategory,
        authorId: currentUserId,
      );

      // Firebase에 저장
      await FirebaseFirestore.instance
          .collection('community_posts')
          .add(newPost.toFirestore());

      widget.onPostCreated(newPost);
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 작성되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성에 실패했습니다: $e')),
        );
      }
    }
  }
}