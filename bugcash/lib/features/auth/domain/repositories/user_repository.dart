import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserEntity>>> searchUsers({
    required String query,
    int limit = 20,
  });

  Future<Either<Failure, UserEntity?>> getUserById(String userId);

  Future<Either<Failure, void>> updateUser(UserEntity user);

  Future<Either<Failure, void>> deleteUser(String userId);

  Future<Either<Failure, List<UserEntity>>> getAllUsers({
    int limit = 50,
    String? lastUserId,
  });

  Future<Either<Failure, List<UserEntity>>> getUsersByType(
    UserType userType, {
    int limit = 50,
  });
}