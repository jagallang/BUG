import '../entities/provider_app_entity.dart';
import '../repositories/app_management_repository.dart';

class CreateAppUseCase {
  final AppManagementRepository repository;

  CreateAppUseCase(this.repository);

  Future<String> call(ProviderAppEntity app) {
    return repository.createApp(app);
  }
}