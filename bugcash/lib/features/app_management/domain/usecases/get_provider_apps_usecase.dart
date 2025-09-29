import '../entities/provider_app_entity.dart';
import '../repositories/app_management_repository.dart';

class GetProviderAppsUseCase {
  final AppManagementRepository repository;

  GetProviderAppsUseCase(this.repository);

  Stream<List<ProviderAppEntity>> call(String providerId) {
    return repository.getProviderApps(providerId);
  }
}