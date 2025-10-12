import '../../domain/entities/provider_app_entity.dart';
import '../../domain/repositories/app_management_repository.dart';
import '../datasources/app_management_remote_datasource.dart';
import '../models/provider_app_model.dart';

class AppManagementRepositoryImpl implements AppManagementRepository {
  final AppManagementRemoteDataSource remoteDataSource;

  AppManagementRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<ProviderAppEntity>> getProviderApps(String providerId) {
    return remoteDataSource.getProviderApps(providerId);
  }

  @override
  Future<String> createApp(ProviderAppEntity app) {
    final model = ProviderAppModel.fromEntity(app);
    return remoteDataSource.createApp(model);
  }

  @override
  Future<void> updateApp(ProviderAppEntity app) {
    final model = ProviderAppModel.fromEntity(app);
    return remoteDataSource.updateApp(model);
  }

  @override
  Future<void> deleteApp(String appId) {
    return remoteDataSource.deleteApp(appId);
  }

  @override
  Future<ProviderAppEntity?> getAppById(String appId) {
    return remoteDataSource.getAppById(appId);
  }

  @override
  Future<bool> verifyProviderCredentials(String email, String password) {
    return remoteDataSource.verifyProviderCredentials(email, password);
  }
}