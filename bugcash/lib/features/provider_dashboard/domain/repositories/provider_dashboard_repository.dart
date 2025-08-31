import '../models/provider_model.dart';
import '../../../../models/mission_model.dart';

abstract class ProviderDashboardRepository {
  // Provider Management
  Future<ProviderModel?> getProviderInfo(String providerId);
  Future<void> updateProviderInfo(String providerId, Map<String, dynamic> data);
  Future<void> updateProviderStatus(String providerId, ProviderStatus status);
  
  // App Management
  Future<List<AppModel>> getProviderApps(String providerId);
  Future<AppModel?> getApp(String appId);
  Future<String> createApp(AppModel app);
  Future<void> updateApp(String appId, Map<String, dynamic> data);
  Future<void> updateAppStatus(String appId, AppStatus status);
  Future<void> deleteApp(String appId);
  
  // Mission Management
  Future<List<MissionModel>> getProviderMissions(String providerId);
  Future<List<MissionModel>> getAppMissions(String appId);
  Future<String> createMission(MissionModel mission);
  Future<void> updateMission(String missionId, Map<String, dynamic> data);
  Future<void> deleteMission(String missionId);
  
  // Bug Report Management
  Future<List<Map<String, dynamic>>> getBugReports(String providerId);
  Future<List<Map<String, dynamic>>> getAppBugReports(String appId);
  Future<void> updateBugReportStatus(String reportId, String status);
  Future<void> addBugReportResponse(String reportId, String response);
  
  // Analytics & Statistics
  Future<DashboardStats> getDashboardStats(String providerId);
  Future<Map<String, dynamic>> getAppAnalytics(String appId);
  Future<Map<String, dynamic>> getMissionAnalytics(String missionId);
  Future<List<Map<String, dynamic>>> getRecentActivities(String providerId);
  
  // Real-time Streams
  Stream<ProviderModel> watchProviderInfo(String providerId);
  Stream<List<AppModel>> watchProviderApps(String providerId);
  Stream<List<MissionModel>> watchProviderMissions(String providerId);
  Stream<DashboardStats> watchDashboardStats(String providerId);
  Stream<List<Map<String, dynamic>>> watchRecentActivities(String providerId);
  
  // Tester Management
  Future<List<Map<String, dynamic>>> getProviderTesters(String providerId);
  Future<Map<String, dynamic>> getTesterProfile(String testerId);
  Future<List<Map<String, dynamic>>> getTesterHistory(String testerId);
  
  // Financial Management
  Future<Map<String, dynamic>> getFinancialSummary(String providerId);
  Future<List<Map<String, dynamic>>> getPaymentHistory(String providerId);
  Future<void> processPayment(String providerId, Map<String, dynamic> paymentData);
}