import '../entities/provider_app_entity.dart';

abstract class AppManagementRepository {
  /// Get a stream of apps for a specific provider
  Stream<List<ProviderAppEntity>> getProviderApps(String providerId);

  /// Create a new app
  Future<String> createApp(ProviderAppEntity app);

  /// Update an existing app
  Future<void> updateApp(ProviderAppEntity app);

  /// Delete an app
  Future<void> deleteApp(String appId);

  /// Get app by ID
  Future<ProviderAppEntity?> getAppById(String appId);

  /// Verify provider credentials for deletion
  Future<bool> verifyProviderCredentials(String email, String password);
}