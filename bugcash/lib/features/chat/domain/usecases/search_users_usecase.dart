import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/user_repository.dart';

class SearchUsersUsecase {
  final UserRepository userRepository;

  SearchUsersUsecase(this.userRepository);

  Future<Either<Failure, List<UserEntity>>> call({
    required String query,
    int limit = 20,
    List<String>? excludeUserIds,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }

      final result = await userRepository.searchUsers(
        query: query,
        limit: limit,
      );

      return result.fold(
        (failure) => Left(failure),
        (users) {
          // 제외할 사용자 ID가 있다면 필터링
          if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
            final filteredUsers = users
                .where((user) => !excludeUserIds.contains(user.uid))
                .toList();
            return Right(filteredUsers);
          }
          return Right(users);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search users: $e'));
    }
  }
}