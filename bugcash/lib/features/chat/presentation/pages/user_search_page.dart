import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/chat_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/chat_room.dart';
import 'chat_room_page.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createDirectChatRoom(UserEntity selectedUser) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      // 로그인하지 않은 상태에서는 로그인 우회를 먼저 수행
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('채팅을 시작하려면 먼저 로그인 우회 버튼을 눌러주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final chatActions = ref.read(chatActionsProvider);
    
    // 로딩 다이얼로그 표시
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // 1:1 채팅방 생성
      final success = await chatActions.createChatRoom(
        name: '${currentUser.displayName} & ${selectedUser.displayName}',
        type: ChatRoomType.direct,
        participantIds: [currentUser.uid, selectedUser.uid],
        metadata: {
          'createdBy': currentUser.uid,
          'chatType': 'direct',
          'participants': [
            {
              'id': currentUser.uid,
              'name': currentUser.displayName,
              'email': currentUser.email,
            },
            {
              'id': selectedUser.uid,
              'name': selectedUser.displayName,
              'email': selectedUser.email,
            },
          ],
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        if (success) {
          // 채팅방 생성 성공 - 사용자 목록을 다시 가져와서 새 채팅방 찾기
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            final chatRoomsFilter = ChatRoomFilter(
              userId: currentUser.uid,
              type: ChatRoomType.direct,
            );
            
            // 잠시 대기 후 채팅방으로 이동 (Firebase 동기화 시간 고려)
            await Future.delayed(const Duration(milliseconds: 500));
            
            // 임시로 모의 채팅방 ID 생성하여 이동
            final mockChatRoomId = 'direct_${currentUser.uid}_${selectedUser.uid}';
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  chatRoomId: mockChatRoomId,
                  chatRoomName: selectedUser.displayName,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방 생성에 실패했습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userSearchProvider(_searchQuery));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 검색'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // 검색 입력창
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름 또는 이메일로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),

          // 검색 결과
          Expanded(
            child: searchResults.when(
              data: (users) {
                if (_searchQuery.isEmpty) {
                  return _buildSearchHint();
                }

                if (users.isEmpty) {
                  return _buildNoResults();
                }

                // 현재 사용자를 결과에서 제외 (로그인한 경우에만)
                final filteredUsers = currentUser != null 
                    ? users.where((user) => user.uid != currentUser.uid).toList()
                    : users;

                if (filteredUsers.isEmpty) {
                  return _buildNoResults();
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserTile(user);
                  },
                );
              },
              loading: () => _searchQuery.isEmpty 
                  ? _buildSearchHint()
                  : const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      '검색 중 오류가 발생했습니다',
                      style: TextStyle(fontSize: 16.sp, color: Colors.red),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '사용자를 검색해보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '이름이나 이메일을 입력하여\n채팅하고 싶은 사용자를 찾아보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            '검색 결과가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '다른 키워드로 검색해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserEntity user) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: CircleAvatar(
        radius: 24.w,
        backgroundColor: _getUserTypeColor(user.userType),
        backgroundImage: user.photoUrl != null 
            ? NetworkImage(user.photoUrl!) 
            : null,
        child: user.photoUrl == null
            ? Text(
                user.displayName.isNotEmpty 
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _getUserTypeColor(user.userType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _getUserTypeText(user.userType),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: _getUserTypeColor(user.userType),
              ),
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chat),
        onPressed: () => _createDirectChatRoom(user),
        tooltip: '채팅 시작',
      ),
      onTap: () => _createDirectChatRoom(user),
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.provider:
        return Colors.blue;
      case UserType.tester:
        return Colors.green;
    }
  }

  String _getUserTypeText(UserType userType) {
    switch (userType) {
      case UserType.provider:
        return '공급자';
      case UserType.tester:
        return '테스터';
    }
  }
}