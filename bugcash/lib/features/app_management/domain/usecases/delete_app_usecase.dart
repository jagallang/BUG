import '../repositories/app_management_repository.dart';

class DeleteAppUseCase {
  final AppManagementRepository repository;

  DeleteAppUseCase(this.repository);

  Future<void> call(String appId) {
    return repository.deleteApp(appId);
  }
}